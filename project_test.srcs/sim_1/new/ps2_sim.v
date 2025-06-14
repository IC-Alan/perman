`timescale 1ns/1ps
module tb_ps2();

// ����ϵͳʱ�Ӻ͸�λ�ź�
reg clk;
reg rst;

// PS/2�ӿ��ź�
reg ps2_clk;
reg ps2_data;

// ����ź�
wire up, down, left, right, enter;

// ʵ��������ģ��
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

// ����50MHzϵͳʱ��
always #10 clk = ~clk;  // 20ns����

// PS/2ʱ����������
task gen_ps2_clk;
    integer i;
    begin
        for(i=0; i<11; i=i+1) begin
            #500 ps2_clk = 1;
            #500 ps2_clk = 0;  // 1us���� (1MHz)
        end
    end
endtask

// PS/2���ݷ�������
task send_ps2;
    input [7:0] data;
    integer i;
    begin
        // ��ʼλ (0)
        ps2_data = 0;
        gen_ps2_clk();
      
        // 8λ���� (LSB first)
        for(i=0; i<8; i=i+1) begin
            ps2_data = data[i];
            gen_ps2_clk();
        end
      
        // ��żУ��λ (0)
        ps2_data = 0;
        gen_ps2_clk();
      
        // ֹͣλ (1)
        ps2_data = 1;
        gen_ps2_clk();
      
        // ���߿���
        ps2_data = 1;
        #2000;
    end
endtask

// �����Թ���
initial begin
    // ��ʼ���ź�
    clk = 0;
    rst = 1;
    ps2_clk = 1;
    ps2_data = 1;
  
    // ϵͳ��λ
    #100 rst = 0;
    #50;
  
    $display("��ʼ���棺������ͻس����������");
  
    // ��������
    // 1. ����W��
    $display("[ʱ��%0t] ����W������", $time);
    send_ps2(8'h1D);
    #1000;
  
    // 2. �ͷ�W��
    $display("[ʱ��%0t] ����W���ͷ�", $time);
    send_ps2(8'hF0); // Breakǰ׺
    send_ps2(8'h1D);
    #1000;
  
    // 3. ����S��
    $display("[ʱ��%0t] ����S������", $time);
    send_ps2(8'h1B);
    #1000;
  
    // 4. ����A��
    $display("[ʱ��%0t] ����A������", $time);
    send_ps2(8'h1C);
    #1000;
  
    // 5. ����D��
    $display("[ʱ��%0t] ����D������", $time);
    send_ps2(8'h23);
    #1000;
  
    // 6. ����Enter��
    $display("[ʱ��%0t] ����Enter������", $time);
    send_ps2(8'h5A);
    #1000;
  
    // 7. �ͷ�Enter��
    $display("[ʱ��%0t] ����Enter���ͷ�", $time);
    send_ps2(8'hF0); // Breakǰ׺
    send_ps2(8'h5A);
    #1000;
  
    // ��������
    $display("�������");
    $finish;
end

// �������仯
always @(posedge clk) begin
    if(up || down || left || right || enter) begin
        $display("[ʱ��%0t] ���״̬: up=%b down=%b left=%b right=%b enter=%b", 
                $time, up, down, left, right, enter);
    end
end

endmodule