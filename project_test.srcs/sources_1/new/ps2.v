module ps2_keyboard(
    input wire clk,           // ϵͳʱ��
    input wire rst_n,         // �͵�ƽ��λ
    input wire ps2_clk,       // PS2ʱ���ź�
    input wire ps2_data,      // PS2�����ź�
    output reg key_up,        // �ϼ�����
    output reg key_down,      // �¼�����
    output reg key_left,      // �������
    output reg key_right,     // �Ҽ�����
    output reg key_enter      // Enter������
);

    // PS2����ɨ����
    parameter UP_CODE     = 8'h75;  // ��
    parameter DOWN_CODE   = 8'h72;  // ��
    parameter LEFT_CODE   = 8'h6B;  // ��
    parameter RIGHT_CODE  = 8'h74;  // ��
    parameter ENTER_CODE  = 8'h5A;  // Enter
    parameter EXTEND      = 8'hE0;  // ��չǰ׺
    parameter BREAK       = 8'hF0;  // ����ǰ׺

    // ����״̬��
    parameter IDLE        = 2'd0;
    parameter DATA        = 2'd1;
    parameter PARITY      = 2'd2;
    parameter STOP        = 2'd3;

    reg [1:0] state;
    reg [3:0] count;
    reg [7:0] data;
    reg is_extend;
    reg is_break;
    reg [19:0] timeout_cnt;

    // �˲���ͬ��
    reg [7:0] ps2_clk_filter;
    reg [7:0] ps2_data_filter;
    reg ps2_clk_sync;
    reg ps2_data_sync;
    reg ps2_clk_prev;

    wire timeout = (timeout_cnt == 20'hFFFFF);  // ��ʱ
    wire ps2_clk_negedge = ps2_clk_prev & ~ps2_clk_sync;

    // ͬ�� + ȥ����
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ps2_clk_filter <= 8'hFF;
            ps2_data_filter <= 8'hFF;
            ps2_clk_sync <= 1'b1;
            ps2_data_sync <= 1'b1;
            ps2_clk_prev <= 1'b1;
        end else begin
            ps2_clk_filter <= {ps2_clk_filter[6:0], ps2_clk};
            ps2_data_filter <= {ps2_data_filter[6:0], ps2_data};

            if (ps2_clk_filter == 8'h00) ps2_clk_sync <= 1'b0;
            else if (ps2_clk_filter == 8'hFF) ps2_clk_sync <= 1'b1;

            if (ps2_data_filter == 8'h00) ps2_data_sync <= 1'b0;
            else if (ps2_data_filter == 8'hFF) ps2_data_sync <= 1'b1;

            ps2_clk_prev <= ps2_clk_sync;
        end
    end

    // ��״̬��
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            count <= 4'd0;
            data <= 8'd0;
            is_extend <= 1'b0;
            is_break <= 1'b0;
            timeout_cnt <= 20'd0;
            key_up <= 1'b0;
            key_down <= 1'b0;
            key_left <= 1'b0;
            key_right <= 1'b0;
            key_enter <= 1'b0;
        end else begin
            // ��ʱ����
            if (state != IDLE) begin
                if (ps2_clk_negedge)
                    timeout_cnt <= 20'd0;
                else
                    timeout_cnt <= timeout_cnt + 1'b1;
            end

            if (timeout && state != IDLE) begin
                state <= IDLE;
                count <= 4'd0;
                timeout_cnt <= 20'd0;
                is_extend <= 1'b0;
                is_break <= 1'b0;
            end else if (ps2_clk_negedge) begin
                case (state)
                    IDLE: begin
                        if (ps2_data_sync == 1'b0) begin
                            state <= DATA;
                            count <= 4'd0;
                            data <= 8'd0;
                        end
                    end

                    DATA: begin
                        data[count] <= ps2_data_sync;
                        count <= count + 1'b1;
                        if (count == 4'd7)
                            state <= PARITY;
                    end

                    PARITY: begin
                        state <= STOP;
                    end

                    STOP: begin
                        if (ps2_data_sync == 1'b1) begin
                            state <= IDLE;
                            case (data)
                                EXTEND: is_extend <= 1'b1;
                                BREAK:  is_break  <= 1'b1;
                                default: begin
                                    if (is_extend) begin
                                        if (is_break) begin
                                            case (data)
                                                UP_CODE:    key_up    <= 1'b0;
                                                DOWN_CODE:  key_down  <= 1'b0;
                                                LEFT_CODE:  key_left  <= 1'b0;
                                                RIGHT_CODE: key_right <= 1'b0;
                                            endcase
                                            is_extend <= 1'b0;
                                            is_break  <= 1'b0;
                                        end else begin
                                            case (data)
                                                UP_CODE:    key_up    <= 1'b1;
                                                DOWN_CODE:  key_down  <= 1'b1;
                                                LEFT_CODE:  key_left  <= 1'b1;
                                                RIGHT_CODE: key_right <= 1'b1;
                                            endcase
                                        end
                                    end else begin
                                        if (is_break) begin
                                            case (data)
                                                ENTER_CODE: key_enter <= 1'b0;
                                            endcase
                                            is_break <= 1'b0;
                                        end else begin
                                            case (data)
                                                ENTER_CODE: key_enter <= 1'b1;
                                            endcase
                                        end
                                    end
                                end
                            endcase
                        end else begin
                            state <= IDLE;  // ֹͣλ����
                        end
                    end
                endcase
            end
        end
    end

endmodule
