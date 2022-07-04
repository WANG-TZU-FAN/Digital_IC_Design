module LZ77_Decoder(clk,reset,code_pos,code_len,chardata,encode,finish,char_nxt);

input 				clk;
input 				reset;
input 		[3:0] 	code_pos;
input 		[2:0] 	code_len;
input 		[7:0] 	chardata;
output  			encode;
output  			finish;
output 	 	[7:0] 	char_nxt;
reg     			encode;
reg		  			finish;
reg 	 	[7:0] 	char_nxt;

// For Search Buffer
reg			[7:0]   search_buffer [8:0];
reg			[3:0]	search_buffer_address;

// Counter of the iteration time
reg			[3:0]	iteration_time;

// 
reg 				start;

// Only for decoding state
// Don't hane to build finite state machine

always@(posedge clk) begin
	if(reset) begin
		encode 			<= 0;
		finish 			<= 0;
		iteration_time 	<= 0;
		start 			<= 1;
	end
	else begin
		// No matching: Directly put the input to the first bit of the search_buffer, and the result.
		if(code_len == 0) begin
			search_buffer[0] 			<= chardata;
			char_nxt 					<= chardata;
			// Terminal Condition of the decoder
			if(chardata == 36) begin
				finish 	<= 1;
			end
			else begin
				finish	<= 0;
			end
		end
		// Matching at least 1 element
		else begin
			// First Round: Because that code_len != 0 
			// => Terminal Condition of the decoder will not occur in the first round
			if(start == 1) begin
				// If Start this round, then pull down the "start" signal
				start 					<= ~start;
				// set the iteration time
				iteration_time 			<= code_len - 1;

				search_buffer[0] 		<= search_buffer[code_pos];
				char_nxt 				<= search_buffer[code_pos];
			end
			// Final Round
			else if(iteration_time == 0) begin
				// If finish this round, then pull up the "start" signal
				start 					<= ~start;
				
				search_buffer[0] 		<= chardata;
				char_nxt 				<= chardata;
				
				if(chardata == 36) begin
					finish 				<= 1;
				end
				else begin
					finish				<= 0;
				end
			end 
			else begin
				search_buffer[0] 		<= search_buffer[code_pos];
				char_nxt 				<= search_buffer[code_pos];
				// counter for the iteration time
				iteration_time 			<= iteration_time - 1;
			end
		end
		// Push the input to the front bit
		for(search_buffer_address = 0; search_buffer_address < 8; search_buffer_address = search_buffer_address + 1) begin
			search_buffer[search_buffer_address + 1] <= search_buffer[search_buffer_address];
		end
	end
end
endmodule