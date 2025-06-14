module game_display(
    input wire clk,           // 系统时钟
    input wire rst_n,         // 低电平复位
    input wire [8:0] row_addr,  // VGA行地址
    input wire [9:0] col_addr,  // VGA列地址
    input wire [15:0] grid_0, // 第一行数据
    input wire [15:0] grid_1, // 第二行数据
    input wire [15:0] grid_2, // 第三行数据
    input wire [15:0] grid_3, // 第四行数据
    input wire game_over,     // 游戏结束标志
    input wire game_win,      // 游戏胜利标志
    output reg [11:0] vga_data // VGA像素数据
);

    // 游戏区域定义
    parameter GRID_SIZE = 80;           // 每个格子大小
    parameter GRID_GAP = 10;            // 格子间隔
    parameter GRID_BORDER = 20;         // 边框宽度
    parameter GRID_START_X = 160;       // 游戏区域起始X坐标
    parameter GRID_START_Y = 60;        // 游戏区域起始Y坐标
    parameter GRID_TOTAL_SIZE = 370;    // 游戏区域总大小

    // 颜色定义
    parameter COLOR_BG      = 12'hFFF;  // 背景色（白色）
    parameter COLOR_GRID_BG = 12'hCCC;  // 网格背景色（浅灰色）
    parameter COLOR_BORDER  = 12'h888;  // 边框色（深灰色）
    parameter COLOR_2       = 12'hEEE;  // 数字2的颜色
    parameter COLOR_4       = 12'hEDC;  // 数字4的颜色
    parameter COLOR_8       = 12'hFB8;  // 数字8的颜色
    parameter COLOR_16      = 12'hF96;  // 数字16的颜色
    parameter COLOR_32      = 12'hF75;  // 数字32的颜色
    parameter COLOR_64      = 12'hF53;  // 数字64的颜色
    parameter COLOR_128     = 12'hEC7;  // 数字128的颜色
    parameter COLOR_256     = 12'hEC6;  // 数字256的颜色
    parameter COLOR_512     = 12'hEC5;  // 数字512的颜色
    parameter COLOR_1024    = 12'hEC3;  // 数字1024的颜色
    parameter COLOR_2048    = 12'hEC2;  // 数字2048的颜色
    parameter COLOR_TEXT    = 12'h000;  // 文字颜色（黑色）
    parameter COLOR_WIN     = 12'h0F0;  // 胜利颜色（绿色）
    parameter COLOR_LOSE    = 12'hF00;  // 失败颜色（红色）

    // 内部信号
    wire in_grid_area;  // 是否在游戏区域内
    wire [1:0] grid_x;  // 当前格子X坐标(0-3)
    wire [1:0] grid_y;  // 当前格子Y坐标(0-3)
    wire [3:0] grid_val; // 当前格子的值
    wire in_grid_border; // 是否在格子边框上
    wire in_grid_gap;    // 是否在格子间隙中

    // 判断是否在游戏区域内
    assign in_grid_area = (col_addr >= GRID_START_X) && (col_addr < GRID_START_X + GRID_TOTAL_SIZE) &&
                         (row_addr >= GRID_START_Y) && (row_addr < GRID_START_Y + GRID_TOTAL_SIZE);

    // 计算当前扫描位置对应的格子坐标
    assign grid_x = (col_addr - GRID_START_X) / (GRID_SIZE + GRID_GAP);
    assign grid_y = (row_addr - GRID_START_Y) / (GRID_SIZE + GRID_GAP);

    // 获取当前格子的值
    assign grid_val = (grid_y == 0) ? grid_0[grid_x*4 +: 4] :
                     (grid_y == 1) ? grid_1[grid_x*4 +: 4] :
                     (grid_y == 2) ? grid_2[grid_x*4 +: 4] :
                                    grid_3[grid_x*4 +: 4];

    // 判断是否在格子边框上
    wire [9:0] rel_x = (col_addr - GRID_START_X) % (GRID_SIZE + GRID_GAP);
    wire [9:0] rel_y = (row_addr - GRID_START_Y) % (GRID_SIZE + GRID_GAP);
    assign in_grid_gap = (rel_x >= GRID_SIZE) || (rel_y >= GRID_SIZE);

    // 判断是否在游戏区域边框上
    wire in_game_border = (col_addr >= GRID_START_X - GRID_BORDER) && (col_addr < GRID_START_X + GRID_TOTAL_SIZE + GRID_BORDER) &&
                         (row_addr >= GRID_START_Y - GRID_BORDER) && (row_addr < GRID_START_Y + GRID_TOTAL_SIZE + GRID_BORDER) &&
                         !in_grid_area;

    // 根据数字值选择颜色
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

    // 简单的数字显示（仅显示2的幂次方）
    function is_number_pixel;
        input [3:0] val;
        input [9:0] rel_x, rel_y;
        begin
            // 数字在格子中央显示，简化为一个小方块
            is_number_pixel = (val != 0) && 
                            (rel_x >= GRID_SIZE/4) && (rel_x < GRID_SIZE*3/4) &&
                            (rel_y >= GRID_SIZE/4) && (rel_y < GRID_SIZE*3/4);
        end
    endfunction

    // 游戏胜利/失败信息显示
    wire show_game_result = game_win || game_over;
    wire [11:0] result_color = game_win ? COLOR_WIN : COLOR_LOSE;
    wire in_result_area = show_game_result && 
                         (col_addr >= GRID_START_X + GRID_TOTAL_SIZE/4) && 
                         (col_addr < GRID_START_X + GRID_TOTAL_SIZE*3/4) &&
                         (row_addr >= GRID_START_Y + GRID_TOTAL_SIZE/3) && 
                         (row_addr < GRID_START_Y + GRID_TOTAL_SIZE*2/3);

    // 生成VGA像素数据
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