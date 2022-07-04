module LZ77_Encoder(clk,reset,chardata,valid,encode,finish,offset,match_len,char_nxt);

input 				clk;
input 				reset;
input 		[7:0] 	chardata;
output reg 			valid;
output  			encode;
output reg 			finish;
output reg 	[3:0] 	offset;
output reg 	[2:0] 	match_len;
output reg 	[7:0] 	char_nxt;


reg			[1:0]	current_state, next_state;
/* counter 數到 2049 需要 12 bits */
reg			[11:0]	counter;
/* search_index 最多數到 search_buffer - 1 */
// 這邊要數到 11 - 1，至少要 4 個 bit
reg			[3:0]	search_index;
/* lookahead_index 最多數到 lookahead_buffer - 1 */
// 這邊要數到 5 - 1，至少要 3 個 bit
reg			[2:0]	lookahead_index;
/* 輸入有 2048 個 */
reg			[3:0]	str_buffer	[2047:0];
/* Search Buffer 長度為 11 */
reg			[3:0]	search_buffer	[10:0];
/* equal 的個數 = look-ahead buffer 長度 */
wire				equal	[4:0];
/* current_encode_len 與 counter 長度相同 */
wire		[11:0]	current_encode_len;
/* curr_lookahead_index 最多數到 lookahead_buffer - 1 */
wire		[2:0]	curr_lookahead_index;
/* match_char 的個數 = look-ahead buffer 長度 - 1 */
wire		[3:0]	match_char [3:0];

parameter [1:0] IN = 2'b00, ENCODE = 2'b01, ENCODE_OUT = 2'b10, SHIFT_ENCODE = 2'b11;

integer i;

assign	encode = 1'b1;

// match_char[0] ~ [6] 為待匹配字串
// str_buffer 為 look-ahead buffer 的開頭
// 因為 look-ahead buffer 長度為 8，匹配長度最長為7(匹配 7 個字元 + 1 個 next_char)，equal[7] 默認為 0，
// 若 look-ahead buffer 長度改變，則需增加 match_char 與 equal
// equal[n] 為 1 的條件除了匹配正確外(match_char[n] == str_buffer[n])，equal[n - 1] ~ equal[0] 也必須都為1，
// 同時 search_index 不可超過 search_buffer 長度(search_index <= 8)

/* match_char 的個數 = look-ahead buffer 長度 - 1 */
assign	match_char[0] = search_buffer[search_index];
assign	match_char[1] = (search_index >= 1) ? search_buffer[search_index - 1] : str_buffer[search_index];
assign	match_char[2] = (search_index >= 2) ? search_buffer[search_index - 2] : str_buffer[1 - search_index];
assign	match_char[3] = (search_index >= 3) ? search_buffer[search_index - 3] : str_buffer[2 - search_index];

/* equal 的個數 = look-ahead buffer 長度 */
/* 匹配長度最長為 look-ahead buffer 長度 - 1 */
/* next_char，equal[7] 默認為 0 */
assign	equal[0] = (search_index <= 10) ? ((match_char[0]==str_buffer[0]) ? 1'b1 : 1'b0) : 1'b0;
assign	equal[1] = (search_index <= 10) ? ((match_char[1]==str_buffer[1]) ? equal[0] : 1'b0) : 1'b0;
assign	equal[2] = (search_index <= 10) ? ((match_char[2]==str_buffer[2]) ? equal[1] : 1'b0) : 1'b0;
assign	equal[3] = (search_index <= 10) ? ((match_char[3]==str_buffer[3]) ? equal[2] : 1'b0) : 1'b0;
assign	equal[4] = 1'b0;

assign	current_encode_len = counter + match_len + 1;
assign	curr_lookahead_index = lookahead_index + 1;

always @(posedge clk or posedge reset)
begin
	if(reset)
		current_state <= IN;
	else
		current_state <= next_state;
end

always @(*)
begin
	case(current_state)
		IN:
		begin
			next_state = (counter==2047) ? ENCODE : IN;
		end
		ENCODE:
		begin
			/* 終止條件：Search 由 8 減至溢位，或匹配長度已達到 7 */
			next_state = (search_index==15 || match_len==7) ? ENCODE_OUT : ENCODE;
		end
		ENCODE_OUT:
		begin
			next_state = SHIFT_ENCODE;
		end
		SHIFT_ENCODE:
		begin
			// 移動輪數扣至 0
			next_state = (lookahead_index == 0) ? ENCODE : SHIFT_ENCODE;
		end
		default:
		begin
			next_state = IN;
		end
	endcase
end

always @(posedge clk or posedge reset)
begin
	if(reset)
	begin
		counter <= 12'd0;
		search_index <= 4'd0;
		lookahead_index <= 3'd0;
		valid <= 1'b0;
		finish <= 1'b0;
		offset <= 4'd0;
		match_len <= 3'd0;
		char_nxt <= 8'd0;
		/* Search Buffer 長度為 9 */
		search_buffer[0] <= 4'd0;
		search_buffer[1] <= 4'd0;
		search_buffer[2] <= 4'd0;
		search_buffer[3] <= 4'd0;
		search_buffer[4] <= 4'd0;
		search_buffer[5] <= 4'd0;
		search_buffer[6] <= 4'd0;
		search_buffer[7] <= 4'd0;
		search_buffer[8] <= 4'd0;
		search_buffer[9] <= 4'd0;
		search_buffer[10] <= 4'd0;
	end
	else
	begin
		case(current_state)
			IN:
			begin
				str_buffer[counter] <= chardata[3:0];
				counter <= (counter == 2047) ? 0 : counter+1;
			end
			ENCODE:
			begin
				if(equal[match_len] == 1 && search_index < counter && current_encode_len <= 2048)
				begin
					char_nxt <= str_buffer[curr_lookahead_index];
					match_len <= match_len + 1;
					offset <= search_index;

					lookahead_index <= curr_lookahead_index;
				end
				else
				begin
					search_index <= (search_index == 15) ? 0 : search_index - 1;
				end
			end
			ENCODE_OUT:
			begin
				valid <= 1;
				// offset <= offset;
				// match_len <= match_len;
				char_nxt <= (current_encode_len==2049) ? 8'h24 : (match_len==0) ? str_buffer[0] : char_nxt;
				counter <= current_encode_len;
			end
			SHIFT_ENCODE:
			begin
				finish <= (counter==2049) ? 1 : 0;
				offset <= 0;
				valid <= 0;
				match_len <= 0;
				/* 最左邊有優先匹配權，Search Buffer 的長度是 9，這邊要初始化成 9 - 1 = 8 */
				search_index <= 10;
				// 用來判斷移動幾輪
				lookahead_index <= (lookahead_index == 0) ? 0 : lookahead_index - 1;
				// 滑動視窗，每個 cycle 都往前移
				/* Search Buffer 長度可調整 */
				
				search_buffer[10] <= search_buffer[9];
				search_buffer[9] <= search_buffer[8];
				search_buffer[8] <= search_buffer[7];
				search_buffer[7] <= search_buffer[6];
				search_buffer[6] <= search_buffer[5];
				search_buffer[5] <= search_buffer[4];
				search_buffer[4] <= search_buffer[3];
				search_buffer[3] <= search_buffer[2];
				search_buffer[2] <= search_buffer[1];
				search_buffer[1] <= search_buffer[0];
				search_buffer[0] <= str_buffer[0];

				for (i = 0; i < 2047; i = i + 1) begin
					str_buffer[i] <= str_buffer[i + 1];
				end
			end
		endcase
	end
end

endmodule
