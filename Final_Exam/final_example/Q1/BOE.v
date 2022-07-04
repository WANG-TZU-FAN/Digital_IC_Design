module BOE(clk, rst, data_num, data_in, result);
input 	    		clk;
input 	    		rst;
input 	    [2:0] 	data_num;
input 	    [7:0] 	data_in;
output reg  [10:0] 	result;


reg [10:0] sum;
reg [7:0] buffer [0:5];
reg [2:0] state, next_state;
reg [2:0] count;
reg [2:0] data_num_reg;

reg [7:0] sorted_buffer [0:5];

integer i;

localparam	RESET = 0,
			GET_AND_SORT = 1,
			OUTPUT_SUM = 2,
			OUTPUT_MIN = 3,
			OUTPUT_SORTED_DATA = 4;

always@(*) begin
	if(data_in < buffer[0]) begin
		sorted_buffer[0] = data_in;
		for(i=1;i<6;i=i+1) sorted_buffer[i] = buffer[i-1];
	end
	else if(data_in < buffer[1]) begin
		for(i=0;i<1;i=i+1) sorted_buffer[i] = buffer[i];
		sorted_buffer[1] = data_in;
		for(i=2;i<6;i=i+1) sorted_buffer[i] = buffer[i-1];
	end
	else if(data_in < buffer[2]) begin
		for(i=0;i<2;i=i+1) sorted_buffer[i] = buffer[i];
		sorted_buffer[2] = data_in;
		for(i=3;i<6;i=i+1) sorted_buffer[i] = buffer[i-1];
	end
	else if(data_in < buffer[3]) begin
		for(i=0;i<3;i=i+1) sorted_buffer[i] = buffer[i];
		sorted_buffer[3] = data_in;
		for(i=4;i<6;i=i+1) sorted_buffer[i] = buffer[i-1];
	end
	else if(data_in < buffer[4]) begin
		for(i=0;i<4;i=i+1) sorted_buffer[i] = buffer[i];
		sorted_buffer[4] = data_in;
		for(i=5;i<6;i=i+1) sorted_buffer[i] = buffer[i-1];
	end
	else begin
		for(i=0;i<5;i=i+1) sorted_buffer[i] = buffer[i];
		sorted_buffer[5] = data_in;
	end
end

always@(*) begin
	case(state)
		RESET: begin
			next_state = GET_AND_SORT;
		end
		GET_AND_SORT: begin
			if(count==1) next_state = OUTPUT_SUM;
			else next_state = GET_AND_SORT;
		end
		OUTPUT_SUM: begin
			next_state = OUTPUT_MIN;
		end
		OUTPUT_MIN: begin
			next_state = OUTPUT_SORTED_DATA;
		end
		default: begin	// OUTPUT_SORTED_DATA
			if(count == data_num_reg) next_state = RESET;
			else next_state = OUTPUT_SORTED_DATA;
		end
	endcase
end

always@(posedge clk or posedge rst) begin
	if(rst) begin
		state <= RESET;
	end
	else begin
		state <= next_state;
		
		case(state) 
			// reset
			RESET: begin
				data_num_reg <= data_num-1;
				count <= data_num-1;
				sum <= data_in;
				buffer[0] <= data_in;
				for(i=1;i<8;i=i+1) begin
					buffer[i] <= 8'b11111111;
				end
			end
			GET_AND_SORT: begin
				for(i=0;i<7;i=i+1) begin
					buffer[i] <= sorted_buffer[i];
				end
				sum <= sum+data_in;
				count <= count-1;
			end
			OUTPUT_SUM: begin
				result <= sum;
			end
			OUTPUT_MIN: begin
				result <= buffer[0];
			end
			OUTPUT_SORTED_DATA: begin
				result <= buffer[data_num_reg-count];
				count <= count+1;
			end
		endcase
	end
end




endmodule