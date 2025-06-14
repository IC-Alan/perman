module monster_move #(
    parameter CELL_SIZE = 10,
    parameter IMAGE_WIDTH = 640,
    parameter IMAGE_HEIGHT = 480,
    parameter INIT_X = 10'd0,
    parameter INIT_Y = 9'd0,
    parameter MOVE_INTERVAL = 24'd8_000_000  // �����ƶ��ٶ�
)(
    input clk,               // 25MHz VGA ʱ��
    input rst_n,             // �͵�ƽ��λ

    input [3:0] btn_udlr,   // �����ӿڣ�Ϊ��map_checker���ݣ����Բ�ʹ��

    output reg [9:0] monster_x,  // ���ص�λ��X ����
    output reg [8:0] monster_y   // ���ص�λ��Y ����
);

  // === LFSR: 16λ��ǿ�汾�����ڸ��� ===
    reg [15:0] lfsr = 16'hACE1;
    wire feedback = lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10];
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            lfsr <= 16'hACE1;
        else
            lfsr <= {lfsr[14:0], feedback};
    end

    wire [1:0] rand2 = lfsr[1:0];

    // �������ӳ���4λ����֮һ��ֻȡ��2λ����ӳ���btn_edge��ʽ��
    // btn_edge ��ʽ: 4bit��һbit��Ч����Ӧ�ĸ�����
   reg [3:0] move_dir;
    always @(*) begin
        case (rand2)
            2'd0: move_dir = 4'b0001; // up
            2'd1: move_dir = 4'b0010; // down
            2'd2: move_dir = 4'b0100; // left
            2'd3: move_dir = 4'b1000; // right
            default: move_dir = 4'b0000;
        endcase
    end

  // === ��ʱ�������ƶ���� ===
    reg [23:0] move_timer;
    wire move_trigger = (move_timer == 0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            move_timer <= MOVE_INTERVAL;
        else if (move_timer == 0)
            move_timer <= MOVE_INTERVAL;
        else
            move_timer <= move_timer - 1;
    end


    // ����״̬���ṹ�������߼�

    reg [1:0] state;
    localparam WAIT_DIR = 2'd0, WAIT_CHECK = 2'd1;

    reg move_req;
    wire [9:0] next_x;
    wire [8:0] next_y;
    wire allow_move;
    wire move_valid;

    // map_checkerʵ������player_moveһ���ӿ�
    map_checker checker (
        .clk(clk),
        .rst_n(rst_n),

        .btn(move_dir),
        .player_x(monster_x),
        .player_y(monster_y),

        .next_x(next_x),
        .next_y(next_y),

        .allow_move(allow_move),
        .move_req(move_req),
        .move_valid(move_valid)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            monster_x <= INIT_X;
            monster_y <= INIT_Y;
            state <= WAIT_DIR;
            move_req <= 0;
        end else begin
            case (state)
                WAIT_DIR: begin
                    move_req <= 0;
                    if (move_trigger) begin  // ��ʱ�����ƶ�����
                        move_req <= 1;
                        state <= WAIT_CHECK;
                    end
                end
                WAIT_CHECK: begin
                    if (move_valid) begin
                        if (allow_move) begin
                            monster_x <= next_x;
                            monster_y <= next_y;
                        end
                        move_req <= 0;
                        state <= WAIT_DIR;
                    end
                end
            endcase
        end
    end

endmodule
