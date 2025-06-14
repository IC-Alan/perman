`timescale 1ns / 1ps

module map_checker_tb;
    reg clk, rst_n;
    reg [3:0] btn;
    reg [9:0] player_x;
    reg [8:0] player_y;
    wire [9:0] next_x;
    wire [8:0] next_y;
    wire allow_move;

    // ʵ��������ģ��
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

    // 25MHzʱ������ (����40ns)
    initial begin
        clk = 0;
        forever #20 clk = ~clk;  // 40ns���� = 25MHz
    end

    // ����������
    initial begin
        // ��ʼ������
        rst_n = 0;
        btn = 4'b0000;
    
        // ���ó�ʼλ��Ϊ (1,1)
        player_x = 10'd10;  // ��Ӧ��������(1,1)
        player_y = 9'd10;
    
        // ���ɸ�λ�ź� (�ӳ�����Ӧ25MHz)
        #200;  // 5��ʱ������
        rst_n = 1;
    
        // === �������� ===
    
        // ����1�������ƶ� (����ײǽ)
        $display("=== ����1�������ƶ� (��) @ %0tns ===", $time);
        #40 btn = 4'b0001;  // ������
        #120 btn = 4'b0000;  // �ͷŰ��� (3��ʱ������)
        #200;  // �ȴ�״̬����� (5��ʱ������)
    
        // ����2�������ƶ�
        $display("=== ����2�������ƶ� (��) @ %0tns ===", $time);
        #40 btn = 4'b0010;  // ������
        #120 btn = 4'b0000;
        #200;
    
        // ����3�������ƶ� (����ײǽ)
        $display("=== ����3�������ƶ� (��) @ %0tns ===", $time);
        #40 btn = 4'b1000;  // ������
        #120 btn = 4'b0000;
        #200;
    
        // ����4�������ƶ�
        $display("=== ����4�������ƶ� (��) @ %0tns ===", $time);
        #40 btn = 4'b0100;  // ������
        #120 btn = 4'b0000;
        #200;
    
        $display("������� @ %0tns", $time);
        $finish;
    end

    // ʵʱ�źż����� - ���map_data��ʾ��ͨ��������ã�
    always @(posedge clk) begin
        $display("[%0tns] CLK�� | BTN=%4b | CurPos: X=%3d Y=%3d | NextPos: X=%3d Y=%3d | Allow=%b | MapData=%b | State=%d | Addr=%h", 
                 $time, 
                 btn, 
                 player_x, 
                 player_y, 
                 next_x, 
                 next_y, 
                 allow_move,
                 uut.map_data,    // ʹ�ò��������ʾmap_dataֵ
                 uut.state, 
                 uut.addr);
    end

    // ���ɲ����ļ� - ���map_data��ͨ��������ã�
    initial begin
        $dumpfile("map_checker_wave.vcd");
        $dumpvars(0, map_checker_tb);
        $dumpvars(0, uut); // ���uutģ�������ź�
    end
endmodule