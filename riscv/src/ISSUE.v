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
        output wire ROB_o, 
        output wire[`InstSize] pc_o,
        output wire[`OpSize] OpCode_o,
        output wire[`InstSize] imm_o,
        output wire[`RegAddrSize] rd_o,
        input  wire[`RegAddrSize] ROB_Number,
        //REGFile
        input wire [`InstSize] Reg_Status_1,
        input wire [`InstSize] Reg_Data_1,
        input wire [`InstSize] Reg_Status_2,
        input wire [`InstSize] Reg_Data_2,
        output wire Status_Change,
        output wire[`RegAddrSize] register_addr,
        output wire[`InstSize] goal,
        //RS
        output wire RS_o,
        output wire [`RegAddrSize] ROB_Number_o,
        output wire [`OpSize] OpCode_RS,
        output wire [`InstSize] Reg_Status_1_RS,
        output wire [`InstSize] Reg_Data_1_RS,
        output wire [`InstSize] Reg_Status_2_RS,
        output wire [`InstSize] Reg_Data_2_RS,
        //LSB
        output wire LSB_o,
        output wire[`OpSize] OpCode_LSB,
        output wire [`InstSize] Reg_Status_1_LSB,
        output wire [`InstSize] Reg_Data_1_LSB,
        output wire [`InstSize] Reg_Status_2_LSB,
        output wire [`InstSize] Reg_Data_2_LSB,
        output wire [`InstSize] imm_LSB
    );
    always @(*) begin
        if(clear||rst_in||!en_in) begin
            
        end
        else if(rdy_in) begin
            if(!en_in) begin
                ROB_o = `zero;
                Status_change = `zero;
                RS_o = `zero;
                LSB_o = `zero;
            end
            else begin
            ROB_o = `zero;
            Status_change = `zero;
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