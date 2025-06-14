
`timescale 1ns/1ps

module player_move_tb;
    reg clk;
    reg rst_n;
    reg [3:0] btn_udlr;
    wire [9:0] player_x;
    wire [8:0] player_y;
 wire [9:0] next_x;
    wire [8:0] next_y;
    wire allow_move;
    // Instantiate the player_move module
    player_move uut (
        .clk(clk),
        .rst_n(rst_n),
        .btn_udlr(btn_udlr),
        .player_x(player_x),
        .player_y(player_y),
        .next_x(next_x),
        .next_y(next_y),
        .allow_move(allow_move)
    );

    // 25MHz Clock generation
    initial clk = 0;
    always #20 clk = ~clk; // 40ns period -> 25MHz

    initial begin
        // Initialize signals
        rst_n = 0;
        btn_udlr = 4'b0000;
        #100;

        // Release reset
        rst_n = 1;
        #100;

        // Simulate UP button press (btn[0])
        btn_udlr = 4'b0001; #40;
        btn_udlr = 4'b0000; #200;

        // Simulate DOWN button press (btn[1])
        btn_udlr = 4'b0010; #40;
        btn_udlr = 4'b0000; #200;

        // Simulate RIGHT button press (btn[2])
        btn_udlr = 4'b0100; #40;
        btn_udlr = 4'b0000; #200;

        // Simulate LEFT button press (btn[3])
        btn_udlr = 4'b1000; #40;
        btn_udlr = 4'b0000; #200;

        // Finish simulation
        $stop;
    end
endmodule
