`include "def.v"
module ID(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,
    input wire clear,
    //IQ
    input wire[`InstSize] Inst_in,
    input wire[`InstSize] pc_in,
    input wire en_in,
    input wire IQ_isempty,
    output reg Get_Inst,
    //ISSUE
    output reg en_out,
    output reg [`OpSize] OpCode,
    output reg [`RegAddrSize] rs1,
    output reg [`RegAddrSize] rs2,
    output reg [`InstSize] imm,
    output reg [`RegAddrSize] rd,
    output reg [`InstSize] pc,

    //ROB
    input wire ROB_isfull,
    //RS
    input wire RS_isfull,
    //LSB
    input wire LSB_isfull,
    //REGFile
    output reg en_1,
    output reg[`RegAddrSize] Addr_1,
    output reg en_2,
    output reg[`RegAddrSize] Addr_2
);  integer i;
always @(posedge clk_in) begin
    if(ROB_isfull||RS_isfull||LSB_isfull||IQ_isempty||!en_in||clear||rst_in) begin
        en_1 <= `zero;
        en_2 <= `zero;
        Get_Inst <=`zero;
        en_out <= `zero;

    end 
    else begin
        en_out<=`one;
        pc <= pc_in;
        case(Inst_in[6:0]) 
            7'b0000011: begin
                case(Inst_in[14:12]) 
                3'b000 : OpCode <= `lb;
                3'b001 : OpCode <= `lh;
                3'b010 : OpCode <= `lw;
                3'b100 : OpCode <= `lbu;
                3'b101 : OpCode <= `lhu;
                endcase
                rd <= Inst_in[11:7];
                rs1 <= Inst_in[19:15];
                imm <= Inst_in[31:20];//?
                if(Inst_in[31]) begin
                    
                    for(i=12;i<32;++i) imm|=(1<<i);
                end
                en_1 <= `one;
                en_2 <= `zero;
                Addr_1 <= rs1;
            end
            7'b0100011: begin
                case(Inst_in[14:12]) 
                3'b000 : OpCode <= `sb;
                3'b001 : OpCode <= `sh;
                3'b010 : OpCode <= `sw;
                endcase
                rs1 <= Inst_in[19:15];
                rs2 <= Inst_in[24:20];
                imm <= Inst_in[11:7]+Inst_in[31:25]<<5;
                if(Inst_in[31]) begin
                    for(i=12;i<32;++i) imm|=(1<<i);
                end
                en_1 <= `one;
                en_2 <= `one;
                Addr_1 <= rs1;
                Addr_2 <= rs2;
            end
            7'b0110011: begin
                case(Inst_in[14:12])
                3'b000 : begin
                    if(Inst_in[31:25]==7'b0) begin
                        OpCode <= `add;
                    end
                    if(Inst_in[31:25]==7'b0100000) begin
                        OpCode <= `sub;
                    end
                end
                3'b100 : begin
                    OpCode <= `xor;
                end
                3'b110 : begin
                    OpCode <= `or;
                end
                3'b111 :begin
                    OpCode <= `and;
                end
                3'b001 :begin
                    OpCode <= `sll;
                end
                3'b101 :begin
                    if(Inst_in[31:25]==7'b0) begin
                        OpCode <= `srl;
                    end
                    if(Inst_in[31:25]==7'b0100000) begin
                        OpCode <= `sra;
                    end
                end
                3'b010 : begin
                    OpCode <= `slt;
                end
                3'b011 : begin
                    OpCode <= `sltu;
                end
                
                endcase
                rs1 <= Inst_in[19:15];
                rs2 <= Inst_in[24:20];
                rd  <= Inst_in[11:7];
                en_1 <= `one;
                en_2 <= `one;
                Addr_1 <= rs1;
                Addr_2 <= rs2;
            end
            7'b0010011: begin
                case(Inst_in[14:12])
                3'b000 : OpCode <= `addi;
                3'b100 : OpCode <= `xori;
                3'b110 : OpCode <= `ori;
                3'b111 : OpCode <= `andi;
                3'b001 : OpCode <= `slli; 
                3'b101 :begin
                    if(Inst_in[31:26]==6'b0) begin
                        OpCode <= `srli;
                    end
                    if(Inst_in[31:26]==6'b010000) begin
                        OpCode <= `srai;
                    end
                end
                3'b010 : begin
                    OpCode <= `slti;
                end
                3'b011 : begin
                    OpCode <= `sltiu;
                end
                
                endcase
                
                rs1 <= Inst_in[19:15];
                rd  <= Inst_in[11:7];
                imm <= Inst_in[31:20];//?
                if(Inst_in[31]) begin
                    for(i=12;i<32;++i) imm|=(1<<i);
                end
                en_1 <= `one;
                en_2 <= `zero;
                Addr_1 <= rs1;
                Addr_2 <= rs2;
            end
            7'b0110111: begin
                OpCode <= `lui;
                rd <= Inst_in[11:7];
                imm <= Inst_in[31:12]<<12;   
                en_1 <= `zero;
                en_2 <= `zero;
            end 
            7'b0010111:begin
                OpCode <= `auipc;
                rd <= Inst_in[11:7];
                imm <= Inst_in[31:12]<<12;   
                en_1 <= `zero;
                en_2 <= `zero;
            end
            7'b1100011:begin
                case(Inst_in[14:12])
                3'b000: begin
                    OpCode<=`beq;
                end
                3'b001: begin
                    OpCode<=`bne;
                end
                3'b100: begin
                    OpCode<=`blt;
                end
                3'b101: begin
                    OpCode<=`bge;
                end
                3'b110: begin
                    OpCode<=`bltu;
                end
                3'b111: begin
                    OpCode<=`bgeu;
                end
                endcase
                rs1 <= Inst_in[19:15];
                rs2 <= Inst_in[24:20];
                imm <= Inst_in[11:7]+Inst_in[31:25]<<5;
                if(Inst_in[31]) begin
                    for(i=12;i<32;++i) imm|=(1<<i);
                end
                en_1 <= `one;
                en_2 <= `one;
                Addr_1 <= rs1;
                Addr_2 <= rs2;
            end
            7'b1101111:begin
                OpCode <= `jal;
                rd <= Inst_in[11:7];
                imm <= Inst_in[31:12];
                if(Inst_in[31]) begin
                    for(i=20;i<32;++i) imm|=(1<<i);
                end
                en_1 <= `zero;
                en_2 <= `zero;
            end
            7'b1100111:begin
                OpCode <= `jalr;
                rd <= Inst_in[11:7];
                rs1 <= Inst_in[19:15];
                imm <= Inst_in[31:20];
                if(Inst_in[31]) begin
                    for(i=12;i<32;++i) imm|=(1<<i);
                end
                en_1 <= `one;
                en_2 <= `zero;
                Addr_1 <= rs1;
            end
        endcase
    end
end
endmodule;