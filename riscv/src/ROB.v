`include "def.v"
module ROB (
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,
    output reg clear,
    
    //CDB
    output reg en_commit,
    output reg[`RegAddrSize] ROB_Number,
    output reg[`RegAddrSize] Reg_Number,
    output reg[`InstSize] Reg_Val,
    output reg pc_Change,
    output reg[`InstSize] pc_goal,
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
    input wire[`InstSize] Inst_debug_in,
    output wire[`RegAddrSize] ROB_Number_in,
    //ID
    output reg ROB_is_Full,
    //LSB
    input wire LSB_in,
    input wire[`RegAddrSize] ROB_Number_LSB,
    input wire[`InstSize] Value_LSB,
    output wire[`RegAddrSize] ROB_head
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
reg[`InstSize] _Inst[`InstSize];
reg q_empty,q_full;
assign ROB_Number_in = tail;
assign _tail = (ISSUE_in) ? (tail+1)%SIZE:tail;
wire commit_enable;
assign commit_enable = (!q_empty) &&is_ready[head];
assign ROB_head = head;
always @(posedge clk_in) begin
    // if(pc_Change==1)$display(pc_Change);
    if(rst_in||clear) begin
        head<=0;
        tail<=0;
        q_empty<=`one;
        q_full <=`zero;
        if(clear) begin
            clear <= `zero;
        end
    end
    else if(rdy_in) begin
        //$display("fucl");
        // $display("%h",_Inst[head]);
        // $display(head);
        // $display(tail);
        // if(pc[head]!=4252) begin
            
        // $display("head",head);
        // $display("tail",tail);
        // $display("ROB",ROB_is_Full);
        // $display("pc_head",pc[head]);
        // end
        if(ISSUE_in) begin
            pc[tail]<=pc_in;
            // if(pc_in==4252) begin
            //           $display("Here you are");
            //         end
            // $display("pc:",pc_in);
            OpCode[tail] <= OpCode_in;
            // $display("OpCodeRRRRROB:", OpCode_in);
            // $display("TTTTTTAIl",tail);
            imm[tail] <= imm_in;
            _Inst[tail] <= Inst_debug_in;
            //$display("Imm:",rd_in);
            //$display("imm:",imm_in);
            rd[tail] <=rd_in;
            if(OpCode_in==`sb||OpCode_in==`sh||OpCode_in==`sw) begin
                is_ready[tail] <= `one;
            end
            else begin
                is_ready[tail] <= `zero;
            end
        end
        if(commit_enable) begin
            //$display("fuck");
            head <= (head+1)%SIZE;
            q_empty <= (head+1)%SIZE==_tail;
            q_full <= (((_tail+1)%SIZE==(head+1)%SIZE)||((_tail+2)%SIZE==(head+1)%SIZE)||((_tail+3)%SIZE==(head+1)%SIZE));
            ROB_is_Full <= (((_tail+1)%SIZE==(head+1)%SIZE)||((_tail+2)%SIZE==(head+1)%SIZE)||((_tail+3)%SIZE==(head+1)%SIZE));
            // $display("%h",pc[head]);
            // $display("Head:",head);
            // $display("tail:",tail);
            case(OpCode[head]) 
            `lb,`lh,`lw,`lbu,`lhu,`add,`addi,`sub,`lui,`auipc,`xor,`xori,`or,`ori,`and,`andi,`sll,`slli,`srl,`srli,`sra,`srai,`slt,`slti,`sltu,`sltiu:begin
                en_commit <= `one;
                pc_Change <= `zero;
                ROB_Number <= head;
                Reg_Number <= rd[head];
                Reg_Val <= Val[head];
                // $display("cur_commitNumber:",OpCode[head]);
                // $display(en_commit);
                //  $display("rd[head]",rd[head]);
                //  $display("reg_Val:",Val[head]);

            end
            `beq,`bne,`blt,`bge,`bltu,`bgeu:begin
                en_commit <= `zero;
                // $display(Val[head]);
                if(Val[head]) begin
                    pc_Change <= `one;
                    pc_goal <= pc[head]+imm[head];
                    clear <= `one;
                    
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
                clear <= `one;
                //$display(pc[head]+imm[head]);
            end
            `jalr:begin
                en_commit <= `one;
                pc_Change <= `one;
                ROB_Number <= head;
                Reg_Number <= rd[head];
                Reg_Val <= pc[head]+4;
                pc_goal <= Val[head];
                clear <= `one;
            end
            default : begin
                en_commit <= `one;
                pc_Change <= `zero;
                ROB_Number <= head;
                Reg_Number <= 0;
            end
            endcase
        end
        else begin
            head <= head;
            q_empty <= head==_tail;
            q_full <= (((_tail+1)%SIZE==head)||((_tail+2)%SIZE==head)||((_tail+3)%SIZE==head));
            ROB_is_Full <= (((_tail+1)%SIZE==head)||((_tail+2)%SIZE==head)||((_tail+3)%SIZE==head));
            en_commit <= `zero;
            pc_Change <= `zero; 
        end
        if(ALU_in) begin
            is_ready[ROB_Number_ALU] <= `one;
            //$display(ROB_Number_ALU);
            Val[ROB_Number_ALU] <= Value;
            //$display(Value);
        end
        if(LSB_in) begin
            is_ready[ROB_Number_LSB] <= `one;
            Val[ROB_Number_LSB] <= Value_LSB;
        end
        tail<=_tail;
    end
end
endmodule