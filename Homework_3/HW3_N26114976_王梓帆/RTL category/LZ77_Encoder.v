module LZ77_Encoder(clk,reset,chardata,valid,encode,finish,offset,match_len,char_nxt);


input 				clk;
input 				reset;
input 		[7:0] 	chardata;
output  			valid;
output  			encode;
output  			finish;
output 		[3:0] 	offset;
output 		[2:0] 	match_len;
output 	 	[7:0] 	char_nxt;
// valid signal
reg 	  			valid;
// encode signal
reg 	  			encode;
// finish signal
reg 	  			finish;
// encoding result
reg 	 	[3:0] 	offset;
reg 	 	[2:0] 	match_len;
reg 	 	[7:0] 	char_nxt;
// register for states
reg			[1:0]	curr_state, next_state;
// 需要 12 bits 才能存到 2050 = 2^11 + 2
// 讀取輸入，也用來判斷讀取的條件
reg			[11:0]	input_count;
// search buffer 對應原本數組的 address
reg			[11:0]	search_buffer_address;
// look ahead buffer 對應原本數組的 address
reg			[11:0]	look_ahead_buffer_address;
// 存取 data 的 memory
reg 		[3:0]	data_mem[2049 : 0];	
// search buffer
reg			[4:0]	search_count;
reg 		[4:0]	search_start;	
reg		    [4:0]	s_lens_max;
reg 		[4:0]	s_start_max;
wire 		[4:0]	search_buffer_len;
// look ahead buffer
reg			[2:0]	look_ahead_count;
// search ahead buffer 的長度
assign search_buffer_len = look_ahead_buffer_address - search_buffer_address;
// state 的定義
parameter 	[1:0] datain_state = 2'b00;
parameter 	[1:0] encode_state = 2'b01;
parameter 	[1:0] result_state = 2'b10;
parameter 	[1:0] finish_state = 2'b11;

// State register
always @(posedge clk or posedge reset) begin
    if (reset)
		curr_state <= datain_state;
    else 
		curr_state <= next_state;
end

// Next state logic
always @(*) begin
	case(curr_state)
		datain_state: begin
			if(input_count == 2050) 
				next_state = encode_state;
			else
				next_state = datain_state;
		end
		encode_state: begin
			if(search_start == 9 || search_buffer_address + search_start == look_ahead_buffer_address) 
				next_state = result_state;
			else
				next_state = encode_state;
		end
		result_state: 
			next_state = finish_state;
		finish_state: 
			next_state = encode_state;
	endcase 
end

// Output logic
always@(posedge clk) begin
	if(reset) begin
		// state signals
		encode <= 1;
		finish <= 0;
		valid <= 0;
		// encoding result
		offset <= 0;
		match_len <= 0; 
		char_nxt <= 0;
		// input counter
		input_count <= 0;
		// buffer address
		search_buffer_address <= 0;
		look_ahead_buffer_address <= 0;
		search_count <= 0;
		search_start <= 0;
		s_lens_max <= 0;
		s_start_max <= 0;	
		look_ahead_count <= 0;
	end
	else begin
		case(curr_state)
			datain_state: begin
				// Input data when input_count is not more than 32*32*2 + 2*1(8'h24) = 2050		
				input_count <= input_count + 1;
				data_mem[input_count] <= chardata[3:0];
			end
			encode_state: begin
				if(data_mem[search_buffer_address + search_count] == data_mem[look_ahead_buffer_address + look_ahead_count]) begin
					look_ahead_count <= look_ahead_count + 1;
					// Look ahead buffer is 8 characters long
					// When look ahead buffer attached to 8 characters long, start to run in the search buffer
					if(look_ahead_count == 7) begin
						search_start <= search_start + 1;
						search_count <= search_start + 1;
					end
					else search_count <= search_count + 1;
				end
				else begin
					look_ahead_count <= 0;
					search_start <= search_start + 1;
					search_count <= search_start + 1;
				end
				if(s_lens_max < search_count - search_start && look_ahead_buffer_address < 2048) begin
					s_lens_max <= search_count - search_start;
					s_start_max <= search_start;
				end
			end
			result_state: begin
				// valid on
				valid <= 1;
				// result of match_len
				match_len <= s_lens_max;
				look_ahead_buffer_address <= look_ahead_buffer_address + s_lens_max + 1;
				// result of offset
				if(search_buffer_len != 0 && s_lens_max != 0)
					offset <= search_buffer_len - s_start_max - 1;
				else 
					offset <= 0;
				// result of char_nxt
				if(look_ahead_buffer_address + s_lens_max + 1 < 2049) 
					char_nxt <= {4'h0, data_mem[look_ahead_buffer_address + s_lens_max]};
				else 
					char_nxt <= 36;
			end
			finish_state: begin
				// valid off
				valid <= 0;
				offset <= 'hx;
				match_len <= 'hx;
				char_nxt <= 'hx;
				search_count <= 0;
				search_start <= 0;
				s_lens_max <= 0;
				s_start_max <= 0;
				look_ahead_count <= 0;
				// 在 look_ahead_buffer_address 比 9 小之前，每次都要回到第一項作比較
				if(look_ahead_buffer_address < 9) begin
					search_buffer_address <= 0;
				end
				else begin
					search_buffer_address <= look_ahead_buffer_address - 9;
				end
				if(look_ahead_buffer_address >= 2049) begin
					finish <= 1;
				end
			end
		endcase
	end 
end

// always@(posedge valid) begin
// 	// result of match_len
// 	match_len <= s_lens_max;
// 	look_ahead_buffer_address <= look_ahead_buffer_address + s_lens_max + 1;
// 	// result of offset
// 	if(search_buffer_len != 0 && s_lens_max != 0)
// 		offset <= search_buffer_len - s_start_max - 1;
// 	else 
// 		offset <= 0;
// 	// result of char_nxt
// 	if(look_ahead_buffer_address + s_lens_max + 1 < 2049) 
// 		char_nxt <= {4'h0,data_mem[look_ahead_buffer_address + s_lens_max]};
// 	else 
// 		char_nxt <= 36;
// end

// always@(negedge valid) begin
// 	offset <= 'hx;
// 	match_len <= 'hx;
// 	char_nxt <= 'hx;
// 	search_count <= 0;
// 	search_start <= 0;
// 	s_lens_max <= 0;
// 	s_start_max <= 0;
// 	look_ahead_count <= 0;
// 	if(look_ahead_buffer_address < 9) begin
// 		search_buffer_address <= 0;
// 	end
// 	else begin
// 		search_buffer_address <= look_ahead_buffer_address - 9;
// 	end
// 	if(look_ahead_buffer_address >= 2049) begin
// 		finish <= 1;
// 	end
// end


endmodule