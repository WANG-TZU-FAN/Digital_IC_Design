module LZ77_Decoder(clk,reset,ready,code_pos,code_len,chardata,encode,finish,char_nxt);

input 				clk;
input 				reset;
input				ready;
input 		[4:0] 	code_pos;
input 		[4:0] 	code_len;
input 		[7:0] 	chardata;
output	  			encode;
output	  			finish;
output		[7:0] 	char_nxt;

reg     			encode;
reg		  			finish;
reg 	 	[7:0] 	char_nxt;
/* 和 code_len 一樣寬 */
reg			[4:0]	output_counter;	
/* search_buffer 長度 = 30 */
reg			[3:0]	search_buffer[29:0];


always @(posedge clk or posedge reset)
begin
	if(reset)
	begin
		finish <= 0;
		output_counter <= 0;
		encode <= 0;
		char_nxt <= 0;
		/* search_buffer 長度 = 30 */
		search_buffer[0]  <= 4'd0;
		search_buffer[1]  <= 4'd0;
		search_buffer[2]  <= 4'd0;
		search_buffer[3]  <= 4'd0;
		search_buffer[4]  <= 4'd0;
		search_buffer[5]  <= 4'd0;
		search_buffer[6]  <= 4'd0;
		search_buffer[7]  <= 4'd0;
		search_buffer[8]  <= 4'd0;
		search_buffer[9]  <= 4'd0;
		search_buffer[10] <= 4'd0;
		search_buffer[11] <= 4'd0;
		search_buffer[12] <= 4'd0;
		search_buffer[13] <= 4'd0;
		search_buffer[14] <= 4'd0;
		search_buffer[15] <= 4'd0;
		search_buffer[16] <= 4'd0;
		search_buffer[17] <= 4'd0;
		search_buffer[18] <= 4'd0;
		search_buffer[19] <= 4'd0;
		search_buffer[20] <= 4'd0;
		search_buffer[21] <= 4'd0;
		search_buffer[22] <= 4'd0;
		search_buffer[23] <= 4'd0;
		search_buffer[24] <= 4'd0;
		search_buffer[25] <= 4'd0;
		search_buffer[26] <= 4'd0;
		search_buffer[27] <= 4'd0;
		search_buffer[28] <= 4'd0;
		search_buffer[29] <= 4'd0;
	end
	else if(!ready)
	begin
		finish <= finish;
	end
	else begin
		char_nxt <= (output_counter == code_len) ? chardata : search_buffer[code_pos];
		/* search_buffer 長度 = 30 */
		search_buffer[29] <= search_buffer[28];
		search_buffer[28] <= search_buffer[27];
		search_buffer[27] <= search_buffer[26];
		search_buffer[26] <= search_buffer[25];
		search_buffer[25] <= search_buffer[24];
		search_buffer[24] <= search_buffer[23];
		search_buffer[23] <= search_buffer[22];
		search_buffer[22] <= search_buffer[21];
		search_buffer[21] <= search_buffer[20];
		search_buffer[20] <= search_buffer[19];
		search_buffer[19] <= search_buffer[18];
		search_buffer[18] <= search_buffer[17];
		search_buffer[17] <= search_buffer[16];
		search_buffer[16] <= search_buffer[15];
		search_buffer[15] <= search_buffer[14];
		search_buffer[14] <= search_buffer[13];
		search_buffer[13] <= search_buffer[12];
		search_buffer[12] <= search_buffer[11];
		search_buffer[11] <= search_buffer[10];
		search_buffer[10] <= search_buffer[9];
		search_buffer[9]  <= search_buffer[8];
		search_buffer[8]  <= search_buffer[7];
		search_buffer[7]  <= search_buffer[6];
		search_buffer[6]  <= search_buffer[5];
		search_buffer[5]  <= search_buffer[4];
		search_buffer[4]  <= search_buffer[3];
		search_buffer[3]  <= search_buffer[2];
		search_buffer[2]  <= search_buffer[1];
		search_buffer[1]  <= search_buffer[0];
		search_buffer[0]  <= (output_counter == code_len) ? chardata : search_buffer[code_pos];
		output_counter <= (output_counter == code_len) ? 0 : output_counter + 1;
		finish <= (char_nxt == 8'h24) ? 1 : 0;
	end
end




endmodule