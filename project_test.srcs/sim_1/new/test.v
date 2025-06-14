`timescale 1ns / 1ps

module map_checker_tb;
    reg clk, rst_n;
    reg [3:0] btn;
    reg [9:0] player_x;
    reg [8:0] player_y;
    wire [9:0] next_x;
    wire [8:0] next_y;
    wire allow_move;

    // 实例化被测模块
    map_checker uut (
        .clk(clk),
        .rst_n(rst_n),
        .btn(btn),
        .player_x(player_x),
        .player_y(player_y),
        .next_x(next_x),
        .next_y(next_y),
        .allow_move(allow_move)
    );

    // 25MHz时钟生成 (周期40ns)
    initial begin
        clk = 0;
        forever #20 clk = ~clk;  // 40ns周期 = 25MHz
    end

    // 主测试序列
    initial begin
        // 初始化变量
        rst_n = 0;
        btn = 4'b0000;
    
        // 设置初始位置为 (1,1)
        player_x = 10'd10;  // 对应格子坐标(1,1)
        player_y = 9'd10;
    
        // 生成复位信号 (延长以适应25MHz)
        #200;  // 5个时钟周期
        rst_n = 1;
    
        // === 测试序列 ===
    
        // 测试1：向上移动 (可能撞墙)
        $display("=== 测试1：向上移动 (↑) @ %0tns ===", $time);
        #40 btn = 4'b0001;  // ↑按键
        #120 btn = 4'b0000;  // 释放按键 (3个时钟周期)
        #200;  // 等待状态机完成 (5个时钟周期)
    
        // 测试2：向下移动
        $display("=== 测试2：向下移动 (↓) @ %0tns ===", $time);
        #40 btn = 4'b0010;  // ↓按键
        #120 btn = 4'b0000;
        #200;
    
        // 测试3：向左移动 (可能撞墙)
        $display("=== 测试3：向左移动 (←) @ %0tns ===", $time);
        #40 btn = 4'b1000;  // ←按键
        #120 btn = 4'b0000;
        #200;
    
        // 测试4：向右移动
        $display("=== 测试4：向右移动 (→) @ %0tns ===", $time);
        #40 btn = 4'b0100;  // →按键
        #120 btn = 4'b0000;
        #200;
    
        $display("仿真完成 @ %0tns", $time);
        $finish;
    end

    // 实时信号监视器 - 添加map_data显示（通过层次引用）
    always @(posedge clk) begin
        $display("[%0tns] CLK↑ | BTN=%4b | CurPos: X=%3d Y=%3d | NextPos: X=%3d Y=%3d | Allow=%b | MapData=%b | State=%d | Addr=%h", 
                 $time, 
                 btn, 
                 player_x, 
                 player_y, 
                 next_x, 
                 next_y, 
                 allow_move,
                 uut.map_data,    // 使用层次引用显示map_data值
                 uut.state, 
                 uut.addr);
    end

    // 生成波形文件 - 添加map_data（通过层次引用）
    initial begin
        $dumpfile("map_checker_wave.vcd");
        $dumpvars(0, map_checker_tb);
        $dumpvars(0, uut); // 添加uut模块所有信号
    end
endmodule