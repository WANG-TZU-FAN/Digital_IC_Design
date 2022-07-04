`timescale 1ns/10ps

module ELA(clk, rst, ready, in_data, data_rd, req, wen, addr, data_wr, done);

	input				clk;
	input				rst;
	input				ready;
	input		[7:0]	in_data;
	input		[7:0]	data_rd;
	output				req;
	output				wen;
	output		[12:0]	addr;
	output		[7:0]	data_wr;
	output				done;

	reg					req;
	reg					wen;
	reg			[12:0]	addr;
	reg			[7:0]	data_wr;
	reg					done;

	// Register for States
	reg 		[2:0] 	next_state, curr_state;
	// Two Neighboring Points
	reg 				first;
	// Position of Pixels
	reg [12:0] 			pixel;
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
	reg 		[8:0] 	D1_abs, D2_abs, D3_abs;
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
			if(ready)
				next_state = datain_state;
			else
				next_state = write_enable;
			datain_state: 
				// Final Element at 128*63 - 1 = 8063
				if (addr == 8063) 
					next_state = check_pixels;
				else
					next_state = datain_state;
			check_pixels: begin 
				if(pixel[6:0] == 0) 
					next_state <= lft_boundary;
				// Don't update c, f when facing right boundary(improving time consuming)
				else if(pixel[6:0] == 127) 
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
				// When facing 128*62 - 1, Finish the ELA
				if (pixel == 7935) 
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
			req <= 0;
			addr <= 0;
			first <= 0;
			done <= 0;
			pixel <= 0;
			D1 <= 0;
			D2 <= 0;
			D3 <= 0;
			a <= 0;
			b <= 0;
			c <= 0;
			d <= 0;
			e <= 0;
			f <= 0;
		end
		else begin
			case(curr_state) 
			write_enable: begin
				req <= 1;
				wen <= 1;
			end
			datain_state: begin
				addr <= pixel;
				if(addr == 8063) begin
					wen <= 0;
					pixel <= 128;
				end
				else begin
					if(pixel[6:0] == 127) begin
						pixel[12:7] <= pixel[12:7] + 2;
					end
					pixel[6:0] <= pixel[6:0] + 1;
					data_wr <= in_data;
				end
			end
			check_pixels: begin
					wen <= 0;
					req <= 0;
					if(pixel[6:0] == 0) begin
						a <= 0;
						d <= 0;
						addr <= pixel - 128;
					end
					else if(pixel[6:0] == 127) begin
					end
					else begin
						c <= 0;
						f <= 0;
						addr <= pixel - 127;
					end 
					first <= 1;
				end
			lft_boundary: begin
					first <= ~first;
					if(first) begin
						b <= data_rd;
						addr <= addr + 256;
					end
					else begin
						e <= data_rd;
						addr <= addr - 255;
					end
				end
			not_boundary: begin
					first <= ~first;
					if(first) begin
						c <= data_rd;
						addr <= addr + 256;
					end
					else begin
						f <= data_rd;
						addr <= addr - 255;
					end
				end
			Dx_calculate: begin
					D1 <= {1'b0,a} - {1'b0,f};
					D2 <= {1'b0,b} - {1'b0,e};
					D3 <= {1'b0,c} - {1'b0,d};
				end
			
			pixels_shift: begin
					wen <= 1;
					addr <= pixel;
					// The left and right boundary interpolation is fixed to (b+e)/2
					if(pixel[6:0] == 0 || pixel[6:0] == 127) 
						data_wr <= ({1'b0,b} + {1'b0,e})>> 1;
					else 
						data_wr <= min ;
					// change the row when facing end
					if(pixel[6:0] == 127) 
						pixel <= pixel + 129;
					else 
						pixel <= pixel + 1;
					// Rolling the value
					a <= b;
					b <= c;
					d <= e;
					e <= f;
				end
			image_finish: begin
				done <= 1;
			end
			endcase
		end
	end

	always @(*) begin
		if(D1[8])
			D1_abs <= ~D1 + 1'b1;
		else
			D1_abs <= D1;
		if(D2[8])
			D2_abs <= ~D2 + 1'b1;
		else
			D2_abs <= D2;
		if(D3[8])
			D3_abs <= ~D3 + 1'b1;
		else
			D3_abs <= D3;
	end

	always @(*) begin
		if(D2_abs <= D1_abs && D2_abs <= D3_abs) begin
			if(((a + b + c) / 3) - b < 3 || ((a + b + c) / 3) - b > -3) begin
				if(((a + b + c) / 3) - b < 2 || ((a + b + c) / 3) - b > -2)
					min = {1'b0, b * 5/8} + {1'b0, e * 3/8};
				else
					min = {1'b0, b * 17/32} + {1'b0, e * 15/32};
			end
			else if(((d + e + f) / 3) - e < 3 || ((d + e + f) / 3) - e > -3)
				if(((d + e + f) / 3) - e < 2 || ((d + e + f) / 3) - e > -2)
					min = {1'b0, b * 3/8} + {1'b0, e * 5/8};
				else
					min = {1'b0, b * 15/32} + {1'b0, e * 17/32};
			else
				min = ({1'b0, b} + {1'b0, e}) >> 1;	
		end
		else if(D1_abs <= D2_abs && D1_abs <= D3_abs) begin
			if(((a + b + c) / 3) - a < 3 || ((a + b + c) / 3) - a > -3)
				if(((a + b + c) / 3) - a < 2 || ((a + b + c) / 3) - a > -2)
					min = {1'b0, a * 5/8} + {1'b0, f * 3/8};
				else
					min = {1'b0, a * 17/32} + {1'b0, f *15/32};
			else if(((d + e + f) / 3) - f < 3 || ((d + e + f) / 3) - f > -3)
				if(((d + e + f) / 3) - f < 2 || ((d + e + f) / 3) - f > -2)
					min = {1'b0, a * 3/8} + {1'b0, f * 5/8};
				else
					min = {1'b0, a * 15/32} + {1'b0, f * 17/32};
			else
				// min = ({1'b0, a} + {1'b0, f}) >> 1;
				min = ({1'b0, b} + {1'b0, e}) >> 1;
		end 
		else begin
			if(((a + b + c) / 3) - c < 3 || ((a + b + c) / 3) - c > -3)
				if(((a + b + c) / 3) - c < 2 || ((a + b + c) / 3) - c > -2)
					min = {1'b0, c * 5/8} + {1'b0, d * 3/8};
				else
					min = {1'b0, c * 17/32} + {1'b0, d * 15/32};
			else if(((d + e + f) / 3) - d < 3 || ((d + e + f) / 3) - d > -3)
				if(((d + e + f) / 3) - d < 2 || ((d + e + f) / 3) - d > -2)
					min = {1'b0, c * 3/8} + {1'b0, d * 5/8};
				else
					min = {1'b0, c * 15/32} + {1'b0, d * 17/32};
			else
				min = ({1'b0, b} + {1'b0, e}) >> 1;
				// min = ({1'b0, c} + {1'b0, d}) >> 1;
		end
	end

endmodule