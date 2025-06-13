module top (
    input wire clk,         // 50MHz
    input wire clrn,
    input wire [3:0] btn,   // ¿ØÖÆ·½Ïò
    output wire [3:0] r, g, b,
    output wire hs, vs
);
    wire clk_25MHz;
    clk_wiz_0 clk_gen (
        .clk_in1(clk),
        .clk_out1(clk_25MHz)
    );
    wire [8:0] row;
    wire [9:0] col;
    wire [11:0] d_in;

    wire [9:0] pac_x;
    wire [8:0] pac_y;

    wire [18:0] addr = row * 640 + col;
    wire [11:0] map_pixel;

    pacman_ctrl u_ctrl(.clk(clk_25MHz), .reset(!clrn), .dir(btn), .pac_x(pac_x), .pac_y(pac_y));
    map_rom u_rom(.clk(clk_25MHz), .addr(addr), .pixel_data(map_pixel));
    renderer u_rend(.clk(clk_25MHz), .row(row), .col(col), .pac_x(pac_x), .pac_y(pac_y),
                    .map_pixel(map_pixel), .rgb(d_in));

    VGA vga_inst(.vga_clk(clk_25MHz), .clrn(clrn), .d_in(d_in), .row_addr(row),
                 .col_addr(col), .rdn(), .r(r), .g(g), .b(b), .hs(hs), .vs(vs));
endmodule
