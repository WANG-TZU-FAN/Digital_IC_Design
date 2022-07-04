module BOE(clk, rst, data_num, data_in, result);
input clk;
input rst;
input [2:0] data_num;
input [7:0] data_in;
output [10:0] result;

reg     [10:0]  result;
reg	    [2:0]   cur_state, next_state;
reg     [3:0]   input_count;
// for summation
reg     [10:0]  summation;
// for maximum searching
reg     [7:0]   max;
// for sorting
reg     [7:0]   sorting_list [5:0];
reg     [3:0]   sorting_count;

parameter [2:0] T1 = 3'b000;
parameter [2:0] T2 = 3'b001;
parameter [2:0] T3 = 3'b010;
parameter [2:0] T4 = 3'b011;
parameter [2:0] T5 = 3'b100;

// state register()
always @(posedge clk) begin
    if (rst) 
        cur_state <= T1;
    else
        cur_state <= next_state;
end

always @(*) begin
	next_state = cur_state;
	case(cur_state)
		T1: begin
            next_state = T2;
        end
        T2: begin
            if(sorting_count == input_count) 
                next_state = T3;
            else
                next_state = T2;
        end
        T3: begin
            next_state = T4;
        end
        T4: begin
            next_state = T5;
        end
        T5: begin
            if(sorting_count == input_count) 
                next_state = T1;
        end
	endcase 
end

integer i;

