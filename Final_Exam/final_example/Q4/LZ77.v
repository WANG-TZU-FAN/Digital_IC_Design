
module LZ77(clk,reset,chardata,valid,encode,busy,offset,match_len,char_nxt);
input 		clk;
input 		reset;
output reg 	valid;
output reg 	encode;
output reg 	busy;
output reg [7:0] char_nxt;

inout	[3:0] 	offset; 
inout	[2:0] 	match_len;
inout 	[7:0] 	chardata;

reg		[2:0]	current_state, next_state;
reg		[11:0]	counter;
reg		[3:0]	search_index;
reg		[2:0]	lookahead_index;
reg		[3:0]	str_buffer		[2047:0];
reg		[3:0]	search_buffer	[8:0];

wire			equal[7:0];
wire	[11:0]	current_encode_len;
wire	[2:0]	curr_lookahead_index;
wire	[3:0]	match_char [6:0];


parameter [2:0] IN=3'b000, ENCODE=3'b001, ENCODE_OUT=3'b010, SHIFT_ENCODE=3'b011, DECODE_OUT=3'b100;

reg 	[3:0] 	offset_reg;
reg 	[2:0] 	match_len_reg;
reg 	[7:0]	chardata_reg;
reg 			chardata_flag;

wire	[3:0] 	offset;
wire	[2:0] 	match_len;
wire	[7:0]	chardata;

assign	offset = (encode) ? offset_reg : 4'hz;
assign	match_len = (encode) ? match_len_reg : 3'hz;
assign	chardata = (chardata_flag) ? chardata_reg : 8'hzz;


integer i;

assign	match_char[0] = search_buffer[search_index];
assign	match_char[1] = (search_index >= 1) ? search_buffer[search_index-1] : str_buffer[search_index];
assign	match_char[2] = (search_index >= 2) ? search_buffer[search_index-2] : str_buffer[1-search_index];
assign	match_char[3] = (search_index >= 3) ? search_buffer[search_index-3] : str_buffer[2-search_index];
assign	match_char[4] = (search_index >= 4) ? search_buffer[search_index-4] : str_buffer[3-search_index];
assign	match_char[5] = (search_index >= 5) ? search_buffer[search_index-5] : str_buffer[4-search_index];
assign	match_char[6] = (search_index >= 6) ? search_buffer[search_index-6] : str_buffer[5-search_index];

assign	equal[0] = (search_index <= 8) ? (match_char[0]==str_buffer[0]) ? 1'b1 : 1'b0 : 1'b0;
assign	equal[1] = (search_index <= 8) ? (match_char[1]==str_buffer[1]) ? equal[0] : 1'b0 : 1'b0;
assign	equal[2] = (search_index <= 8) ? (match_char[2]==str_buffer[2]) ? equal[1] : 1'b0 : 1'b0;
assign	equal[3] = (search_index <= 8) ? (match_char[3]==str_buffer[3]) ? equal[2] : 1'b0 : 1'b0;
assign	equal[4] = (search_index <= 8) ? (match_char[4]==str_buffer[4]) ? equal[3] : 1'b0 : 1'b0;
assign	equal[5] = (search_index <= 8) ? (match_char[5]==str_buffer[5]) ? equal[4] : 1'b0 : 1'b0;
assign	equal[6] = (search_index <= 8) ? (match_char[6]==str_buffer[6]) ? equal[5] : 1'b0 : 1'b0;
assign	equal[7] = 1'b0;

assign	current_encode_len = counter+match_len_reg+1;
assign	curr_lookahead_index = lookahead_index+1;


