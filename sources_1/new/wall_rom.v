module wall_rom (
    input wire clk,
    input wire [11:0] addr,     // 0~3071
    output reg wall
);
    wire [0:0] rom_out;

    // ʵ���� Vivado ���ɵ� IP
    wall_rom_ip rom_inst (
        .clka(clk),
        .addra(addr),
        .douta(rom_out)
    );

    always @(posedge clk) begin
        wall <= rom_out[0];
    end
endmodule
