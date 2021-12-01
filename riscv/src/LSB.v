`include "def.v"
module LSB (parameter size = 32;)(
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
    input wire [`InstSize] ROB_NumbertoLSB,
    //ID
    output wire LSB_is_full,
    //ROB
    input wire en_commit,
    input wire[`RegAddrSize] ROB_Number,
    input wire[`RegAddrSize] Reg_Number,
    input wire[`InstSize] Reg_Val,
    output wire LSB_in,
    output wire[`RegAddrSize] ROB_Number_LSB,
    output wire[`InstSize] Value,
    //MemCtrl
    output wire data_w_en,
    output wire[`InstSize] data_addr,
    output wire[`InstSize] data_val,
    output wire data_r_en,
    output wire[`InstSize] data_len,
    input wire LSB_en_o,
    input wire[`InstSize] LSB_data_o
);
reg[`InstSize] Reg_Status1[`InstSize];
reg[`InstSize] Reg_Data1[`InstSize];
reg[`InstSize] Reg_Status2[`InstSize];
reg[`InstSize] Reg_Data2[`InstSize];
reg[`InstSize] _OpCode[`InstSize];
reg[`InstSize] ROB_Number_[`InstSize];
reg[`InstSize] Imm[`InstSize];
reg Commited[`InstSize];
reg Valid[`InstSize];
reg[`InstSize] head,tail;
wire[`InstSize] _head,_tail;
assign _tail = en_in?((tail+1)%size):tail;
always @(posedge clk_in) begin
    if(rst_in||clear) begin
        
    end
    else if(rdy_in) begin
        if(en_in) begin
            if(en_commit) begin
                if((ROB_Number==Reg_Status_1)) begin
                    Reg_Status1[tail] <= `MAXN;
                    Reg_Data1[tail] <= Reg_Val;
                end
                else begin
                    Reg_Status1[tail] <= Reg_Status_1;
                    Reg_Data1[tail] <= Reg_Data_1;
                end
                if((ROB_Number==Reg_Status_2)) begin
                    Reg_Status2[tail] <= `MAXN;
                    Reg_Data2[tail] <= Reg_Val;
                end
                else begin
                    Reg_Status2[tail] <= Reg_Status_2;
                    Reg_Data2[tail] <= Reg_Data_2;
                end
            end
            else begin
                Reg_Status1[tail] <= Reg_Status_1;
                Reg_Data1[tail] <= Reg_Data_1;
                Reg_Status2[tail] <= Reg_Status_2;
                Reg_Data2[tail] <= Reg_Data_2;

            end
            Valid[tail] <= 0;
            _OpCode[tail] <= OpCode;
            ROB_Number_ <= ROB_NumbertoLSB;
            Imm[tail] <=imm_LSB;
            Commited[tail] <= 0;
        end
        tail <= _tail;
        if(en_commit)begin
            integer i;
            for(i=head;i!=tail;i=(i+1)%size) begin
                if(Reg_Status1[i]==ROB_Number) begin
                    Reg_Status1[i]<=`MAXN;
                    Reg_Data1[i]<=Reg_Val;
                end
                if(Reg_Status2[i]==ROB_Number) begin
                    Reg_Status2[i]<=`MAXN;
                    Reg_Data2[i]<=Reg_Val;
                end
                if(ROB_Number_[i]==ROB_Number) begin
                    Commited[i] = `one;
                end
            end
        end
        if(head!=tail) begin
            if(Valid[head]) begin
                if(LSB_en_o) begin
                    head <= head+1;
                    case(OpCode[head])
                    `lb,`lh,`lw,`lbu,`lhu:begin
                        LSB_in <= `one;
                        ROB_Number_LSB <= ROB_Number_[head];
                        data_w_en <= `zero;
                        data_r_en <=`zero;
                        case(OpCode[head]) begin
                        `lb:begin
                            if(LSB_data_o[7])begin
                                Value <={24{1'b1},LSB_data_o[7:0]};
                            end
                            else Value<= LSB_data_o;
                        end
                        `lh:begin
                            if(LSB_data_o[15])begin
                                Value <={16{1'b1},LSB_data_o[15:0]};
                            end
                            else Value<= LSB_data_o;
                        end
                        `lw,`lbu,`lhu:begin
                            Value <= LSB_data_o;
                        end
                        end
                    end
                    default:begin
                        
                    end
                    endcase
                    LSB_is_full <= ((_tail+1)%size==(head+1)%size)||((_tail+2)%size==(head+1)%size);
                end
                else begin
                    LSB_in <= `zero;
                    LSB_is_full <= ((_tail+1)%size==head)||((_tail+2)%size==head);
                end
            end
            else begin
                case(OpCode)
                `lb:begin
                    if(Reg_Status1[head]==`MAXN) begin
                        Valid[head] <= 1;
                        LSB_in <= `zero;
                        data_w_en <=`zero;
                        data_r_en <=`one;
                        data_addr <= Imm[head]+Reg_Data1[head];
                        data_len <= 1;
                    end
                    else begin
                        LSB_in <= `zero;
                        data_w_en <=`zero;
                        data_r_en <=`zero;
                    end
                end
                `lh:begin
                    if(Reg_Status1[head]==`MAXN) begin
                        Valid[head] <= 1;
                        LSB_in <= `zero;
                        data_w_en <=`zero;
                        data_r_en <=`one;
                        data_addr <= Imm[head]+Reg_Data1[head];
                        data_len <= 2;
                    end
                    else begin
                        LSB_in <= `zero;
                        data_w_en <=`zero;
                        data_r_en <=`zero;
                    end
                end
                `lw:begin
                    if(Reg_Status1[head]==`MAXN) begin
                        Valid[head] <= 1;
                        LSB_in <= `zero;
                        data_w_en <=`zero;
                        data_r_en <=`one;
                        data_addr <= Imm[head]+Reg_Data1[head];
                        data_len <= 4;
                    end
                    else begin
                        LSB_in <= `zero;
                        data_w_en <=`zero;
                        data_r_en <=`zero;
                    end
                end
                `lbu:begin
                    if(Reg_Status1[head]==`MAXN) begin
                        Valid[head] <= 1;
                        LSB_in <= `zero;
                        data_w_en <=`zero;
                        data_r_en <=`one;
                        data_addr <= Imm[head]+Reg_Data1[head];
                        data_len <= 1;
                    end
                    else begin
                        LSB_in <= `zero;
                        data_w_en <=`zero;
                        data_r_en <=`zero;
                    end
                end
                `lhu:begin
                    if(Reg_Status1[head]==`MAXN) begin
                        Valid[head] <= 1;
                        LSB_in <= `zero;
                        data_w_en <=`zero;
                        data_r_en <=`one;
                        data_addr <= Imm[head]+Reg_Data1[head];
                        data_len <= 2;
                    end
                    else begin
                        LSB_in <= `zero;
                        data_w_en <=`zero;
                        data_r_en <=`zero;
                    end
                end
                `sb:begin
                    if(Commited[head]) begin
                        Valid[head] <= 1;
                        LSB_in <= `zero;
                        data_w_en <=`one;
                        data_r_en <=`zero;
                        data_addr <= Imm[head]+Reg_Data1[head];
                        data_val <= Reg_Data2[head][7:0];
                        data_len <= 1;
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
                    end
                    else begin
                        LSB_in <= `zero;
                        data_w_en <=`zero;
                        data_r_en <=`zero;
                    end
                end
                endcase


                LSB_is_full <= ((_tail+1)%size==head)||((_tail+2)%size==head);
            end
        end
        else begin
            LSB_in <= `zero;
            data_w_en <=`zero;
            data_r_en <=`zero;
            LSB_is_full <= ((_tail+1)%size==head)||((_tail+2)%size==head);
        end
    end
end
endmodule