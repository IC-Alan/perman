`timescale 1ns / 1ps

module tb_ps2();
    reg clk;
    reg rst;
    reg ps2_clk;
    reg ps2_data;
    wire up;
    wire down;
    wire left;
    wire right;
    wire enter;
    
    // 实例化设计
    ps2 dut (
        .clk(clk),
        .rst(rst),
        .ps2_clk(ps2_clk),
        .ps2_data(ps2_data),
        .up(up),
        .down(down),
        .left(left),
        .right(right),
        .enter(enter)
    );
    
    // 时钟参数
    parameter PS2_CLK_PERIOD = 100_000; // 100 μs (10 kHz)
    parameter SYS_CLK_PERIOD = 10;      // 10 ns (100 MHz)
    
    // 系统时钟
    initial clk = 0;
    always #(SYS_CLK_PERIOD/2) clk = ~clk;
    
    // PS/2 帧发送任务
    task send_ps2_frame;
        input [7:0] data;
        integer i;
        begin
            // 开始位 (0)
            ps2_data = 0;
            #(PS2_CLK_PERIOD/2);
            ps2_clk = 0;
            #(PS2_CLK_PERIOD/2);
            ps2_clk = 1;
            
            // 数据位 (LSB 优先)
            for (i = 0; i < 8; i = i + 1) begin
                ps2_data = data[i];
                #(PS2_CLK_PERIOD/2);
                ps2_clk = 0;
                #(PS2_CLK_PERIOD/2);
                ps2_clk = 1;
            end
            
            // 奇偶校验位 (简单设为1)
            ps2_data = 1;
            #(PS2_CLK_PERIOD/2);
            ps2_clk = 0;
            #(PS2_CLK_PERIOD/2);
            ps2_clk = 1;
            
            // 停止位 (1)
            ps2_data = 1;
            #(PS2_CLK_PERIOD/2);
            ps2_clk = 0;
            #(PS2_CLK_PERIOD/2);
            ps2_clk = 1;
            
            // 空闲状态
            ps2_data = 1;
            #(PS2_CLK_PERIOD);
        end
    endtask
    
    // 主测试序列
    initial begin
        // 初始化信号
        rst = 1;
        ps2_clk = 1;
        ps2_data = 1;
        #100;
        
        // 释放复位
        rst = 0;
        #100;
        
        // 测试用例1: 按下 W 键
        $display("测试用例1: 按下 W 键");
        send_ps2_frame(8'h1D); // W 键扫描码
        #500;
        
        // 测试用例2: 释放 W 键
        $display("测试用例2: 释放 W 键");
        send_ps2_frame(8'hF0); // Break 码
        send_ps2_frame(8'h1D); // W 键扫描码
        #500;
        
        // 测试用例3: 按下 S 键
        $display("测试用例3: 按下 S 键");
        send_ps2_frame(8'h1B); // S 键扫描码
        #500;
        
        // 测试用例4: 释放 S 键
        $display("测试用例4: 释放 S 键");
        send_ps2_frame(8'hF0); // Break 码
        send_ps2_frame(8'h1B); // S 键扫描码
        #500;
        
        // 测试用例5: 按下 A 键
        $display("测试用例5: 按下 A 键");
        send_ps2_frame(8'h1C); // A 键扫描码
        #500;
        
        // 测试用例6: 释放 A 键
        $display("测试用例6: 释放 A 键");
        send_ps2_frame(8'hF0); // Break 码
        send_ps2_frame(8'h1C); // A 键扫描码
        #500;
        
        // 测试用例7: 按下 D 键
        $display("测试用例7: 按下 D 键");
        send_ps2_frame(8'h23); // D 键扫描码
        #500;
        
        // 测试用例8: 释放 D 键
        $display("测试用例8: 释放 D 键");
        send_ps2_frame(8'hF0); // Break 码
        send_ps2_frame(8'h23); // D 键扫描码
        #500;
        
        // 测试用例9: 按下 Enter 键
        $display("测试用例9: 按下 Enter 键");
        send_ps2_frame(8'h5A); // Enter 键扫描码
        #500;
        
        // 测试用例10: 释放 Enter 键
        $display("测试用例10: 释放 Enter 键");
        send_ps2_frame(8'hF0); // Break 码
        send_ps2_frame(8'h5A); // Enter 键扫描码
        #500;
        
        $display("所有测试完成");
        $finish;
    end
    
    // 监控按键状态
    always @(posedge clk) begin
        if (!rst) begin
            $monitor("时间=%0tns: W=%b S=%b A=%b D=%b Enter=%b", 
                     $time, up, down, left, right, enter);
        end
    end
    
    // 波形文件生成
    initial begin
        $dumpfile("ps2_sim.vcd");
        $dumpvars(0, tb_ps2);
    end
endmodule
