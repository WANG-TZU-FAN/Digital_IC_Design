`timescale 1ns/10ps

module ELA(clk, rst, in_data, data_rd, req, wen, addr, data_wr, done);

	input				clk;
	input				rst;
	input		[7:0]	in_data;
	input		[7:0]	data_rd;
	output				req;
	output				wen;
	output		[9:0]	addr;
	output		[7:0]	data_wr;
	output				done;

	reg					req;
	reg					wen;
	reg			[9:0]	addr;
	reg			[7:0]	data_wr;
	reg					done;
	// Register for States
	reg 		[2:0] 	next_state, curr_state;
	// Two Neighboring Points
	reg 				first;
	// Position of Pixels
	reg 		[9:0] 	pixel;
	// Neighboring Points
	reg 		[7:0]	a;
	reg 		[7:0]	b;
	reg 		[7:0]	c;
	reg 		[7:0]	d;
	reg 		[7:0]	e;
	reg 		[7:0]	f;
	// Minimum Value from D1 to D3
	reg 		[7:0] 	min;
	// D values
	reg 		[8:0] 	D1, D2, D3;
	wire 		[8:0] 	D1_abs, D2_abs, D3_abs;
	// Name of states
	parameter 	[2:0] 	write_enable = 3'b000;
	parameter 	[2:0] 	datain_state = 3'b001;
	parameter 	[2:0] 	check_pixels = 3'b010;
	parameter 	[2:0] 	lft_boundary = 3'b011;
	parameter 	[2:0] 	not_boundary = 3'b100;
	parameter 	[2:0] 	Dx_calculate = 3'b101;
	parameter 	[2:0] 	pixels_shift = 3'b110;
	parameter 	[2:0] 	image_finish = 3'b111;

	// State Register
	always @(posedge clk or posedge rst) begin
		if (rst) 
			curr_state <= write_enable;
		else 
			curr_state <= next_state;
	end

	// Next State Logic
	always @(*) begin
		next_state = curr_state;
		case(curr_state)
			write_enable: 
				next_state = datain_state;
			datain_state: 
				// Final Element at 32*31 - 1 = 991
				if (addr == 991) 
					next_state = check_pixels;
				else
					next_state = datain_state;
			check_pixels: begin 
				if(pixel[4:0] == 0) 
					next_state <= lft_boundary;
				// Don't update c, f when facing right boundary(improving time consuming)
				else if(pixel[4:0] == 31) 
					next_state <= Dx_calculate;
				else 
					next_state <= not_boundary;
			end
			lft_boundary: begin
				if (!first) 
					next_state <= not_boundary;
				else
					next_state <= lft_boundary;
			end
			not_boundary: begin
				if (!first) 
					next_state <= Dx_calculate;
				else
					next_state <= not_boundary;
			end
			Dx_calculate: 
				next_state <= pixels_shift;
			pixels_shift: 
				// When facing 32*30 - 1, Finish the ELA
				if (pixel == 959) 
					next_state <= image_finish;
				else
					next_state <= check_pixels;
			image_finish: 
				next_state <= image_finish;
		endcase 
	end

	// Output Logic + Datapath
	always @(posedge clk) begin
		if(rst) begin
			wen <= 0;
			req <= 0;
			addr <= 0;
			first <= 0;
			done <= 0;
			pixel <= 0;
			a <= 0;
			b <= 0;
			c <= 0;
			d <= 0;
			e <= 0;
			f <= 0;
			D1 <= 0;
			D2 <= 0;
			D3 <= 0;

		end
		else begin
			case(curr_state) 
				write_enable: begin
					wen <= 1;
					req <= 1;
				end
				datain_state: begin // from img to gray
					addr <= pixel;
					if (addr == 991) begin
						wen <= 0;
						pixel <= 32;
					end
					else begin
						if(pixel[4:0] == 31) 
							pixel[9:5] <= pixel[9:5] + 2;
						pixel[4:0] <= pixel[4:0] + 1;
						data_wr <= in_data;
					end
				end
				check_pixels: begin
					wen <= 0;
					req <= 0;
					if(pixel[4:0] == 0) begin
						a <= 0;
						d <= 0;
						addr <= pixel - 32;
					end
					else if(pixel[4:0] == 31) begin
					end
					else begin
						c <= 0;
						f <= 0;
						addr <= pixel - 31;
					end 
					first <= 1;
				end
				lft_boundary: begin
					first <= ~first;
					if(first) begin
						b <= data_rd;
						addr <= addr + 64;
					end
					else begin
						e <= data_rd;
						addr <= addr - 63;
					end
				end
				not_boundary: begin
					first <= ~first;
					if(first) begin
						c <= data_rd;
						addr <= addr + 64;
					end
					else begin
						f <= data_rd;
						addr <= addr - 63;
					end
				end
				Dx_calculate: begin
					D1 <= {1'b0, a} - {1'b0, f};
					D2 <= {1'b0, b} - {1'b0, e};
					D3 <= {1'b0, c} - {1'b0, d};
				end
				pixels_shift: begin
					wen <= 1;
					addr <= pixel;
					// The left and right boundary interpolation is fixed to (b+e)/2
					if(pixel[4:0]==0 || pixel[4:0]==31) 
						data_wr <= ({1'b0,b} + {1'b0,e})>> 1;
					else
						data_wr <= min ;
					// change the row when facing end
					if(pixel[4:0] == 31) 
						pixel <= pixel + 33;
					else 
						pixel <= pixel + 1;
					// Rolling the value
					a <= b;
					b <= c;
					d <= e;
					e <= f;
				end
				image_finish: done <= 1;
			endcase
		end
	end

	// Absolute Value
	assign	D1_abs = D1[8] ? (~D1 + 9'b000000001) : D1;
	assign	D2_abs = D2[8] ? (~D2 + 9'b000000001) : D2;
	assign	D3_abs = D3[8] ? (~D3 + 9'b000000001) : D3;

	always @(*) begin
		// The left and right boundary interpolation is fixed to (b+e)/2
		if(D2_abs <= D1_abs && D2_abs <= D3_abs) begin
			// shift bit for devision
			min = ({1'b0,b} + {1'b0,e}) >> 1;
		end
		else if(D1_abs <= D2_abs && D1_abs <= D3_abs) begin
			min = ({1'b0,a} + {1'b0,f}) >> 1;
		end 
		else begin
			min = ({1'b0,c} + {1'b0,d}) >> 1;
		end
	end

	

endmodule