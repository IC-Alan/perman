module game_display(
    input wire clk,           // ϵͳʱ��
    input wire rst_n,         // �͵�ƽ��λ
    input wire [8:0] row_addr,  // VGA�е�ַ
    input wire [9:0] col_addr,  // VGA�е�ַ
    input wire [15:0] grid_0, // ��һ������
    input wire [15:0] grid_1, // �ڶ�������
    input wire [15:0] grid_2, // ����������
    input wire [15:0] grid_3, // ����������
    input wire game_over,     // ��Ϸ������־
    input wire game_win,      // ��Ϸʤ����־
    output reg [11:0] vga_data // VGA��������
);

    // ��Ϸ������
    parameter GRID_SIZE = 80;           // ÿ�����Ӵ�С
    parameter GRID_GAP = 10;            // ���Ӽ��
    parameter GRID_BORDER = 20;         // �߿���
    parameter GRID_START_X = 160;       // ��Ϸ������ʼX����
    parameter GRID_START_Y = 60;        // ��Ϸ������ʼY����
    parameter GRID_TOTAL_SIZE = 370;    // ��Ϸ�����ܴ�С

    // ��ɫ����
    parameter COLOR_BG      = 12'hFFF;  // ����ɫ����ɫ��
    parameter COLOR_GRID_BG = 12'hCCC;  // ���񱳾�ɫ��ǳ��ɫ��
    parameter COLOR_BORDER  = 12'h888;  // �߿�ɫ�����ɫ��
    parameter COLOR_2       = 12'hEEE;  // ����2����ɫ
    parameter COLOR_4       = 12'hEDC;  // ����4����ɫ
    parameter COLOR_8       = 12'hFB8;  // ����8����ɫ
    parameter COLOR_16      = 12'hF96;  // ����16����ɫ
    parameter COLOR_32      = 12'hF75;  // ����32����ɫ
    parameter COLOR_64      = 12'hF53;  // ����64����ɫ
    parameter COLOR_128     = 12'hEC7;  // ����128����ɫ
    parameter COLOR_256     = 12'hEC6;  // ����256����ɫ
    parameter COLOR_512     = 12'hEC5;  // ����512����ɫ
    parameter COLOR_1024    = 12'hEC3;  // ����1024����ɫ
    parameter COLOR_2048    = 12'hEC2;  // ����2048����ɫ
    parameter COLOR_TEXT    = 12'h000;  // ������ɫ����ɫ��
    parameter COLOR_WIN     = 12'h0F0;  // ʤ����ɫ����ɫ��
    parameter COLOR_LOSE    = 12'hF00;  // ʧ����ɫ����ɫ��

    // �ڲ��ź�
    wire in_grid_area;  // �Ƿ�����Ϸ������
    wire [1:0] grid_x;  // ��ǰ����X����(0-3)
    wire [1:0] grid_y;  // ��ǰ����Y����(0-3)
    wire [3:0] grid_val; // ��ǰ���ӵ�ֵ
    wire in_grid_border; // �Ƿ��ڸ��ӱ߿���
    wire in_grid_gap;    // �Ƿ��ڸ��Ӽ�϶��

    // �ж��Ƿ�����Ϸ������
    assign in_grid_area = (col_addr >= GRID_START_X) && (col_addr < GRID_START_X + GRID_TOTAL_SIZE) &&
                         (row_addr >= GRID_START_Y) && (row_addr < GRID_START_Y + GRID_TOTAL_SIZE);

    // ���㵱ǰɨ��λ�ö�Ӧ�ĸ�������
    assign grid_x = (col_addr - GRID_START_X) / (GRID_SIZE + GRID_GAP);
    assign grid_y = (row_addr - GRID_START_Y) / (GRID_SIZE + GRID_GAP);

    // ��ȡ��ǰ���ӵ�ֵ
    assign grid_val = (grid_y == 0) ? grid_0[grid_x*4 +: 4] :
                     (grid_y == 1) ? grid_1[grid_x*4 +: 4] :
                     (grid_y == 2) ? grid_2[grid_x*4 +: 4] :
                                    grid_3[grid_x*4 +: 4];

    // �ж��Ƿ��ڸ��ӱ߿���
    wire [9:0] rel_x = (col_addr - GRID_START_X) % (GRID_SIZE + GRID_GAP);
    wire [9:0] rel_y = (row_addr - GRID_START_Y) % (GRID_SIZE + GRID_GAP);
    assign in_grid_gap = (rel_x >= GRID_SIZE) || (rel_y >= GRID_SIZE);

    // �ж��Ƿ�����Ϸ����߿���
    wire in_game_border = (col_addr >= GRID_START_X - GRID_BORDER) && (col_addr < GRID_START_X + GRID_TOTAL_SIZE + GRID_BORDER) &&
                         (row_addr >= GRID_START_Y - GRID_BORDER) && (row_addr < GRID_START_Y + GRID_TOTAL_SIZE + GRID_BORDER) &&
                         !in_grid_area;

    // ��������ֵѡ����ɫ
    function [11:0] get_grid_color;
        input [3:0] val;
        begin
            case (val)
                4'd0:  get_grid_color = COLOR_GRID_BG;
                4'd1:  get_grid_color = COLOR_2;
                4'd2:  get_grid_color = COLOR_4;
                4'd3:  get_grid_color = COLOR_8;
                4'd4:  get_grid_color = COLOR_16;
                4'd5:  get_grid_color = COLOR_32;
                4'd6:  get_grid_color = COLOR_64;
                4'd7:  get_grid_color = COLOR_128;
                4'd8:  get_grid_color = COLOR_256;
                4'd9:  get_grid_color = COLOR_512;
                4'd10: get_grid_color = COLOR_1024;
                4'd11: get_grid_color = COLOR_2048;
                default: get_grid_color = COLOR_GRID_BG;
            endcase
        end
    endfunction

    // �򵥵�������ʾ������ʾ2���ݴη���
    function is_number_pixel;
        input [3:0] val;
        input [9:0] rel_x, rel_y;
        begin
            // �����ڸ���������ʾ����Ϊһ��С����
            is_number_pixel = (val != 0) && 
                            (rel_x >= GRID_SIZE/4) && (rel_x < GRID_SIZE*3/4) &&
                            (rel_y >= GRID_SIZE/4) && (rel_y < GRID_SIZE*3/4);
        end
    endfunction

    // ��Ϸʤ��/ʧ����Ϣ��ʾ
    wire show_game_result = game_win || game_over;
    wire [11:0] result_color = game_win ? COLOR_WIN : COLOR_LOSE;
    wire in_result_area = show_game_result && 
                         (col_addr >= GRID_START_X + GRID_TOTAL_SIZE/4) && 
                         (col_addr < GRID_START_X + GRID_TOTAL_SIZE*3/4) &&
                         (row_addr >= GRID_START_Y + GRID_TOTAL_SIZE/3) && 
                         (row_addr < GRID_START_Y + GRID_TOTAL_SIZE*2/3);

    // ����VGA��������
    always @(*) begin
        if (in_game_border)
            vga_data = COLOR_BORDER;
        else if (in_grid_area) begin
            if (in_grid_gap)
                vga_data = COLOR_GRID_BG;
            else if (in_result_area)
                vga_data = result_color;
            else if (is_number_pixel(grid_val, rel_x, rel_y))
                vga_data = COLOR_TEXT;
            else
                vga_data = get_grid_color(grid_val);
        end
        else
            vga_data = COLOR_BG;
    end

endmodule