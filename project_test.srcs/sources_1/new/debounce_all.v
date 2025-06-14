module debounce_all(
    input clk,
    input rst_n,
    input [3:0] btn_in,       // ԭʼ��������
    output [3:0] btn_out      // ȥ����������
);

    debounce db0(.clk(clk), .rst_n(rst_n), .key_in(btn_in[0]), .key_out(btn_out[0]));
    debounce db1(.clk(clk), .rst_n(rst_n), .key_in(btn_in[1]), .key_out(btn_out[1]));
    debounce db2(.clk(clk), .rst_n(rst_n), .key_in(btn_in[2]), .key_out(btn_out[2]));
    debounce db3(.clk(clk), .rst_n(rst_n), .key_in(btn_in[3]), .key_out(btn_out[3]));

endmodule



module debounce #(
    parameter CNT_MAX = 250_000     // 10ms for 25MHz clock
)(
    input clk,          // ϵͳʱ��
    input rst_n,        // ��λ���͵�ƽ��
    input key_in,       // ���밴����ԭʼ�źţ����ܶ�����
    output reg key_out  // ȥ�������������ȶ���/�͵�ƽ��
);

    reg [17:0] cnt;
    reg key_sync0, key_sync1;
    reg key_in_d;

    // ͬ����ϵͳʱ����
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_sync0 <= 1'b1;
            key_sync1 <= 1'b1;
        end else begin
            key_sync0 <= key_in;
            key_sync1 <= key_sync0;
        end
    end

    // ����ƽ�Ƿ�仯
    wire key_change = (key_sync1 != key_in_d);

    // ȥ����������
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 0;
            key_in_d <= 1'b1;
            key_out <= 1'b1;
        end else if (key_change) begin
            cnt <= 0;
            key_in_d <= key_sync1;
        end else if (cnt < CNT_MAX) begin
            cnt <= cnt + 1;
        end else begin
            key_out <= key_sync1;  // ֻ���ȶ���Ÿ������
        end
    end

endmodule
