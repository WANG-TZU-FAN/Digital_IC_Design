module LZ77_Decoder(clk,reset,code_pos,code_len,chardata,encode,finish,char_nxt);

input 				clk;
input 				reset;
input 		[3:0] 	code_pos;
input 		[2:0] 	code_len;
input 		[7:0] 	chardata;
output  reg			encode;
output  reg			finish;
output 	reg [7:0] 	char_nxt;
/* 和 code_len 一樣寬 */
reg			[2:0]	output_counter;	
/* search_buffer 長度 = 9 */
reg			[3:0]	search_buffer[10:0];


always @(posedge clk or posedge reset)
begin
	if(reset)
	begin
		finish <= 0;
		output_counter <= 0;
		encode <= 0;
		char_nxt <= 0;
		/* search_buffer 長度 = 9 */
        
		search_buffer[10] <= 0;
		search_buffer[9] <= 0;
		search_buffer[8] <= 0;
		search_buffer[7] <= 0;
		search_buffer[6] <= 0;
		search_buffer[5] <= 0;
		search_buffer[4] <= 0;
		search_buffer[3] <= 0;
		search_buffer[2] <= 0;
		search_buffer[1] <= 0;
		search_buffer[0] <= 0;
	end
	else
	begin
		char_nxt <= (output_counter == code_len) ? chardata : search_buffer[code_pos];
		/* search_buffer 長度 = 9 */
        
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
		// 最右邊要接到 chardata 或 search_buffer[code_pos]
		search_buffer[0] <= (output_counter == code_len) ? chardata : search_buffer[code_pos];
		output_counter <= (output_counter == code_len) ? 0 : output_counter + 1;
		finish <= (char_nxt==8'h24) ? 1 : 0;
	end
end




endmodule



