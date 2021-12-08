    `include "def.v"
    module ISSUE (
        input wire clk_in,
        input wire rst_in,
        input wire rdy_in,
        input wire clear,
        //Wires from ID
        input wire en_in,
        input wire [`OpSize] OpCode,
        input wire [`RegAddrSize] rs1,
        input wire [`RegAddrSize] rs2,
        input wire [`InstSize] imm,
        input wire [`RegAddrSize] rd,
        input wire [`InstSize] pc,
        input wire [`InstSize] Inst_debug_in,
        //ROB
        output reg ROB_o, 
        output reg[`InstSize] pc_o,
        output reg[`OpSize] OpCode_o,
        output reg[`InstSize] imm_o,
        output reg[`RegAddrSize] rd_o,
        input  wire[`RegAddrSize] ROB_Number,
        output reg [`InstSize] Inst_debug_out,
        //REGFile
        input wire [`InstSize] Reg_Status_1,
        input wire [`InstSize] Reg_Data_1,
        input wire [`InstSize] Reg_Status_2,
        input wire [`InstSize] Reg_Data_2,
        output reg Status_Change,
        output reg[`RegAddrSize] register_addr,
        output reg[`InstSize] goal,
        //RS
        output reg RS_o,
        output reg [`RegAddrSize] ROB_Number_o,
        output reg [`OpSize] OpCode_RS,
        output reg [`InstSize] Reg_Status_1_RS,
        output reg [`InstSize] Reg_Data_1_RS,
        output reg [`InstSize] Reg_Status_2_RS,
        output reg [`InstSize] Reg_Data_2_RS,
        //LSB
        output reg LSB_o,
        output reg[`OpSize] OpCode_LSB,
        output reg [`InstSize] Reg_Status_1_LSB,
        output reg [`InstSize] Reg_Data_1_LSB,
        output reg [`InstSize] Reg_Status_2_LSB,
        output reg [`InstSize] Reg_Data_2_LSB,
        output reg [`InstSize] imm_LSB,
        output reg [`RegAddrSize] ROB_NumbertoLSB
    );
    always @(*) begin
        if(clear||rst_in||en_in!=`one) begin
            ROB_o = `zero;
            Status_Change = `zero;
            RS_o = `zero;
            LSB_o = `zero;
        end
        else if(rdy_in) begin
            //$display(ROB_Number);
            
            if(!en_in) begin
                ROB_o = `zero;
                Status_Change = `zero;
                RS_o = `zero;
                LSB_o = `zero;
            end
            else begin
            ROB_o = `zero;
            Status_Change = `zero;
            RS_o = `zero;
            LSB_o = `zero;
            Inst_debug_out = Inst_debug_in;
            
            case(OpCode)
                `lb,`lh,`lw,`lbu,`lhu:begin
                    OpCode_o = OpCode;
                    ROB_o = `one; 
                    LSB_o = `one;
                    // if(pc==4252) begin
                    //   $display("Here you are");
                    // end
                    pc_o = pc;
                    rd_o = rd;
                    imm_o = imm;
                    Status_Change = `one;
                    register_addr = rd;
                    goal = ROB_Number;
                    OpCode_LSB = OpCode;
                    Reg_Status_1_LSB = Reg_Status_1;
                    Reg_Data_1_LSB = Reg_Data_1;
                    Reg_Status_2_LSB = Reg_Status_2;
                    Reg_Data_2_LSB = Reg_Data_2;
                    imm_LSB = imm;
                    ROB_NumbertoLSB = ROB_Number;
                end
                `sb,`sh,`sw:begin
                    OpCode_o = OpCode;
                    ROB_o = `one; 
                    LSB_o = `one;
                    pc_o = pc;
                    rd_o = rd;
                    imm_o = imm;
                    OpCode_LSB = OpCode;
                    Reg_Status_1_LSB = Reg_Status_1;
                    Reg_Data_1_LSB = Reg_Data_1;
                    Reg_Status_2_LSB = Reg_Status_2;
                    Reg_Data_2_LSB = Reg_Data_2;
                    imm_LSB = imm;
                    ROB_NumbertoLSB = ROB_Number;
                end
                `add,`sub,`slt,`sltu,`xor,`or,`and,`sll,`srl,`sra: begin
                    OpCode_o = OpCode;
                    ROB_o = `one; 
                    RS_o = `one;
                    pc_o = pc;
                    rd_o = rd;
                    imm_o = imm;
                    Status_Change = `one;
                    register_addr = rd;
                    goal = ROB_Number;
                    OpCode_RS= OpCode;
                    Reg_Status_1_RS = Reg_Status_1;
                    Reg_Data_1_RS = Reg_Data_1;
                    Reg_Status_2_RS = Reg_Status_2;
                    Reg_Data_2_RS = Reg_Data_2;
                    ROB_Number_o = ROB_Number;
                end
                `addi,`slti,`sltiu,`xori,`ori,`andi,`slli,`srli,`srai:begin
                    OpCode_o = OpCode;
                    ROB_o = `one; 
                    RS_o = `one;
                    pc_o = pc;
                    rd_o = rd;
                    imm_o = imm;
                    OpCode_RS= OpCode;
                    Status_Change = `one;
                    register_addr = rd;
                    goal = ROB_Number;
                    Reg_Status_1_RS = Reg_Status_1;
                    Reg_Data_1_RS = Reg_Data_1;
                    Reg_Status_2_RS = `MAXN;
                    Reg_Data_2_RS = imm;
                    ROB_Number_o = ROB_Number;
                end
                `beq,`bne,`blt,`bge,`bltu,`bgeu:begin
                    OpCode_o = OpCode;
                    ROB_o = `one;
                    RS_o = `one;
                    pc_o = pc;
                    rd_o = rd;
                    imm_o = imm;
                    OpCode_RS= OpCode;
                    Reg_Status_1_RS = Reg_Status_1;
                    Reg_Data_1_RS = Reg_Data_1;
                    Reg_Status_2_RS = Reg_Status_2;
                    Reg_Data_2_RS = Reg_Data_2;
                    ROB_Number_o = ROB_Number;
                end
                `jal:begin
                    OpCode_o = OpCode;
                    ROB_o = `one;
                    RS_o = `one;
                    pc_o = pc;
                    rd_o = rd;
                    imm_o = imm;
                    Status_Change = `one;
                    register_addr = rd;
                    goal = ROB_Number;
                    OpCode_RS= OpCode;
                    Reg_Status_1_RS = `MAXN;
                    Reg_Data_1_RS = pc;
                    Reg_Status_2_RS = `MAXN;
                    Reg_Data_2_RS = 32'd4;
                    ROB_Number_o = ROB_Number;
                end
                `jalr:begin
                    OpCode_o = OpCode;
                    ROB_o = `one; 
                    RS_o = `one;
                    pc_o = pc;
                    rd_o = rd;
                    imm_o = imm;
                    OpCode_RS= OpCode;
                    Status_Change = `one;
                    register_addr = rd;
                    goal = ROB_Number;
                    Reg_Status_1_RS = Reg_Status_1;
                    Reg_Data_1_RS = Reg_Data_1;
                    Reg_Status_2_RS = `MAXN;
                    Reg_Data_2_RS = imm;
                    ROB_Number_o = ROB_Number;
                end
                `lui:begin
                    //$display(imm);
                    //$display(rd);
                    OpCode_o = OpCode;
                    ROB_o = `one; 
                    RS_o = `one;
                    pc_o = pc;
                    rd_o = rd;
                    imm_o = imm;
                    OpCode_RS= OpCode;
                    Status_Change = `one;
                    register_addr = rd;
                    goal = ROB_Number;
                    //$display(ROB_Number);
                    Reg_Status_1_RS = `MAXN;
                    Reg_Data_1_RS = 0;
                    Reg_Status_2_RS = `MAXN;
                    Reg_Data_2_RS = imm;
                    ROB_Number_o = ROB_Number;
                end
                `auipc:begin
                    OpCode_o = OpCode;
                    ROB_o = `one; 
                    RS_o = `one;
                    pc_o = pc;
                    rd_o = rd;
                    imm_o = imm;
                    OpCode_RS= OpCode;
                    Status_Change = `one;
                    register_addr = rd;
                    goal = ROB_Number;
                    Reg_Status_1_RS = `MAXN;
                    Reg_Data_1_RS = pc;
                    Reg_Status_2_RS = `MAXN;
                    Reg_Data_2_RS = imm;
                    ROB_Number_o = ROB_Number;
                end
            endcase
            end
            // $display(en_in);
        end
    end
    endmodule