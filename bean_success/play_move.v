module player_move #(
    parameter CELL_SIZE = 10,
    parameter IMAGE_WIDTH = 640,
    parameter IMAGE_HEIGHT = 480,
    parameter INIT_X = 10'd0,
    parameter INIT_Y = 9'd0,
    parameter MOVE_INTERVAL = 24'd8_000_000  // 控制移动速度（约0.3秒）
)(
    input clk,                   // 25MHz VGA 时钟
    input rst_n,                 // 低电平复位
   input [3:0] btn_udlr ,


    output reg [9:0] player_x,   // 像素单位，X 坐标
    output reg [8:0] player_y   // 像素单位，Y 坐标


);
reg [3:0] btn_prev;
    wire [3:0] btn_edge;
    assign btn_edge = btn_udlr & ~btn_prev;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            btn_prev <= 4'b0;
        else
            btn_prev <= btn_udlr;
    end
    
reg [3:0] move_dir;
wire [9:0] next_x;
wire [8:0] next_y;
wire allow_move;
wire move_valid;
    reg move_req;
    
 map_checker checker (
        .clk(clk),
        .rst_n(rst_n),
     
      .btn(btn),
        .player_x(player_x),
        .player_y(player_y),
        .next_x(next_x),
        .next_y(next_y),
        .allow_move(allow_move),
           .move_req(move_req),
        .move_valid (move_valid)
    );

// === 控制握手逻辑 ===
    reg [1:0] state;
    localparam WAIT_BTN = 2'd0, WAIT_CHECK = 2'd1;


 always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            player_x <= INIT_X;
            player_y <= INIT_Y;
            state <= WAIT_BTN;
            move_req <= 0;

        end else begin
            case (state)
                WAIT_BTN: begin
                    move_req <= 0;
                 if (btn_edge != 0) begin
    move_req <= 1;         // 发起地图检查请求
    state <= WAIT_CHECK;
end
                end
                WAIT_CHECK: begin
         
                    if (move_valid) begin
                        if (allow_move) begin
                            player_x <= next_x;
                            player_y <= next_y;
                        end
                         move_req <= 0; 
                        state <= WAIT_BTN;
                    end
                    
                end
            endcase
        end
    end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        move_dir <= 4'b0000;
    else if (state == WAIT_BTN && btn_edge != 0)
        move_dir <= btn_edge;
    else if (state == WAIT_CHECK && move_valid)
        move_dir <= 4'b0000;
end


endmodule