always @(posedge clk) begin
    if(rst)begin
        input_count <= 0;
        summation   <= 0;
        for (i = 0; i < 7; i = i + 1) begin
            sorting_list[i] <= 0;
        end
    end
    else begin
        case(cur_state) 
        T1: begin
            input_count     <= data_num - 1;
            sorting_list[0] <= data_in;
            max             <= data_in;
            sorting_count   <= 1;
            summation       <= {3'd0, data_in};
        end
        T2: begin
            sorting_count <= sorting_count + 1;
            // when new data larger than old data, change the maximum number
            if(max > data_in) begin
                max <= max;
            end
            else begin
                max <= data_in;
            end
            // sum up all the data inputs
            summation <= summation + {3'd0, data_in};
            // sort for each time
            case(sorting_count)
                1: begin
                    if(data_in > sorting_list[0]) begin
                        sorting_list[0] <= data_in;
                        sorting_list[1] <= sorting_list[0];
                    end
                    else begin
                        sorting_list[1] <= data_in; 
                    end
                end
                2: begin
                    if(data_in > sorting_list[0]) begin
                        sorting_list[0] <= data_in;
                        sorting_list[1] <= sorting_list[0];
                        sorting_list[2] <= sorting_list[1];
                    end
                    else if(data_in > sorting_list[1]) begin
                        sorting_list[1] <= data_in;
                        sorting_list[2] <= sorting_list[1]; 
                    end
                    else begin
                        sorting_list[2] <= data_in; 
                    end
                end
                3: begin
                    if(data_in > sorting_list[0]) begin
                        sorting_list[0] <= data_in;
                        sorting_list[1] <= sorting_list[0];
                        sorting_list[2] <= sorting_list[1];
                        sorting_list[3] <= sorting_list[2];
                    end
                    else if(data_in > sorting_list[1]) begin
                        sorting_list[1] <= data_in;
                        sorting_list[2] <= sorting_list[1];
                        sorting_list[3] <= sorting_list[2];
                    end
                    else if(data_in > sorting_list[2]) begin
                        sorting_list[2] <= data_in;
                        sorting_list[3] <= sorting_list[2];
                    end
                    else begin
                        sorting_list[3] <= data_in;
                    end
                end
                4: begin
                    if(data_in > sorting_list[0]) begin
                        sorting_list[0] <= data_in;
                        sorting_list[1] <= sorting_list[0];
                        sorting_list[2] <= sorting_list[1];
                        sorting_list[3] <= sorting_list[2];
                        sorting_list[4] <= sorting_list[3];
                    end
                    else if(data_in > sorting_list[1]) begin
                        sorting_list[1] <= data_in;
                        sorting_list[2] <= sorting_list[1];
                        sorting_list[3] <= sorting_list[2];
                        sorting_list[4] <= sorting_list[3];
                    end
                    else if(data_in > sorting_list[2]) begin
                        sorting_list[2] <= data_in;
                        sorting_list[3] <= sorting_list[2];
                        sorting_list[4] <= sorting_list[3];
                    end
                    else if(data_in > sorting_list[3]) begin
                        sorting_list[3] <= data_in;
                        sorting_list[4] <= sorting_list[3];
                    end
                    else begin
                        sorting_list[4] <= data_in;
                    end
                end
                5: begin
                    if(data_in > sorting_list[0]) begin
                        sorting_list[0] <= data_in;
                        sorting_list[1] <= sorting_list[0];
                        sorting_list[2] <= sorting_list[1];
                        sorting_list[3] <= sorting_list[2];
                        sorting_list[4] <= sorting_list[3];
                        sorting_list[5] <= sorting_list[4];
                    end
                    else if(data_in > sorting_list[1]) begin
                        sorting_list[1] <= data_in;
                        sorting_list[2] <= sorting_list[1];
                        sorting_list[3] <= sorting_list[2];
                        sorting_list[4] <= sorting_list[3];
                        sorting_list[5] <= sorting_list[4];
                    end
                    else if(data_in > sorting_list[2]) begin
                        sorting_list[2] <= data_in;
                        sorting_list[3] <= sorting_list[2];
                        sorting_list[4] <= sorting_list[3];
                        sorting_list[5] <= sorting_list[4];
                    end
                    else if(data_in > sorting_list[3]) begin
                        sorting_list[3] <= data_in;
                        sorting_list[4] <= sorting_list[3];
                        sorting_list[5] <= sorting_list[4];
                    end
                    else if(data_in > sorting_list[4]) begin
                        sorting_list[4] <= data_in;
                        sorting_list[5] <= sorting_list[4];
                    end
                    else begin
                        sorting_list[5] <= data_in;
                    end
                end
                6:begin
                    if(data_in > sorting_list[0]) begin
                        sorting_list[0] <= data_in;
                        sorting_list[1] <= sorting_list[0];
                        sorting_list[2] <= sorting_list[1];
                        sorting_list[3] <= sorting_list[2];
                        sorting_list[4] <= sorting_list[3];
                        sorting_list[5] <= sorting_list[4];
                        sorting_list[6] <= sorting_list[5];
                    end
                    else if(data_in > sorting_list[1]) begin
                        sorting_list[1] <= data_in;
                        sorting_list[2] <= sorting_list[1];
                        sorting_list[3] <= sorting_list[2];
                        sorting_list[4] <= sorting_list[3];
                        sorting_list[5] <= sorting_list[4];
                        sorting_list[6] <= sorting_list[5];
                    end
                    else if(data_in > sorting_list[2]) begin
                        sorting_list[2] <= data_in;
                        sorting_list[3] <= sorting_list[2];
                        sorting_list[4] <= sorting_list[3];
                        sorting_list[5] <= sorting_list[4];
                        sorting_list[6] <= sorting_list[5];
                    end
                    else if(data_in > sorting_list[3]) begin
                        sorting_list[3] <= data_in;
                        sorting_list[4] <= sorting_list[3];
                        sorting_list[5] <= sorting_list[4];
                        sorting_list[6] <= sorting_list[5];
                    end
                    else if(data_in > sorting_list[4]) begin
                        sorting_list[4] <= data_in;
                        sorting_list[5] <= sorting_list[4];
                        sorting_list[6] <= sorting_list[5];
                    end
                    else if(data_in > sorting_list[5]) begin
                        sorting_list[5] <= data_in;
                        sorting_list[6] <= sorting_list[5];
                    end
                    else begin
                        sorting_list[6] <= data_in;
                    end
                end
            endcase
        end
        // output summation
        T3: begin
            result <= summation;
        end
        // output maximum number
        T4: begin
            sorting_count <= 0;
            result <= {3'd0, max};
        end
        // output sorted result
        T5: begin
            sorting_count <= sorting_count + 1;
            result <= {3'd0, sorting_list[sorting_count]};
        end 
        endcase
    end
end

endmodule
