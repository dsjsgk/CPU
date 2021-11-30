`include "def.v"
module RS (
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,
    input wire clear,
    //to ID
    output wire RS_is_Valid,
    //from ISSUE
    input wire RS_in,
    input wire [`RegAddrSize] ROB_Number,
    input wire [`OpSize] OpCode_RS,
    input wire [`InstSize] Reg_Status_1_RS,
    input wire [`InstSize] Reg_Data_1_RS,
    input wire [`InstSize] Reg_Status_2_RS,
    input wire [`InstSize] Reg_Data_2_RS,
    //from ROB
    input wire commit_en,
    input wire[`RegAddrSize] commit_Number,
    input wire[`InstSize] commit_val,
    //to ALU
    output wire Calc_en,
    output wire[`OpSize] OpCode_o,
    output wire[`InstSize] val1,
    output wire[`InstSize] val2,
    output wire[`RegAddrSize] ROB_Number_o,
);
reg valid[`InstSize];
reg[`InstSize] RS1_data[`InstSize];
reg[`InstSize] RS2_data[`InstSize];
reg[`InstSize] RS1_status[`InstSize];
reg[`InstSize] RS2_status[`InstSize];
reg[`RegAddrSize] ROB_id[`InstSize];
reg[`OpSize] OpCode[`InstSize];
always @(clk_in) begin
    if(rst_in||clear) begin
        integer i ;
        for(i=0;i<32;++i) begin
            valid [i] <= `zero;
        end
        RS_is_Valid <= `one;
    end
    else if(rdy_in) begin
        integer i;
        if(RS_in) begin
            for(i=0;i<32;++i) begin
                if(!valid[i]) begin
                    valid[i] <= `one;
                    if(commit_en&&Reg_Status_1_RS==commit_Number) begin
                        RS1_status[i] <= `MAXN;
                        RS1_data[i] <= commit_val;
                    end
                    else begin
                        RS1_status[i] <= Reg_Status_1_RS;
                        RS1_data[i] <= Reg_Data_1_RS;
                    end
                    if(commit_en&&Reg_Status_2_RS==commit_Number) begin
                        RS2_status[i] <= `MAXN;
                        RS2_data[i] <= commit_val;
                    end
                    else begin
                        RS2_status[i] <= Reg_Status_2_RS;
                        RS2_data[i] <= Reg_Data_2_RS;
                    end
                    ROB_id[i] <= ROB_Number;
                    OpCode[i] <= OpCode_RS;
                    break;
                end
            end
        end
        for(i=0;i<32;++i) begin
            if(valid[i]) begin
                if(RS1_status[i]==commit_Number) begin
                    RS1_status[i] <= `MAXN;
                    RS1_data[i] <= commit_val;
                end
                if(RS2_status[i]==commit_Number) begin
                    RS2_status[i] <= `MAXN;
                    RS2_data[i] <= commit_val;
                end
            end
        end
        Calc_en = `zero;
        for(i=0;i<32;++i) begin
            if(valid[i]) begin
                if(RS1_status[i]==`MAXN&&RS2_status[i]==`MAXN) begin
                    valid[i] <= `zero;
                    Calc_en <= `one;
                    val1 <= RS1_data[i];
                    val2 <=RS2_data[i];
                    OpCode_o <= OpCode[i];
                    ROB_Number_o <= ROB_id[i];
                    break;
                end
            end
        end
    end
end
endmodule