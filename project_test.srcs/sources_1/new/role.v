module role (
    input clk,
    input rst_n,
    input [11:0] pixel_data,  // ��ǰ���ص� RGB444
    input [18:0] addr,
    output reg [9:0] player_x = 0,
    output reg [8:0] player_y = 0
);
    localparam IMAGE_WIDTH = 640;
    reg found = 0;

    wire [9:0] x = addr % IMAGE_WIDTH;
    wire [8:0] y = addr / IMAGE_WIDTH;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            found <= 0;
            player_x <= 0;
            player_y <= 0;
        end else if (!found) begin
            if (pixel_data == 12'hFFF) begin  // ��ɫ��ʾ"·"
                player_x <= x;
                player_y <= y;
                found <= 1;
            end
        end
    end
endmodule
