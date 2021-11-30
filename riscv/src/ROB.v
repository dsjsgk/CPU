`include "def.v"
module ROB (
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,
    input wire clear,
    
    //CDB
    output wire en_commit,
    output wire[`RegAddrSize] ROB_Number,
    output wire[`RegAddrSize] Reg_Number,
    output wire[`InstSize] Reg_Val,
    output wire pc_Change,
    output wire[`InstSize] pc_goal,
    //ALU
    input wire ALU_in,
    input wire[`RegAddrSize] ROB_Number_ALU,
    input wire[`InstSize] Value,
    //ISSUE
    input wire ISSUE_in,
    input wire[`InstSize] pc_in,
    input wire[`OpSize] OpCode_in,
    input wire[`InstSize] imm_in,
    input wire[`RegAddrSize] rd_in,
    output wire[`RegAddrSize] ROB_Number,
    //ID
    output wire ROB_is_Full,
    //LSB
    input wire LSB_in,
    input wire[`RegAddrSize] ROB_Number_LSB,
    input wire[`InstSize] Value_LSB,
    
);
parameter SIZE = 32;
reg [`InstSize] pc[`InstSize];
reg [`OpSize] OpCode[`InstSize];
reg [`InstSize] imm[`InstSize];
reg [`RegAddrSize] rd[`InstSize];
reg is_ready[`InstSize];
reg [`InstSize] Val[`InstSize];
reg [`InstSize] head,tail; 
wire [`InstSize] _head,_tail;
reg q_empty,q_full;

assign _tail = (Inst_Status_in) ? (tail+1)%SIZE:tail;
wire commit_enable;
assign commit_enable = (!q_empty) &&is_ready[head];
always @(posedge clk_in) begin
    if(rst_in||clear) begin
        head<=0;
        tail<=0;
        q_empty<=`one;
        q_full <=`zero;
    end
    else if(rdy_in) begin
        if(ISSUE_in) begin
            pc[tail]<=pc_in;
            OpCode[tail] <= OpCode_in;
            imm[tail] <= imm_in;
            rd[tail] <=rd_in;
            is_ready[tail] <= `zero;
        end
        
        if(commit_enable) begin
            head <= (head+1)%SIZE;
            q_empty <= (head+1)%SIZE==_tail;
            q_full <= (((_tail+1)%SIZE==(head+1)%SIZE)||(_tail+2)%SIZE==(head+1)%SIZE));
            ROB_is_Full <= (((_tail+1)%SIZE==(head+1)%SIZE)||(_tail+2)%SIZE==(head+1)%SIZE));
            case(OpCode[head]) 
            `lb,`lh,`lw,`lbu,`lhu,`add,`addi,`sub,`lui,`auipc,`xor,`xori,`or,`ori,`and,`andi,`sll,`slli,`srl,`srli,`sra,`srai,`slt,`slti,`sltu,`sltiu:begin
                en_commit <= `one;
                pc_Change <= `zero;
                ROB_Number <= head;
                Reg_Number <= rd[head];
                Reg_Val <= Val[head];
            end
            `beq,`bne,`blt,`bge,`bltu,`bgeu:begin
                en_commit <= `zero;
                if(Val[head]) begin
                    pc_Change <= `one;
                    pc_goal <= pc[head]+imm[head];
                end
                else begin
                    pc_Change <= `zero;
                    //pc_goal <= pc[head]+imm[head];
                end
            end
            `jal:begin
                en_commit <= `one;
                pc_Change <= `one;
                ROB_Number <= head;
                Reg_Number <= rd[head];
                Reg_Val <= Val[head];
                pc_goal <= pc[head]+imm[head];
            end
            `jalr:begin
                en_commit <= `one;
                pc_Change <= `one;
                ROB_Number <= head;
                Reg_Number <= rd[head];
                Reg_Val <= pc[head]+4;
                pc_goal <= Val[head];
            end
            default : begin
                en_commit <= `zero;
                pc_Change <= `zero;
            end
            endcase
        end
        else begin
            
            head <= (head)%SIZE;
            q_empty <= (head)%SIZE==_tail;
            q_full <= (((_tail+1)%SIZE==(head)%SIZE)||(_tail+2)%SIZE==(head)%SIZE));
            ROB_is_Full <= (((_tail+1)%SIZE==(head)%SIZE)||(_tail+2)%SIZE==(head)%SIZE));
            en_commit <= `zero;
            pc_Change <= `zero; 
        end
        if(ALU_in) begin
            is_ready[ROB_Number_ALU] <= `one;
            Val[ROB_Number_ALU] <= Value;
        end
        if(LSB_in) begin
            is_ready[ROB_Number_LSB] <= `one;
            Val[ROB_Number_LSB] <= Value;
        end

    end
end 
endmodule