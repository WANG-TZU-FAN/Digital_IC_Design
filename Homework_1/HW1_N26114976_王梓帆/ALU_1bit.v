`include "FA.v"

module ALU_1bit(result, c_out, set, overflow, a, b, less, Ainvert, Binvert, c_in, op);
input        a;
input        b;
input        less;
input        Ainvert;
input        Binvert;
input        c_in;
input  [1:0] op;
output       result;
output       c_out;
output       set;                 
output       overflow;
reg			 result, c_out, set, overflow;

/*
	Write Your Design Here ~
*/
wire a_temp, b_temp, result_temp, c_out_temp;

assign a_temp = (!Ainvert)? a : ~a;
assign b_temp = (!Binvert)? b : ~b;

FA FA_ALU(.s(result_temp), .carry_out(c_out_temp), .x(a_temp), .y(b_temp), .carry_in(c_in));

always @(a or b or less or c_in or op)
begin
	case(op)
		2'b00: begin 
			result = a_temp & b_temp;
		end
		2'b01: begin
			result = a_temp | b_temp;
		end
		2'b10: begin
			result = result_temp;
		end
		// Full Case using "default" operator
		default: begin
			result = less;
		end
	endcase
	// Wires have no relations to "op"
	// Do it outside of the case
	overflow = c_out_temp ^ c_in;
	c_out    = c_out_temp;
	set      = result_temp;
end

endmodule
