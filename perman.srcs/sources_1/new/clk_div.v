module clk_div (
    input wire clk,         // 100 MHz
    output reg clk_out      // 25 MHz
);
    reg [1:0] cnt = 0;

    always @(posedge clk) begin
        cnt <= cnt + 1;
        if (cnt == 2'd3) begin
            cnt <= 0;
            clk_out <= ~clk_out;
        end
    end
endmodule
