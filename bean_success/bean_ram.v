module bean_ram (
    input clk,                // ʱ��
    input rst_n,              // ��λ

    // �˿�A��ֻ�������� VGA ��ʾ
    input [18:0] raddr_a,     // VGA ����ɨ��ĵ�ַ
    output [0:0] rdata_a,     // �������ǰ�����Ƿ��ж���

    // �˿�B�����������ȡ��д�루�Զ���
    input [18:0] raddr_b,     // ���ﵱǰ���ڸ��ӵ�ַ
    output [0:0] rdata_b,     // ����������Ƿ�վ���ж��ӵĸ���
    input [18:0] waddr_b,     // д���ַ���� raddr_b ͨ��һ����
    input [0:0] wdata_b,      // д�����ݣ�ͨ���� 0��
    input we_b,               // дʹ��
    input en_b                // д�˿�ʹ��
);

    bean_map u_bean_map (
        // �˿�A��ֻ��
        .clka(clk),
        .wea(1'b0),
        .addra(raddr_a),
        .dina(1'b0),
        .douta(rdata_a),

        // �˿�B����д
        .clkb(clk),
        .enb(en_b),
        .web({we_b}),          // 1-bit дʹ��
        .addrb(waddr_b),
        .dinb(wdata_b),
        .doutb(rdata_b)        // �����ݣ���������Ƿ��ж���
    );

endmodule
