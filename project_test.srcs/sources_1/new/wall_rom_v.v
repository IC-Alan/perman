module wall_rom_v (
    input clka,
    input [15:0] addra,
    output reg douta
);
    // 定义 64×48 个单元（对应640×480, CELL_SIZE=10）
    reg [0:3071] map_data;  // 64*48=3072
        integer i;
    initial begin

        for (i = 0; i < 3072; i = i + 1)
            map_data[i] = 1'b0; // 全部是路

    
    end

    always @(posedge clka)
        douta <= map_data[addra];
endmodule
