module map_rom (
    input wire clk,
    input wire [18:0] addr,         // 640×480 = 307200 地址空间
    output wire [11:0] pixel_data   // 输出像素值：RRRR_GGGG_BBBB
);
    // 实例化 Vivado IP 生成的模块
    blk_mem_gen_0 u_rom (
        .clka(clk),
        .addra(addr),
        .douta(pixel_data)
    );
endmodule
