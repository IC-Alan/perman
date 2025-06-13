module ps2(
    input clk, rst,
    input ps2_clk, ps2_data,
    output reg up, down, left, right, enter
    );

    // 更新扫描码定义
    localparam Break    = 8'hF0;
    localparam Extend   = 8'hE0;
    localparam Key_W    = 8'h1D; // W 键扫描码
    localparam Key_A    = 8'h1C; // A 键扫描码
    localparam Key_S    = 8'h1B; // S 键扫描码
    localparam Key_D    = 8'h23; // D 键扫描码
    localparam Key_Enter= 8'h5A; // Enter 键扫描码

    // PS/2 时钟同步
    reg [2:0] ps2_clk_sync;
    wire negedge_ps2_clk;
    
    always @(posedge clk or posedge rst) begin
        if (rst) ps2_clk_sync <= 3'b111;
        else ps2_clk_sync <= {ps2_clk_sync[1:0], ps2_clk};
    end
    
    assign negedge_ps2_clk = (ps2_clk_sync[2:1] == 2'b10);

    // 位计数器
    reg [3:0] bit_count;
    
    always @(posedge clk or posedge rst) begin
        if (rst) bit_count <= 0;
        else if (negedge_ps2_clk) begin
            if (bit_count == 10) bit_count <= 0;
            else bit_count <= bit_count + 1;
        end
    end

    // 数据接收
    reg [7:0] shift_reg;
    
    always @(posedge clk or posedge rst) begin
        if (rst) shift_reg <= 0;
        else if (negedge_ps2_clk && bit_count >= 1 && bit_count <= 8)
            shift_reg <= {ps2_data, shift_reg[7:1]};
    end

    // 状态和解码逻辑
    reg is_break, is_extend;
    reg data_ready;
    reg [9:0] current_code;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            is_break <= 0;
            is_extend <= 0;
            data_ready <= 0;
            current_code <= 0;
        end 
        else if (negedge_ps2_clk && bit_count == 10) begin
            data_ready <= 0;
            
            case (shift_reg)
                Break: begin
                    is_break <= 1;
                    is_extend <= 0;
                end
                Extend: begin
                    is_extend <= 1;
                    is_break <= 0;
                end
                default: begin
                    current_code <= {is_extend, is_break, shift_reg};
                    data_ready <= 1;
                    is_break <= 0;
                    is_extend <= 0;
                end
            endcase
        end
    end

    // 按键输出逻辑 (修复版)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            up <= 0;
            down <= 0;
            left <= 0;
            right <= 0;
            enter <= 0;
        end
        else if (data_ready) begin
            case (current_code)
                // W 键 (按下)
                {1'b0, 1'b0, Key_W}: up <= 1;
                // W 键 (释放)
                {1'b0, 1'b1, Key_W}: up <= 0;
                
                // S 键 (按下)
                {1'b0, 1'b0, Key_S}: down <= 1;
                // S 键 (释放)
                {1'b0, 1'b1, Key_S}: down <= 0;
                
                // A 键 (按下)
                {1'b0, 1'b0, Key_A}: left <= 1;
                // A 键 (释放)
                {1'b0, 1'b1, Key_A}: left <= 0;
                
                // D 键 (按下)
                {1'b0, 1'b0, Key_D}: right <= 1;
                // D 键 (释放)
                {1'b0, 1'b1, Key_D}: right <= 0;
                
                // Enter 键 (按下)
                {1'b0, 1'b0, Key_Enter}: enter <= 1;
                // Enter 键 (释放)
                {1'b0, 1'b1, Key_Enter}: enter <= 0;
                
                default: ; // 其他键不做处理
            endcase
        end
    end

endmodule
