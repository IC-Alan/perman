module pacman_ctrl (
    input wire clk,
    input wire reset,
    input wire [3:0] dir,  // {up, down, left, right}
    output reg [9:0] pac_x,
    output reg [8:0] pac_y
);
    parameter STEP = 1;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pac_x <= 320;
            pac_y <= 240;
        end else begin
            if (dir[3] && pac_y > 0)       pac_y <= pac_y - STEP;
            else if (dir[2] && pac_y < 464) pac_y <= pac_y + STEP;
            else if (dir[1] && pac_x > 0)   pac_x <= pac_x - STEP;
            else if (dir[0] && pac_x < 624) pac_x <= pac_x + STEP;
        end
    end
endmodule
