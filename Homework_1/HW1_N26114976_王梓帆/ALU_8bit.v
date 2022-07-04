module ALU_8bit(result, zero, overflow, ALU_src1, ALU_src2, Ainvert, Binvert, op);
input  [7:0] ALU_src1;
input  [7:0] ALU_src2;
input        Ainvert;
input        Binvert;
input  [1:0] op;
output [7:0] result;
output       zero;
output       overflow;

/*
	Write Your Design Here ~
*/

wire ALU_c_trans [6:0];
wire ALU7_set, ALU1_less;

ALU_1bit ALU0(.result(result[0]),.c_out(ALU_c_trans[0]), .set()             , .overflow()        , .a(ALU_src1[0]), .b(ALU_src2[0]), .less(ALU1_less), .Ainvert(Ainvert), .Binvert(Binvert), .c_in(Binvert)       , .op(op));
ALU_1bit ALU1(.result(result[1]),.c_out(ALU_c_trans[1]), .set()             , .overflow()        , .a(ALU_src1[1]), .b(ALU_src2[1]), .less(1'b0)     , .Ainvert(Ainvert), .Binvert(Binvert), .c_in(ALU_c_trans[0]), .op(op));
ALU_1bit ALU2(.result(result[2]),.c_out(ALU_c_trans[2]), .set()             , .overflow()        , .a(ALU_src1[2]), .b(ALU_src2[2]), .less(1'b0)     , .Ainvert(Ainvert), .Binvert(Binvert), .c_in(ALU_c_trans[1]), .op(op));
ALU_1bit ALU3(.result(result[3]),.c_out(ALU_c_trans[3]), .set()             , .overflow()        , .a(ALU_src1[3]), .b(ALU_src2[3]), .less(1'b0)     , .Ainvert(Ainvert), .Binvert(Binvert), .c_in(ALU_c_trans[2]), .op(op));
ALU_1bit ALU4(.result(result[4]),.c_out(ALU_c_trans[4]), .set()             , .overflow()        , .a(ALU_src1[4]), .b(ALU_src2[4]), .less(1'b0)     , .Ainvert(Ainvert), .Binvert(Binvert), .c_in(ALU_c_trans[3]), .op(op));
ALU_1bit ALU5(.result(result[5]),.c_out(ALU_c_trans[5]), .set()             , .overflow()        , .a(ALU_src1[5]), .b(ALU_src2[5]), .less(1'b0)     , .Ainvert(Ainvert), .Binvert(Binvert), .c_in(ALU_c_trans[4]), .op(op));
ALU_1bit ALU6(.result(result[6]),.c_out(ALU_c_trans[6]), .set()             , .overflow()        , .a(ALU_src1[6]), .b(ALU_src2[6]), .less(1'b0)     , .Ainvert(Ainvert), .Binvert(Binvert), .c_in(ALU_c_trans[5]), .op(op));
ALU_1bit ALU7(.result(result[7]),.c_out()              , .set(ALU7_set)     , .overflow(overflow), .a(ALU_src1[7]), .b(ALU_src2[7]), .less(1'b0)     , .Ainvert(Ainvert), .Binvert(Binvert), .c_in(ALU_c_trans[6]), .op(op));

nor nor1(zero, result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7]);

xor Comb(ALU1_less, ALU7_set, overflow);

endmodule
