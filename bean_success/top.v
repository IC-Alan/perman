`include "player_pos.vh"  // ³õÊ¼Î»ÖÃºê¶¨Òå

module top(
    input clk,               // 100MHzÏµÍ³Ê±ÖÓ
    input rst_n,             // Òì²½¸´Î»£¨µÍÓÐÐ§£©
    input [3:0] btn,         // ËÄ·½Ïò°´Å¥ [ÉÏ,ÏÂ,×ó,ÓÒ]
	input ps2_clk,
	input ps2_data,
    output [3:0] r, g, b,    // RGB444Êä³ö
    output hs, vs            // Í¬²½ÐÅºÅ
);

    // === ²ÎÊý¶¨Òå ===
    localparam IMAGE_WIDTH     = 640;
    localparam IMAGE_HEIGHT    = 480;
    localparam CELL_SIZE       = 10;
    localparam PLAYER_COLOR    = 12'h00F; // À¶É«
    localparam BEAN_COLOR      = 12'hFF0; // »ÆÉ«
    localparam EMPTY           = 1'b0;

    // === VGA Ê±ÖÓ 25MHz ===
    wire clk_25MHz;
    clk_wiz_0 clk_gen (
        .clk_in1(clk),
        .clk_out1(clk_25MHz)
    );

    // === VGA ¿ØÖÆÐÅºÅ ===
    wire [8:0] screen_row_addr;
    wire [9:0] screen_col_addr;
    wire vga_pixel_enable;

    // === µØÍ¼ ROM ·ÃÎÊ ===
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
            // Ìæ´ú³Ë·¨£ºrow*640 = row*512 + row*128
            rom_access_addr <= (screen_row_addr << 9) + (screen_row_addr << 7) + screen_col_addr;
    end

    // === VGA Êä³öÄ£¿é ===
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

 //È¥¶¶¶¯
    wire [3:0] btn_debounced;
	wire ctrl_up, ctrp_left, ctrl_right, ctrl_down, ctrl_enter;

debounce_all u_debounce (
    .clk(clk_25MHz),
    .rst_n(rst_n),
    .btn_in(btn),
    .btn_out(btn_debounced)
);

// This is introducing PS2 keyboard.
ps2 u_ps2(
	.clk(clk_25MHz),
	.rst(!rst_n),
	.ps2_clk(ps2_clk),
	.ps2_data(ps2_data),
	.up(ctrl_up),
	.left(ctrl_left),
	.right(ctrl_right),
	.down(ctrl_down),
	.enter(ctrl_enter)
);

// === ÈËÎïÒÆ¶¯Ä£¿é ===
    wire [9:0] player_x;
    wire [8:0] player_y;
     // ÈËÎïÒÆ¶¯Ä£¿é£¨º¬×²Ç½ÅÐ¶Ï£©
player_move #(
    .CELL_SIZE(CELL_SIZE),
    .IMAGE_WIDTH(IMAGE_WIDTH),
    .IMAGE_HEIGHT(IMAGE_HEIGHT),
    .INIT_X(`PLAYER_INIT_X),
    .INIT_Y(`PLAYER_INIT_Y)
) player_ctrl (
    .clk(clk_25MHz),
    .rst_n(rst_n),
    .btn_udlr({ctrl_up, ctrl_down, ctrl_left, ctrl_right}),
    .player_x(player_x),
    .player_y(player_y)

);

    wire is_player_pixel = 
        (screen_col_addr >= player_x + 3) && (screen_col_addr < player_x + 3 + CELL_SIZE) &&
        (screen_row_addr >= player_y) && (screen_row_addr < player_y + CELL_SIZE);

       // === ¶¹×Ó RAM ===
    wire [5:0] grid_x = screen_col_addr / CELL_SIZE;
    wire [5:0] grid_y = screen_row_addr / CELL_SIZE;
    wire [5:0] player_cell_x = player_x / CELL_SIZE;
    wire [5:0] player_cell_y = player_y / CELL_SIZE;

    // ÒýÈëÑÓ³ÙÒ»ÅÄµÄÈËÎï¸ñ×Ó×ø±ê
    reg [5:0] player_cell_x_r, player_cell_y_r;
    always @(posedge clk_25MHz) begin
        player_cell_x_r <= player_cell_x;
        player_cell_y_r <= player_cell_y;
    end

    // RAM µØÖ·£ºA¿ÚÓÃÓÚÏÔÊ¾£¬B¿ÚÓÃÓÚ¼ì²âºÍÐ´Èë
    wire [18:0] bean_display_addr = grid_y * 64 + grid_x;
    wire [18:0] bean_eat_addr     = player_cell_y_r * 64 + player_cell_x_r;

    wire bean_display_data;
    wire bean_present;

    reg we, en;


 // === ³Ô¶¹ FSM£¨¸Ä½ø°æ£º´òÅÄÐ´Èë£© ===
reg bean_present_d1;  // ´òÒ»ÅÄÑÓ³Ù
reg [1:0] eat_state;
localparam IDLE  = 2'd0,
           WRITE = 2'd1,
           WAIT  = 2'd2;

// ÐÞ¸ÄºóµÄ³Ô¶¹ FSM
always @(posedge clk_25MHz or negedge rst_n) begin
    if (!rst_n) begin
        eat_state <= IDLE;
        we <= 0;
        en <= 1;  // ±£³ÖÊ¹ÄÜÒ»Ö±ÓÐÐ§
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

// ¸øen_b±£³Ö1£¬±£Ö¤¶ÁÐ´¶Ë¿Ú×ÜÊÇÓÐÐ§
reg en_b_reg = 1;
always @(posedge clk_25MHz or negedge rst_n) begin
    if (!rst_n)
        en_b_reg <= 1'b1;
    else
        en_b_reg <= 1'b1;
end

// RAMÄ£¿éµ÷ÓÃÊ±ÓÃen_b_regÌæ´úen_b
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


    // === ¶¹×ÓÏñËØÅÐ¶Ï ===
    wire is_bean_pixel = 
        (bean_display_data == 1'b1) &&
        (screen_col_addr >= grid_x * CELL_SIZE) && 
        (screen_col_addr < (grid_x + 1) * CELL_SIZE) &&
        (screen_row_addr >= grid_y * CELL_SIZE) &&
        (screen_row_addr < (grid_y + 1) * CELL_SIZE);
// Ìí¼Ó¼Æ·ÖºÍ³É¹¦ÐÅºÅ
reg [2:0] score;      // 3Î»×ã¹»´æ0~5
reg success;

always @(posedge clk_25MHz or negedge rst_n) begin
    if (!rst_n) begin
        score <= 3'd0;
        success <= 1'b0;
    end else begin
        // Ö»ÒªÃ»³É¹¦ÇÒ³Ôµô¶¹×Ó¾Í+1·Ö
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
    .clka(clk_25MHz),  // Ê¼ÖÕÊ¹ÄÜ
    .addra(success_addr),
    .douta(success_pixel_rgb)
); 

// Éú³Ésuccess_addr


   
always @(posedge clk_25MHz or negedge rst_n)
begin
    if(!rst_n)
        pixel_rgb <= 12'b0;  // ¸´Î»Ê±Êä³öºÚÉ«
         else if (success) 
        // ³É¹¦»­ÃæÓÅÏÈÏÔÊ¾
        pixel_rgb <= success_pixel_rgb; 
      else if (is_player_pixel)
        pixel_rgb <= 12'h00F;  // À¶É«ÈËÎï
else if (is_bean_pixel)
        pixel_rgb <= 12'hFF0;  // »ÆÉ«¶¹×Ó£¬ÌîÂúÕû¸ñ

    else if(screen_col_addr >= 0 && screen_col_addr <= 639 && 
            screen_row_addr >= 0 && screen_row_addr <= 479)
        pixel_rgb <= rom_data_out[11:0];  // µØÍ¼Êý¾Ý
    else
        pixel_rgb <= 12'b0;  // ºÚÉ«£¨ÏûÒþ£©

end



endmodule
