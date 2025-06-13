`include "player_pos.vh"  // ��ʼλ�ú궨��

module top(
    input clk,               // 100MHzϵͳʱ��
    input rst_n,             // �첽��λ������Ч��
    input [3:0] btn,         // �ķ���ť [��,��,��,��]
    output [3:0] r, g, b,    // RGB444���
    output hs, vs            // ͬ���ź�
);

    // === �������� ===
    localparam IMAGE_WIDTH     = 640;
    localparam IMAGE_HEIGHT    = 480;
    localparam CELL_SIZE       = 10;
    localparam PLAYER_COLOR    = 12'h00F; // ��ɫ
    localparam BEAN_COLOR      = 12'hFF0; // ��ɫ
    localparam EMPTY           = 1'b0;

    // === VGA ʱ�� 25MHz ===
    wire clk_25MHz;
    clk_wiz_0 clk_gen (
        .clk_in1(clk),
        .clk_out1(clk_25MHz)
    );

    // === VGA �����ź� ===
    wire [8:0] screen_row_addr;
    wire [9:0] screen_col_addr;
    wire vga_pixel_enable;

    // === ��ͼ ROM ���� ===
    reg [18:0] rom_access_addr;
    wire [11:0] rom_data_out;
    reg [11:0] rom_data_buffer;

    always @(posedge clk_25MHz)
        rom_data_buffer <= rom_data_out;

    maze rom_inst (
        .clka(clk_25MHz),
        .ena(1'b1),
        .addra(rom_access_addr),
        .douta(rom_data_out)
    );

    always @(posedge clk_25MHz or negedge rst_n) begin
        if (!rst_n)
            rom_access_addr <= 19'd0;
        else if (screen_col_addr < 640 && screen_row_addr < 480)
            // ����˷���row*640 = row*512 + row*128
            rom_access_addr <= (screen_row_addr << 9) + (screen_row_addr << 7) + screen_col_addr;
    end

    // === VGA ���ģ�� ===
   reg [11:0] pixel_rgb;
    VGA vga_unit (
        .vga_clk(clk_25MHz),
        .clrn(rst_n),
        .d_in(pixel_rgb),
        .row_addr(screen_row_addr),
        .col_addr(screen_col_addr),
        .rdn(vga_pixel_enable),
        .r(r), .g(g), .b(b),
        .hs(hs), .vs(vs)
    );

 //ȥ����
    wire [3:0] btn_debounced;

debounce_all u_debounce (
    .clk(clk_25MHz),
    .rst_n(rst_n),
    .btn_in(btn),
    .btn_out(btn_debounced)
);
    // === �����ƶ�ģ�� ===
    wire [9:0] player_x;
    wire [8:0] player_y;
     // �����ƶ�ģ�飨��ײǽ�жϣ�
player_move #(
    .CELL_SIZE(CELL_SIZE),
    .IMAGE_WIDTH(IMAGE_WIDTH),
    .IMAGE_HEIGHT(IMAGE_HEIGHT),
    .INIT_X(`PLAYER_INIT_X),
    .INIT_Y(`PLAYER_INIT_Y)
) player_ctrl (
    .clk(clk_25MHz),
    .rst_n(rst_n),
    .btn_udlr( btn_debounced),
    .player_x(player_x),
    .player_y(player_y)

);

    wire is_player_pixel = 
        (screen_col_addr >= player_x + 3) && (screen_col_addr < player_x + 3 + CELL_SIZE) &&
        (screen_row_addr >= player_y) && (screen_row_addr < player_y + CELL_SIZE);

       // === ���� RAM ===
    wire [5:0] grid_x = screen_col_addr / CELL_SIZE;
    wire [5:0] grid_y = screen_row_addr / CELL_SIZE;
    wire [5:0] player_cell_x = player_x / CELL_SIZE;
    wire [5:0] player_cell_y = player_y / CELL_SIZE;

    // �����ӳ�һ�ĵ������������
    reg [5:0] player_cell_x_r, player_cell_y_r;
    always @(posedge clk_25MHz) begin
        player_cell_x_r <= player_cell_x;
        player_cell_y_r <= player_cell_y;
    end

    // RAM ��ַ��A��������ʾ��B�����ڼ���д��
    wire [18:0] bean_display_addr = grid_y * 64 + grid_x;
    wire [18:0] bean_eat_addr     = player_cell_y_r * 64 + player_cell_x_r;

    wire bean_display_data;
    wire bean_present;

    reg we, en;


 // === �Զ� FSM���Ľ��棺����д�룩 ===
reg bean_present_d1;  // ��һ���ӳ�
reg [1:0] eat_state;
localparam IDLE  = 2'd0,
           WRITE = 2'd1,
           WAIT  = 2'd2;

// �޸ĺ�ĳԶ� FSM
always @(posedge clk_25MHz or negedge rst_n) begin
    if (!rst_n) begin
        eat_state <= IDLE;
        we <= 0;
        en <= 1;  // ����ʹ��һֱ��Ч
        bean_present_d1 <= 0;
    end else begin
        bean_present_d1 <= bean_present;
        case (eat_state)
            IDLE: begin
                we <= 0;
                if (bean_present_d1 == 1'b1)
                    eat_state <= WRITE;
            end
            WRITE: begin
                we <= 1;
                eat_state <= WAIT;
            end
            WAIT: begin
                we <= 0;
                eat_state <= IDLE;
            end
            default: eat_state <= IDLE;
        endcase
    end
end

// ��en_b����1����֤��д�˿�������Ч
reg en_b_reg = 1;
always @(posedge clk_25MHz or negedge rst_n) begin
    if (!rst_n)
        en_b_reg <= 1'b1;
    else
        en_b_reg <= 1'b1;
end

// RAMģ�����ʱ��en_b_reg���en_b
bean_ram u_bean_ram (
    .clk(clk_25MHz),
    .rst_n(rst_n),
    .raddr_a(bean_display_addr),
    .rdata_a(bean_display_data),
    .raddr_b(bean_eat_addr),
    .rdata_b(bean_present),
    .waddr_b(bean_eat_addr),
    .wdata_b(EMPTY),
    .we_b(we),
    .en_b(en_b_reg)
);


    // === ���������ж� ===
    wire is_bean_pixel = 
        (bean_display_data == 1'b1) &&
        (screen_col_addr >= grid_x * CELL_SIZE) && 
        (screen_col_addr < (grid_x + 1) * CELL_SIZE) &&
        (screen_row_addr >= grid_y * CELL_SIZE) &&
        (screen_row_addr < (grid_y + 1) * CELL_SIZE);
// ��ӼƷֺͳɹ��ź�
reg [2:0] score;      // 3λ�㹻��0~5
reg success;

always @(posedge clk_25MHz or negedge rst_n) begin
    if (!rst_n) begin
        score <= 3'd0;
        success <= 1'b0;
    end else begin
        // ֻҪû�ɹ��ҳԵ����Ӿ�+1��
        if ((eat_state == WRITE) && !success) begin
            score <= score + 1'b1;
            if (score + 1'b1 >= 3'd5)
                success <= 1'b1;
        end
    end
end

wire [11:0] success_pixel_rgb;
wire [18:0] success_addr = screen_row_addr * IMAGE_WIDTH + screen_col_addr;

game_over u_success_rom (
    .clka(clk_25MHz),  // ʼ��ʹ��
    .addra(success_addr),
    .douta(success_pixel_rgb)
); 

// ����success_addr


   
always @(posedge clk_25MHz or negedge rst_n)
begin
    if(!rst_n)
        pixel_rgb <= 12'b0;  // ��λʱ�����ɫ
         else if (success) 
        // �ɹ�����������ʾ
        pixel_rgb <= success_pixel_rgb; 
      else if (is_player_pixel)
        pixel_rgb <= 12'h00F;  // ��ɫ����
else if (is_bean_pixel)
        pixel_rgb <= 12'hFF0;  // ��ɫ���ӣ���������

    else if(screen_col_addr >= 0 && screen_col_addr <= 639 && 
            screen_row_addr >= 0 && screen_row_addr <= 479)
        pixel_rgb <= rom_data_out[11:0];  // ��ͼ����
    else
        pixel_rgb <= 12'b0;  // ��ɫ��������

end



endmodule