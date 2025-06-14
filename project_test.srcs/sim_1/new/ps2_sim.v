`timescale 1ns/1ps
module tb_ps2();

// 定义系统时钟和复位信号
reg clk;
reg rst;

// PS/2接口信号
reg ps2_clk;
reg ps2_data;

// 输出信号
wire up, down, left, right, enter;

// 实例化待测模块
ps2 uut (
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

// 生成50MHz系统时钟
always #10 clk = ~clk;  // 20ns周期

// PS/2时钟生成任务
task gen_ps2_clk;
    integer i;
    begin
        for(i=0; i<11; i=i+1) begin
            #500 ps2_clk = 1;
            #500 ps2_clk = 0;  // 1us周期 (1MHz)
        end
    end
endtask

// PS/2数据发送任务
task send_ps2;
    input [7:0] data;
    integer i;
    begin
        // 起始位 (0)
        ps2_data = 0;
        gen_ps2_clk();
      
        // 8位数据 (LSB first)
        for(i=0; i<8; i=i+1) begin
            ps2_data = data[i];
            gen_ps2_clk();
        end
      
        // 奇偶校验位 (0)
        ps2_data = 0;
        gen_ps2_clk();
      
        // 停止位 (1)
        ps2_data = 1;
        gen_ps2_clk();
      
        // 总线空闲
        ps2_data = 1;
        #2000;
    end
endtask

// 主测试过程
initial begin
    // 初始化信号
    clk = 0;
    rst = 1;
    ps2_clk = 1;
    ps2_data = 1;
  
    // 系统复位
    #100 rst = 0;
    #50;
  
    $display("开始仿真：方向键和回车键解码测试");
  
    // 测试序列
    // 1. 按下W键
    $display("[时间%0t] 发送W键按下", $time);
    send_ps2(8'h1D);
    #1000;
  
    // 2. 释放W键
    $display("[时间%0t] 发送W键释放", $time);
    send_ps2(8'hF0); // Break前缀
    send_ps2(8'h1D);
    #1000;
  
    // 3. 按下S键
    $display("[时间%0t] 发送S键按下", $time);
    send_ps2(8'h1B);
    #1000;
  
    // 4. 按下A键
    $display("[时间%0t] 发送A键按下", $time);
    send_ps2(8'h1C);
    #1000;
  
    // 5. 按下D键
    $display("[时间%0t] 发送D键按下", $time);
    send_ps2(8'h23);
    #1000;
  
    // 6. 按下Enter键
    $display("[时间%0t] 发送Enter键按下", $time);
    send_ps2(8'h5A);
    #1000;
  
    // 7. 释放Enter键
    $display("[时间%0t] 发送Enter键释放", $time);
    send_ps2(8'hF0); // Break前缀
    send_ps2(8'h5A);
    #1000;
  
    // 结束仿真
    $display("仿真结束");
    $finish;
end

// 监控输出变化
always @(posedge clk) begin
    if(up || down || left || right || enter) begin
        $display("[时间%0t] 输出状态: up=%b down=%b left=%b right=%b enter=%b", 
                $time, up, down, left, right, enter);
    end
end

endmodule