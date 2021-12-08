`include "def.v"
module RS (
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,
    input wire clear,
    //to ID
    output reg RS_is_full,
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
    output reg Calc_en,
    output reg[`OpSize] OpCode_o,
    output reg[`InstSize] val1,
    output reg[`InstSize] val2,
    output reg[`RegAddrSize] ROB_Number_o
);
reg valid[`InstSize];
reg[`InstSize] RS1_data[`InstSize];
reg[`InstSize] RS2_data[`InstSize];
reg[`InstSize] RS1_status[`InstSize];
reg[`InstSize] RS2_status[`InstSize];
reg[`RegAddrSize] ROB_id[`InstSize];
reg[`OpSize] OpCode[`InstSize];
integer i;
reg goal1;
reg[`InstSize] Addr1;
reg free;
reg[`InstSize] Addr2;
always @(posedge clk_in) begin
    if(rst_in||clear) begin
        
        for(i=0;i<32;++i) begin
            valid [i] <= `zero;
        end
        RS_is_full <= `zero;
        Calc_en <= `zero;
    end
    else if(rdy_in) begin
        
        if(RS_in) begin
            // $display("ROB_Number_in",ROB_Number);
            // $display("OpCode:",OpCode_RS);
            if(free == `one)begin
                    valid[Addr2] <= `one;
                    if(commit_en&&Reg_Status_1_RS==commit_Number) begin
                        RS1_status[Addr2] <= `MAXN;
                        RS1_data[Addr2] <= commit_val;
                    end
                    else begin
                        //$display("Reg_Status_1_RS:",Reg_Status_1_RS);
                        RS1_status[Addr2] <= Reg_Status_1_RS;
                        //$display("Reg_Data_1_RS:",Reg_Data_1_RS);
                        RS1_data[Addr2] <= Reg_Data_1_RS;
                    end
                    if(commit_en&&Reg_Status_2_RS==commit_Number) begin
                        RS2_status[Addr2] <= `MAXN;
                        RS2_data[Addr2] <= commit_val;
                    end
                    else begin
                        //$display("Reg_Status_2_RS:",Reg_Status_2_RS);
                        RS2_status[Addr2] <= Reg_Status_2_RS;
                        //$display("Reg_Data_2_RS:",Reg_Data_2_RS);
                        RS2_data[Addr2] <= Reg_Data_2_RS;
                    end
                    ROB_id[Addr2] <= ROB_Number;
                    OpCode[Addr2] <= OpCode_RS;
                    //break;
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
        
        if(goal1)begin
            valid[Addr1] <= `zero;
            Calc_en <= `one;
            val1 <= RS1_data[Addr1];
            val2 <=RS2_data[Addr1];
            OpCode_o <= OpCode[Addr1];
            ROB_Number_o <= ROB_id[Addr1];
        end
        else begin
            Calc_en = `zero;
        end
    end
end
reg[`InstSize] tmp;

always @(*) begin
    goal1 = `zero;
    for(i=0;i<32;++i) begin
        if(valid[i]) begin
            if(RS1_status[i]==`MAXN&&RS2_status[i]==`MAXN) begin
                goal1 = `one;
                Addr1 = i;
            end
        end
    end
    free = `zero;
    RS_is_full = `one;
    tmp=0;
    for(i=0;i<32;++i) begin
        if(!valid[i]) begin
            tmp=tmp+1;
            if(tmp==3) RS_is_full = `zero;
            free = `one;
            Addr2 = i;
            //$display(i);
        end
    end
end
endmodule