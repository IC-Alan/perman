module ps2(
	input wire clk,
	input wire rst,
	input wire ps2_clk,
	input wire ps2_data,
	output reg up,
	output reg left,
	output reg right,
	output reg down,
	output reg enter
	);
	
	localparam Break	= 8'hF0;
	localparam Extend	= 8'hE0;
	localparam Key_Up	= 8'h75;
	localparam Key_Down	= 8'h72;
	localparam Key_Left = 8'h6B;
	localparam Key_Right= 8'h74;
	localparam Key_Enter= 8'h5A;

	reg [1:0] ps2_clk_sync;
	wire negedge_ps2_clk;
	assign negedge_ps2_clk = (ps2_clk_sync == 2'b10);

	// ps2 state update
	always @(posedge clk or posedge rst) begin
		if (rst) begin
			ps2_clk_sync <= 2'b11;
		end
		else begin
			ps2_clk_sync <= {ps2_clk_sync[0], ps2_clk};
		end
	end

	reg [3:0] bit_count;
	reg [7:0] shift_reg;
	wire is_done;

	assign is_done = negedge_ps2_clk && (bit_count == 4'd10);

	// Serial 2 Parallel
	always @(posedge clk or posedge rst) begin
		if (rst) begin
			bit_count <= 4'd0;
			shift_reg <= 8'h00;
		end
		else if (negedge_ps2_clk) begin
			case (bit_count)
				4'd0: begin
					if (~ps2_data) begin
						bit_count <= bit_count + 1;
					end
				end
				4'd1, 4'd2, 4'd3, 4'd4,
				4'd5, 4'd6, 4'd7, 4'd8: begin
					shift_reg <= {ps2_data, shitf_reg[7:1]};
					bit_count <= bit_count + 1;
				end
				default: begin
					bit_count <= 4'd0;
				end
			endcase
		end
	end
	
	// Decode
	reg is_extend;
	reg is_break;

	always @(posedge clk or posedge rst) begin
		if (rst) begin
			is_extend	<= 1'b0;
			is_break	<= 1'b0;
			up			<= 1'b0;
			down		<= 1'b0;
			left		<= 1'b0;
			right		<= 1'b0;
			enter		<= 1'b0;
		end
		else if (is_done) begin
			if (shift_reg == Extend) begin
				is_extend	<= 1'b1;
				is_break	<= 1'b0;
			end
			else if (shift_reg == Break) begin
				is_break	<= 1'b1;
			end
			else begin
				if (is_extend) begin
					case (shift_reg)
						Key_Up:		up		<= !is_break;
						Key_Down:	down	<= !is_break;
						Key_Left:	left	<= !is_break;
						Key_Right:	right	<= !is_break;
						Key_Enter:	enter	<= !is_break;
						default: begin end
					endcase
					is_extend	<= 1'b0;
					is_break	<= 1'b0;
				end
				else begin
					is_break <= 1'b0;
				end
			end
		end
	end
endmodule
