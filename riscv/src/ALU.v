`include "def.v"
module ALU(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,
    input wire clear,
    input wire status,
    input wire[`OpSize] OpCode,
    input wire[`REGSize] rs1,
    //register 1
    input wire[`REGSize] rs2,
    input wire[`RegAddrSize] ROB_Number,
    //transfer to ROB
    output reg to_ROB_Status,
    output reg[`RegAddrSize] ROB_Number_o,
    output reg[`REGSize] val
);integer i ;
reg temp;
always @(*) begin
    if(rst_in||clear||!status) begin
        to_ROB_Status <= `zero;
    end
    else if(rdy_in) begin
        to_ROB_Status = `one;
        ROB_Number_o  = ROB_Number;
        case(OpCode) 
        `add,`addi,`lui,`auipc,`jal,`jalr: val = rs1+rs2;
        `sub : val = rs1-rs2;
        `xor,`xori : val = rs1^rs2;
        `or,`ori : val = rs1|rs2;
        `and,`andi : val = rs1&rs2;
        `sll,`slli : val = rs1<<rs2[4:0];
        `srl,`srli : val = rs1>>rs2[4:0];
        `sra,`srai : begin
            temp = rs1[31];
            val = rs1>>rs2[4:0];
            
            for(i=32-rs2[4:0];i<32;++i) begin
                val = val | (temp<<i);
            end
        end
        `slt,`slti : val = $signed(rs1) < $signed(rs2) ;
        `sltu,`sltiu : val = $unsigned(rs1) <$unsigned(rs2);
        `beq : val=$signed(rs1)==$signed(rs2);
        `bne : val=$signed(rs1)!=$signed(rs2);
        `blt : val=$signed(rs1)<$signed(rs2);
        `bge : val=$signed(rs1)>=$signed(rs2);
        `bltu : val=rs1<rs2;
        `bgeu : val=rs1>=rs2;
        endcase
    end
end
endmodule;