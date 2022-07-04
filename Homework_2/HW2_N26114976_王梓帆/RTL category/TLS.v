module TLS(clk, reset, Set, Stop, Jump, Gin, Yin, Rin, Gout, Yout, Rout);
input           clk;
input           reset;
input           Set;
input           Stop;
input           Jump;
input     [3:0] Gin;
input     [3:0] Yin;
input     [3:0] Rin;
output          Gout;
output          Yout;
output          Rout;
/*
    Write Your Design Here ~
*/
wire recount_counter;

Controlunit CU (.clk(clk), .reset(reset), .Set(Set), .Stop(Stop), .Jump(Jump), .recount_counter(recount_counter), .Gout(Gout), .Yout(Yout), .Rout(Rout));
Datapath    DP (.clk(clk), .reset(reset), .Set(Set), .Stop(Stop), .Jump(Jump), .recount_counter(recount_counter), .GYR({Gout, Yout, Rout}), .Gin(Gin), .Yin(Yin), .Rin(Rin));

endmodule


module Controlunit (clk, reset, Set, Stop, Jump, recount_counter, Gout, Yout, Rout);
input  clk, reset, Set, Stop, Jump, recount_counter;
output Gout, Yout, Rout;
reg    Gout, Yout, Rout;
reg [1:0] currentstate, nextstate;
parameter [1:0] Green_Light = 2'b00, Yellow_Light = 2'b01, Red_Light = 2'b10;
// State Register (Sequential Circuit)
always@(posedge clk)
begin
    if(Set)
        currentstate = Green_Light;
    else
        currentstate = nextstate;
end
// Next State Logic (Combinatial Circuit)
always@(*)
begin
    case(currentstate)
        Green_Light:begin
            // Jump 的優線順位更高
            if(Jump)
                nextstate = Red_Light;
            else begin
                if(recount_counter)
                    nextstate = Yellow_Light;
                else
                    nextstate = Green_Light;
            end
        end
        Yellow_Light:begin
            if(Jump)
                nextstate = Red_Light;
            else begin
                if(recount_counter)
                    nextstate = Red_Light;
                else
                    nextstate = Yellow_Light;
            end
        end
        Red_Light:begin
            if(recount_counter)
                nextstate = Green_Light;
            else
                nextstate = Red_Light;
        end
        default: nextstate = Green_Light;
    endcase
end
// Output Logic (Combinatial Circuit)
always @(currentstate)
begin
    case(currentstate)
    Green_Light: begin
        Gout = 1'b1;
        Yout = 1'b0;
        Rout = 1'b0;
    end
    Yellow_Light: begin
        Gout = 1'b0;
        Yout = 1'b1;
        Rout = 1'b0;
    end
    Red_Light: begin
        Gout = 1'b0;
        Yout = 1'b0;
        Rout = 1'b1;
    end
    default: begin
        Gout = 1'b0;
        Yout = 1'b0;
        Rout = 1'b0;
    end
    endcase
end
endmodule

module Datapath(clk, reset, Set, Stop, Jump, GYR, recount_counter, Gin, Yin, Rin);

input clk, reset, Set, Stop, Jump; 
input [3:0] Gin, Yin, Rin;
input [2:0] GYR;
output recount_counter;

wire [3:0] counter;
wire [3:0] G_times, Y_times, R_times;

SettingTime Setting (.Set(Set), .Gin(Gin), .Yin(Yin), .Rin(Rin), .G_times(G_times), .Y_times(Y_times), .R_times(R_times));
Counter Count (.clk(clk), .reset(reset), .Set(Set), .Stop(Stop), .recount_counter(recount_counter), .counter(counter));
Compare Comp  (.Stop(Stop), .Jump(Jump), .current_times(counter), .GYR(GYR), .recount_counter(recount_counter), .G_times(G_times), .Y_times(Y_times), .R_times(R_times));

endmodule

// 設定時間的函式
module SettingTime(Set, Gin, Yin, Rin, G_times, Y_times, R_times);
input Set;
input  [3:0] Gin, Yin, Rin;
output [3:0] G_times, Y_times, R_times;
reg    [3:0] G_times, Y_times, R_times;

// 只有在 Set = 1 的時候讀值，在下次 Set 之前都是維持同一個值
always@(posedge Set) begin
    G_times <= Gin;
    Y_times <= Yin;
    R_times <= Rin;
end

endmodule

module Counter (clk, reset, Set, Stop, recount_counter, counter);
input clk, Set, reset, Stop, recount_counter;
output [3:0] counter;
reg    [3:0] counter;

// 計數器在歸零的時候是 1
// 這樣子計數器才會正常運作
always@(posedge clk)
begin
    if(reset)
        counter = 1;
    else begin
        if(Set)
            counter = 1;
        else begin
            if(recount_counter)
                counter = 1;
            else begin
                if(Stop)
                    counter = counter;
                else
                    counter = counter + 1;
            end
        end
    end
end

endmodule

module Compare(Stop, Jump, current_times, GYR, recount_counter, G_times, Y_times, R_times);
input [2:0] GYR;
input [3:0] current_times;
input [3:0] G_times, Y_times, R_times;
input Stop, Jump;
output recount_counter;
reg    recount_counter;

// 有出現一種特別的情況
// 在 current_times 等於設定時間的時候
// 剛好亮起 Stop 訊號
// 這個時候要延續原本的燈號
// 而且不能夠重製時間
always @(*) begin
    case(GYR)
        3'b100: begin
            if(Jump)
                recount_counter = 1;
            else begin
                if(Stop)
                    recount_counter = 0;
                else begin
                    if(current_times == G_times)
                        recount_counter = 1;
                    else
                        recount_counter = 0;
                end
            end
        end
        3'b010: begin
            if(Jump)
                recount_counter = 1;
            else begin
                if(Stop)
                    recount_counter = 0;
                else begin
                    if(current_times == Y_times)
                        recount_counter = 1;
                    else
                        recount_counter = 0;
                end
            end
        end
        3'b001: begin
            if(Stop)
                recount_counter = 0;
            else begin
                if (current_times == R_times)
                    recount_counter = 1;
                else
                    recount_counter = 0;
            end
        end
        default: recount_counter = 1;
    endcase
end

endmodule