always @(posedge clk or posedge reset)
begin
	if(reset)
	begin
		current_state <= IN;
		busy <= 0;
		counter <= 0;
		search_index <= 0;
		lookahead_index <= 0;
		valid <= 0;
		encode <= 0;

		offset_reg <= 0;
		match_len_reg <= 0;
		char_nxt <= 0;
		chardata_reg <= 0;
		chardata_flag <= 0;


		search_buffer[0] <= 4'd0;
		search_buffer[1] <= 4'd0;
		search_buffer[2] <= 4'd0;
		search_buffer[3] <= 4'd0;
		search_buffer[4] <= 4'd0;
		search_buffer[5] <= 4'd0;
		search_buffer[6] <= 4'd0;
		search_buffer[7] <= 4'd0;
		search_buffer[8] <= 4'd0;
	end
	else
	begin
		current_state <= next_state;
		
		case(current_state)
			IN:
			begin
				match_len_reg <= 0;
				str_buffer[counter] <= chardata[3:0];
				counter <= (counter == 2047) ? 0 : counter+1;
			end
			ENCODE:
			begin
				valid <= 0;
				if(equal[match_len_reg]==1 && search_index < counter && current_encode_len <= 2048)
				begin
					chardata_reg <= str_buffer[curr_lookahead_index];
					match_len_reg <= match_len_reg+1;
					offset_reg <= search_index;

					lookahead_index <= curr_lookahead_index;
				end
				else
				begin
					search_index <= (search_index==15) ? 0 : search_index-1;
				end
			end
			ENCODE_OUT:
			begin
				encode <= 1;
				chardata_flag <= 1;
				valid <= 1;
				busy <= 1;
				// offset <= offset;
				// match_len <= match_len;
				chardata_reg <= (current_encode_len==2049) ? 8'h24 : (match_len_reg==0) ? str_buffer[0] : chardata_reg;
				counter <= current_encode_len;
			end
			SHIFT_ENCODE:
			begin
				
				counter <= (counter==2049) ? 0 : counter;
				char_nxt <= 0;
				chardata_flag <= (counter==2049) ? 0 : chardata_flag;
				offset_reg <= 0;
				valid <= 0;
				match_len_reg <= 0;
				search_index <= 8;
				lookahead_index <= (lookahead_index==0 || counter==2049) ? 0 : lookahead_index-1;

				search_buffer[8] <= search_buffer[7];
				search_buffer[7] <= search_buffer[6];
				search_buffer[6] <= search_buffer[5];
				search_buffer[5] <= search_buffer[4];
				search_buffer[4] <= search_buffer[3];
				search_buffer[3] <= search_buffer[2];
				search_buffer[2] <= search_buffer[1];
				search_buffer[1] <= search_buffer[0];
				search_buffer[0] <= str_buffer[0];

				for (i=0; i<2047; i=i+1) begin
					str_buffer[i] <= str_buffer[i+1];
				end
			end
			DECODE_OUT:
			begin
				encode <= 0;
				char_nxt <= (match_len_reg == match_len) ? chardata : search_buffer[offset];

				search_buffer[8] <= search_buffer[7];
				search_buffer[7] <= search_buffer[6];
				search_buffer[6] <= search_buffer[5];
				search_buffer[5] <= search_buffer[4];
				search_buffer[4] <= search_buffer[3];
				search_buffer[3] <= search_buffer[2];
				search_buffer[2] <= search_buffer[1];
				search_buffer[1] <= search_buffer[0];

				search_buffer[0] <= (match_len_reg == match_len) ? chardata : search_buffer[offset];
				match_len_reg <= (match_len_reg == match_len) ? 0 : match_len_reg+1;
				busy <= (char_nxt == 8'h24) ? 0 : 1;
				valid <= (char_nxt == 8'h24) ? 0 : 1;
			end
		endcase

	end
end



always @(*)
begin
	case(current_state)
		IN:
		begin
			next_state = (counter == 2047) ? ENCODE : IN;
		end
		ENCODE:
		begin
			next_state = (search_index==15 || match_len_reg==7) ? ENCODE_OUT : ENCODE;
		end
		ENCODE_OUT:
		begin
			next_state = SHIFT_ENCODE;
		end
		SHIFT_ENCODE:
		begin
			next_state = (counter==2049) ? DECODE_OUT : (lookahead_index==0) ? ENCODE : SHIFT_ENCODE;
		end
		DECODE_OUT:
		begin
			next_state = (char_nxt==8'h24) ? IN : DECODE_OUT;
		end
	endcase
end


endmodule
