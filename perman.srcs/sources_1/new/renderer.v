module renderer (
    input wire clk,
    input wire [8:0] row,
    input wire [9:0] col,
    input wire [9:0] pac_x,
    input wire [8:0] pac_y,
    input wire [11:0] map_pixel,
    output reg [11:0] rgb
);
    always @(posedge clk) begin
        // �жϵ�ǰλ���Ƿ���������ʾ����16x16��
        if ((col >= pac_x) && (col < pac_x + 16) &&
            (row >= pac_y) && (row < pac_y + 16)) begin
            rgb <= 12'h00F; // ��ɫ�Զ���
        end else begin
            rgb <= map_pixel;
        end
    end
endmodule
