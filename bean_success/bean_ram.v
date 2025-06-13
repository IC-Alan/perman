module bean_ram (
    input clk,                // 时钟
    input rst_n,              // 复位

    // 端口A：只读，用于 VGA 显示
    input [18:0] raddr_a,     // VGA 正在扫描的地址
    output [0:0] rdata_a,     // 输出：当前格子是否有豆子

    // 端口B：用于人物读取和写入（吃豆）
    input [18:0] raddr_b,     // 人物当前所在格子地址
    output [0:0] rdata_b,     // 输出：人物是否站在有豆子的格子
    input [18:0] waddr_b,     // 写入地址（和 raddr_b 通常一样）
    input [0:0] wdata_b,      // 写入数据（通常是 0）
    input we_b,               // 写使能
    input en_b                // 写端口使能
);

    bean_map u_bean_map (
        // 端口A：只读
        .clka(clk),
        .wea(1'b0),
        .addra(raddr_a),
        .dina(1'b0),
        .douta(rdata_a),

        // 端口B：读写
        .clkb(clk),
        .enb(en_b),
        .web({we_b}),          // 1-bit 写使能
        .addrb(waddr_b),
        .dinb(wdata_b),
        .doutb(rdata_b)        // 读数据（人物格子是否有豆）
    );

endmodule
