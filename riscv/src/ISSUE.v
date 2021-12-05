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
        //ROB
        output reg ROB_o, 
        output reg[`InstSize] pc_o,
        output reg[`OpSize] OpCode_o,
        output reg[`InstSize] imm_o,
        output reg[`RegAddrSize] rd_o,
        input  wire[`RegAddrSize] ROB_Number,
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
        if(clear||rst_in||!en_in) begin
            ROB_o = `zero;
            Status_Change = `zero;
            RS_o = `zero;
            LSB_o = `zero;
        end
        else if(rdy_in) begin
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
            case(OpCode)
                `lb,`lh,`lw,`lbu,`lhu:begin
                    OpCode_o = OpCode;
                    ROB_o = `one; 
                    LSB_o = `one;
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
                    Reg_Status_2_LSB = `MAXN;
                    Reg_Data_2_LSB = imm;
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
                    // imm_LSB = imm;
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
                end
                `lui:begin
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
                    Reg_Data_1_RS = 0;
                    Reg_Status_2_RS = `MAXN;
                    Reg_Data_2_RS = imm;
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
                end
            endcase
            end
        end
    end
    endmodule