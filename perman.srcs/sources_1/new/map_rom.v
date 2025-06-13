module map_rom (
    input wire clk,
    input wire [18:0] addr,         // 640��480 = 307200 ��ַ�ռ�
    output wire [11:0] pixel_data   // �������ֵ��RRRR_GGGG_BBBB
);
    // ʵ���� Vivado IP ���ɵ�ģ��
    blk_mem_gen_0 u_rom (
        .clka(clk),
        .addra(addr),
        .douta(pixel_data)
    );
endmodule
