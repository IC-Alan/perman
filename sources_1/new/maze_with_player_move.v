// 状态定义
parameter IDLE  = 2'b00;
parameter CHECK = 2'b01;
parameter APPLY = 2'b10;

module maze_with_player_move #(
    parameter CELL_SIZE = 10,
    parameter IMAGE_WIDTH = 640,
    parameter IMAGE_HEIGHT = 480,
    parameter INIT_X = 100,
    parameter INIT_Y = 100
)(
    input clk,
    input rst_n,
    input [3:0] btn_udlr,
    input [9:0] col_addr,
    input [8:0] row_addr,
    output reg [11:0] pixel_rgb
);

    // ROM 读取接口
    wire [11:0] rom_data;
    reg [18:0] rom_addr;
    reg [11:0] rom_data_reg;

    maze maze_inst (
        .clka(clk),
        .ena(1'b1),
        .addra(rom_addr),
        .douta(rom_data)
    );

    // 玩家坐标
    reg [9:0] px, move_px;
    reg [8:0] py, move_py;
    reg [9:0] next_px;
    reg [8:0] next_py;

    wire is_player_pixel;
    assign is_player_pixel =
        (col_addr >= px+3 && col_addr < px+3 + CELL_SIZE) &&
        (row_addr >= py && row_addr < py + CELL_SIZE);

    // VGA 当前像素地址
    wire [18:0] vga_addr = row_addr * IMAGE_WIDTH + col_addr;
    wire [18:0] move_addr = move_py * IMAGE_WIDTH + move_px;



// 状态寄存器
reg [1:0] state;

    // 节流控制
    reg [19:0] move_timer;
    wire move_ready = (move_timer == 0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            move_timer <= 0;
        else if (btn_udlr != 4'b0000 && move_ready)
            move_timer <= 20'd500_000;
        else if (move_timer != 0)
            move_timer <= move_timer - 1;
    end

    // FSM 控制人物移动 + ROM 地址控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            px <= INIT_X;
            py <= INIT_Y;
            state <= IDLE;
            rom_addr <= 0;
        end else begin
            case (state)
                IDLE: begin
                    rom_addr <= vga_addr;
                    if (btn_udlr != 4'b0000 && move_ready) begin
                        move_px = px;
                        move_py = py;
                        if (btn_udlr[3] && py >= CELL_SIZE)
                            move_py = py - CELL_SIZE;
                        else if (btn_udlr[2] && py + CELL_SIZE < IMAGE_HEIGHT)
                            move_py = py + CELL_SIZE;
                        else if (btn_udlr[1] && px >= CELL_SIZE)
                            move_px = px - CELL_SIZE;
                        else if (btn_udlr[0] && px + CELL_SIZE < IMAGE_WIDTH)
                            move_px = px + CELL_SIZE;

                        rom_addr <= move_addr;
                        state <= CHECK;
                    end
                end
                CHECK: begin
                    // 等待读取
                    state <= APPLY;
                end
                APPLY: begin
                    // 不是墙才移动
                    if (!rom_data[0]) begin
                        px <= move_px;
                        py <= move_py;
                    end
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end

    // VGA 输出逻辑
    always @(posedge clk) begin
        rom_data_reg <= rom_data;
        if (is_player_pixel)
            pixel_rgb <= 12'h00F;
        else
            pixel_rgb <= rom_data_reg;
    end

endmodule
