`include "def.v"
module LSB (
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,
    input wire clear,
    //ISSUE
    input wire en_in,
    input wire [`OpSize] OpCode,
    input wire [`InstSize] Reg_Status_1,
    input wire [`InstSize] Reg_Data_1,
    input wire [`InstSize] Reg_Status_2,
    input wire [`InstSize] Reg_Data_2,
    input wire [`InstSize] imm_LSB,
    input wire [`RegAddrSize] ROB_NumbertoLSB,
    input wire [`InstSize] Inst_debug_in,
    //ID
    output reg LSB_is_full,
    //ROB
    input wire en_commit,
    input wire[`RegAddrSize] ROB_Number,
    input wire[`RegAddrSize] Reg_Number,
    input wire[`InstSize] Reg_Val,
    output reg LSB_in,
    output reg[`RegAddrSize] ROB_Number_LSB,
    output reg[`InstSize] Value,
    input wire[`RegAddrSize] ROB_head,
    //MemCtrl
    output reg data_w_en,
    output reg[`InstSize] data_addr,
    output reg[`InstSize] data_val,
    output reg data_r_en,
    output reg[`InstSize] data_len,
    input wire LSB_en_o,
    input wire[`InstSize] LSB_data_o
);
parameter size = 32;
reg[`InstSize] Reg_Status1[`InstSize];
reg[`InstSize] Reg_Data1[`InstSize];
reg[`InstSize] Reg_Status2[`InstSize];
reg[`InstSize] Reg_Data2[`InstSize];
reg[`InstSize] _OpCode[`InstSize];
reg[`InstSize] ROB_Number_[`InstSize];
reg[`InstSize] Imm[`InstSize];
reg[`InstSize] _Inst[`InstSize];
reg Commited[`InstSize];
reg Valid[`InstSize];
reg[`InstSize] head,tail;
wire[`InstSize] _head,_tail;
wire[`InstSize] temp;
assign temp = (Imm[head]+Reg_Data1[head]);
assign _tail = (en_in&&!clear)?((tail+1)%size):tail;
integer i;
reg commited_number;
always @(posedge clk_in) begin
    // if(clear==1) begin
    //     $display("gg");
    // end
    if(rst_in) begin
        head <= 0;
        tail <= 0;
        data_w_en <= `zero;
        data_r_en <= `zero;
        LSB_in <= `zero;
        LSB_is_full <= `zero;
        commited_number <= 0;
    end
    else if(rdy_in) begin
        if(en_in&&!clear) begin
            // $display("FUCKINGgggggggggggggggggggg",OpCode);
            // $display(ROB_NumbertoLSB);
            // $display(head);
            // $display(tail);
            // $display(Reg_Status_1);
            // $display(Reg_Status_2);
            // $display(Reg_Data_1);$display(Reg_Data_2);
            if(en_commit) begin
                
                if((ROB_Number==Reg_Status_1)) begin
                    Reg_Status1[tail] <= `MAXN;
                    Reg_Data1[tail] <= Reg_Val;
                    //$display("FCCCC");
                end
                else begin
                    Reg_Status1[tail] <= Reg_Status_1;
                    Reg_Data1[tail] <= Reg_Data_1;
                   
                end
                if((ROB_Number==Reg_Status_2)) begin
                    Reg_Status2[tail] <= `MAXN;
                    Reg_Data2[tail] <= Reg_Val;
                    //$display("FCCCC");
                end
                else begin
                    Reg_Status2[tail] <= Reg_Status_2;
                    Reg_Data2[tail] <= Reg_Data_2;
                    
                end
            end
            else begin
                //$display("FUCKINGgggggggggggggggggggg",OpCode);
                Reg_Status1[tail] <= Reg_Status_1;
                Reg_Data1[tail] <= Reg_Data_1;
                //$display(Reg_Status_1,"/",Reg_Data_1,"/",Reg_Status_2,"/",Reg_Data_2,"/");
                Reg_Status2[tail] <= Reg_Status_2;
                Reg_Data2[tail] <= Reg_Data_2;
            end
            Valid[tail] <= 0;
            _OpCode[tail] <= OpCode;
            ROB_Number_[tail] <= ROB_NumbertoLSB;
            Imm[tail] <=imm_LSB;
            _Inst[tail] <= Inst_debug_in;
            // $display(imm_LSB);
            Commited[tail] <= 0;
            // if(Inst_debug_in==653565987) begin
                // $display("FUCCCCCCk");
            // end
        end
        tail <= _tail;
        if(en_commit)begin
            
            for(i=head;i!=tail;i=(i+1)%size) begin
                //$display("Reg_Status1[i]",ROB_Number);
                if(Reg_Status1[i]==ROB_Number) begin
                    Reg_Status1[i]<=`MAXN;
                    Reg_Data1[i]<=Reg_Val;
                    //$display("OpCoders1:",OpCode,Reg_Val);
                end
                if(Reg_Status2[i]==ROB_Number) begin
                    Reg_Status2[i]<=`MAXN;
                    Reg_Data2[i]<=Reg_Val;
                    //$display("OpCoders2:",OpCode,Reg_Val);
                end
                if(ROB_Number_[i]==ROB_Number) begin
                    Commited[i] <= `one;
                    //$display("YESS:",i);
                end
            end
        end
        if(head!=tail) begin
            if(Valid[head]) begin
                if(LSB_en_o) begin
                    // $display("YES!!!!");
                    head <= (head+1)%size;
                    case(_OpCode[head])
                    `lb,`lh,`lw,`lbu,`lhu:begin
                        LSB_in <= `one;
                        ROB_Number_LSB <= ROB_Number_[head];
                        data_w_en <= `zero;
                        data_r_en <=`zero;
                        case(_OpCode[head])
                        `lb:begin
                            if(LSB_data_o[7])begin
                                Value <={{24{1'b1}},LSB_data_o[7:0]};
                            end
                            else Value<= LSB_data_o;
                        end
                        `lh:begin
                            if(LSB_data_o[15])begin
                                Value <={{16{1'b1}},LSB_data_o[15:0]};
                            end
                            else Value<= LSB_data_o;
                        end
                        `lw,`lbu,`lhu:begin
                            Value <= LSB_data_o;
                            // $display("LOAD_IN",LSB_data_o);
                        end
                        endcase
                    end
                    default:begin
                        data_w_en <= 0;
                        data_r_en <= 0;
                        LSB_in <= 0;
                    end
                    endcase
                    LSB_is_full <= (((_tail+1)%size==(head+1)%size)||((_tail+2)%size==(head+1)%size)||((_tail+3)%size==(head+1)%size));
                end
                else begin
                    LSB_in <= `zero;
                    LSB_is_full <= (((_tail+1)%size==head)||((_tail+2)%size==head)||((_tail+3)%size==head));
                end
            end
            else begin
                //$display("OpCode[head]",OpCode[head]);
                case(_OpCode[head])
                `lb:begin
                    if((Reg_Status1[head]==`MAXN)&&(!(temp[17:16]==2'b11&&ROB_head!=ROB_Number_[head])))  begin
                        Valid[head] <= 1;
                        LSB_in <= `zero;
                        data_w_en <=`zero;
                        data_r_en <=`one;
                        data_addr <= Imm[head]+Reg_Data1[head];
                        data_len <= 1;
                        // $display("0 addr:",Reg_Data1[head]+Imm[head]);
                        // $display("%h",_Inst[head]);
                    end
                    else begin
                        LSB_in <= `zero;
                        data_w_en <=`zero;
                        data_r_en <=`zero;
                    end
                end
                `lh:begin
                    if((Reg_Status1[head]==`MAXN)&&(!(temp[17:16]==2'b11&&ROB_head!=ROB_Number_[head]))) begin
                        Valid[head] <= 1;
                        LSB_in <= `zero;
                        data_w_en <=`zero;
                        data_r_en <=`one;
                        data_addr <= Imm[head]+Reg_Data1[head];
                        data_len <= 2;
                        // $display("1 addr:",Reg_Data1[head]+Imm[head]);
                        // $display("%h",_Inst[head]);
                    end
                    else begin
                        LSB_in <= `zero;
                        data_w_en <=`zero;
                        data_r_en <=`zero;
                    end
                end
                `lw:begin
                    if((Reg_Status1[head]==`MAXN)&&(!(temp[17:16]==2'b11&&ROB_head!=ROB_Number_[head]))) begin
                        Valid[head] <= 1;
                        LSB_in <= `zero;
                        data_w_en <=`zero;
                        data_r_en <=`one;
                        data_addr <= Imm[head]+Reg_Data1[head];
                        data_len <= 4;
                        // $display("2 addr:",Reg_Data1[head]+Imm[head]);
                        // $display("%h",_Inst[head]);
                    end
                    else begin
                        LSB_in <= `zero;
                        data_w_en <=`zero;
                        data_r_en <=`zero;
                    end
                end
                `lbu:begin
                    
                    if((Reg_Status1[head]==`MAXN)&&(!(temp[17:16]==2'b11&&ROB_head!=ROB_Number_[head]))) begin
                        Valid[head] <= 1;
                        LSB_in <= `zero;
                        data_w_en <=`zero;
                        //$display("Fuckkkkkkkkkkkkkkkkkk");
                        data_r_en <=`one;
                        // $display(Imm[head]+Reg_Data1[head]);
                        data_addr <= Imm[head]+Reg_Data1[head];
                        data_len <= 1;
                        // $display("3 addr:",Reg_Data1[head]+Imm[head]);
                        // $display("%h",_Inst[head]);
                    end
                    else begin
                        LSB_in <= `zero;
                        data_w_en <=`zero;
                        data_r_en <=`zero;
                    end
                end
                `lhu:begin
                    if((Reg_Status1[head]==`MAXN)&&(!(temp[17:16]==2'b11&&ROB_head!=ROB_Number_[head]))) begin
                        Valid[head] <= 1;
                        LSB_in <= `zero;
                        data_w_en <=`zero;
                        data_r_en <=`one;
                        data_addr <= Imm[head]+Reg_Data1[head];
                        data_len <= 2;
                        // $display("4 addr:",Reg_Data1[head]+Imm[head]);
                        // $display("%h",_Inst[head]);
                    end
                    else begin
                        LSB_in <= `zero;
                        data_w_en <=`zero;
                        data_r_en <=`zero;
                    end
                end
                `sb:begin
                    // $display("OpCodehead:",head);
                    if(Commited[head]) begin
                        Valid[head] <= 1;
                        LSB_in <= `zero;
                        data_w_en <=`one;
                        data_r_en <=`zero;
                        data_addr <= Imm[head]+Reg_Data1[head];
                        data_val <= Reg_Data2[head][7:0];
                        data_len <= 1;
                        // $display(Reg_Data2[head][7:0]," 1 addr:",Reg_Data1[head]+Imm[head]);
                        // $display("%h",_Inst[head]);
                    end
                    else begin
                        LSB_in <= `zero;
                        data_w_en <=`zero;
                        data_r_en <=`zero;
                    end
                end
                `sh:begin
                    if(Commited[head]) begin
                        Valid[head] <= 1;
                        LSB_in <= `zero;
                        data_w_en <=`one;
                        data_r_en <=`zero;
                        data_addr <= Imm[head]+Reg_Data1[head];
                        data_val <= Reg_Data2[head][14:0];
                        data_len <= 2;
                        // $display(Reg_Data2[head][14:0]," 2 addr:",Reg_Data1[head]+Imm[head]);
                        // $display("%h",_Inst[head]);
                    end
                    else begin
                        LSB_in <= `zero;
                        data_w_en <=`zero;
                        data_r_en <=`zero;
                    end
                end
                `sw:begin
                    if(Commited[head]) begin
                        Valid[head] <= 1;
                        LSB_in <= `zero;
                        data_w_en <=`one;
                        data_r_en <=`zero;
                        data_addr <= Imm[head]+Reg_Data1[head];
                        data_val <= Reg_Data2[head];
                        data_len <= 4;
                        // $display(Reg_Data2[head]," 4 addr: ",Reg_Data1[head]+Imm[head]);
                        // $display("%h",_Inst[head]);
                    end
                    else begin
                        LSB_in <= `zero;
                        data_w_en <=`zero;
                        data_r_en <=`zero;
                    end
                end
                endcase
                LSB_is_full <= (((_tail+1)%size==head)||((_tail+2)%size==head)||((_tail+3)%size==head));
            end
        end
        else begin
            LSB_in <= `zero;
            data_w_en <=`zero;
            data_r_en <=`zero;
            LSB_is_full <= (((_tail+1)%size==head)||((_tail+2)%size==head)||((_tail+3)%size==head));
        end
    end
end
reg[`InstSize] tmp;
always @(*) begin
    if(clear) begin
        tmp=(head+31)%size;
        for(i=head;i!=tail;i=(i+1)%size) begin
            if(Commited[i]) tmp=i;
        end
        tail=(tmp+1)%size;
        LSB_is_full = ((tail+1)%size==head)||((tail+2)%size==head)||((tail+3)%size==head);
        if(tail==head&&Valid[head]) begin
            data_w_en = `zero;
            data_r_en = `zero;
        end
        LSB_in = `zero;
    end
end
endmodule