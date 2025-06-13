`timescale 1ns / 1ps

module map_rom_tb;

    reg clk = 0;
    reg [18:0] addr = 0;
    wire [11:0] pixel_data;

    // Instantiate the ROM wrapper module
    map_rom uut (
        .clk(clk),
        .addr(addr),
        .pixel_data(pixel_data)
    );

    // Generate clock: 100MHz
    always #5 clk = ~clk;

    // Simulation control
    initial begin
        $display("=== Starting map_rom Testbench ===");
        $monitor("Time=%0t | Addr=%d | Pixel=0x%03X", $time, addr, pixel_data);

        // wait some time for initialization
        #20;

        // Read a few pixels (e.g., top-left corner of screen)
        addr = 0;     #10;
        addr = 1;     #10;
        addr = 2;     #10;
        addr = 640;   #10;  // Second row
        addr = 641;   #10;
        addr = 1280;  #10;  // Third row
        addr = 20000; #10;  // Random sample
        addr = 307199;#10;  // Last pixel

        #20;
        $finish;
    end

endmodule
