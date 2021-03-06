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



    input wire [`InstSize] Inst_debug_in,



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



reg[`InstSize] _Inst[`InstSize];



reg[`OpSize] OpCode[`InstSize];



integer i;



reg goal1;



reg[`InstSize] Addr1;



reg[`InstSize] free;



reg[`InstSize] Addr2;



always @(posedge clk_in) begin



    if(rst_in||clear) begin



        



        for(i=0;i<32;i=i+1) begin



            valid [i] <= `zero;



        end



        //RS_is_full <= `zero;



        Calc_en <= `zero;



        



    end



    else if(rdy_in) begin



        



        if(RS_in) begin



            // $display("ROB_Number_in",ROB_Number);



            // $display("OpCode:",OpCode_RS);



            



            if(free!=`zero) begin



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



                    OpCode[Addr2] <= OpCode_RS;_Inst[Addr2] <= Inst_debug_in;



                   



                    //break;



            end



        end



        if(commit_en) begin



            for(i=0;i<32;i=i+1) begin



                if(valid[i]) begin 



                    // if(16091059==_Inst[Addr2]) begin



                    //     $display("FUCKKKKKKKKKklkKK");



                    //     $display(Reg_Status_1_RS);



                    //     $display(Reg_Status_2_RS);



                    //     $display(Reg_Data_1_RS);



                    //     $display(Reg_Data_2_RS);



                    //     $display(Addr2);



                    //     $display("FUCCKKKKKKKKKKK");



                    // end



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



            Calc_en <= `zero;



        end



    end



end







always @(*) begin



    goal1 = `zero;



    Addr1 = 0;



    for(i=0;i<32;i=i+1) begin



        if(valid[i]) begin



            if(RS1_status[i]==`MAXN&&RS2_status[i]==`MAXN) begin



                goal1 = `one;



                Addr1 = i;



            end



        end



    end



end



always @(*) begin



    free = 0;



    RS_is_full = `one;



    Addr2 = 0;



    for(i=0;i<32;i=i+1) begin



        if(!valid[i]) begin



            if(free==0) free= 1;



            if(free==1) free= 2;



            if(free==2) free= 3;



            // if(free==2) free= 3;



            Addr2 = i;



        end



    end



    if(free==3) RS_is_full = 0;



end



endmodule
