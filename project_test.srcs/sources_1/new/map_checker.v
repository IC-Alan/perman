module map_checker (
    input clk,
    input rst_n,
    input [3:0] btn,
    input [9:0] player_x,
    input [8:0] player_y,
    output reg [9:0] next_x,
    output reg [8:0] next_y,
    output reg allow_move,
 input move_req,             // 新增：请求判断信号
   output reg move_valid          // 判断完成标志，握手信号
);
    // 地图 ROM 内部定义
    reg [15:0] addr;
    wire map_data;

    wall_rom rom_inst (
        .clka(clk),
        .addra(addr),
        .douta(map_data)
    );

    // FSM 状态
  reg [3:0] state;
  localparam IDLE = 3'd0, READ = 3'd1, WAIT = 3'd2, CHECK = 3'd3, DONE = 3'd4;


    wire [9:0] next_x_potential = (btn[2] ? player_x + 10 : (btn[3] ? player_x - 10 : player_x));
    wire [8:0] next_y_potential = (btn[0] ? player_y - 10 : (btn[1] ? player_y + 10 : player_y));

   always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            allow_move <= 0;
            move_valid <= 0;
            next_x <= player_x;
            next_y <= player_y;
        end else begin
            case (state)
                IDLE: begin
                    allow_move <= 0;
                    move_valid <= 0;
                    if (move_req) begin
                        next_x <= next_x_potential;
                        next_y <= next_y_potential;
                        addr <= (next_y_potential / 10) * 64 + (next_x_potential / 10);
                        state <= READ;
                    end
                end
                READ: begin
                   state <= WAIT;
                    end
                WAIT: begin
    // ROM 数据此时刚刚准备好
        state <= CHECK;
    end
        CHECK: begin
    allow_move <= (map_data == 1'b0);  // 判断是否是可走区域
    state <= DONE;
    end
        DONE: begin
        move_valid <= 1'b1;
        state <= IDLE;
end
            endcase
        end
    end
endmodule
