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
always @(posedge clk_in) begin
    if(rst_in||clear) begin
        to_ROB_Status = `zero;
    end
end
always @(*) begin
    if(rst_in||clear) begin
        to_ROB_Status = `zero;
    end
    else if(rdy_in) begin
        if(status==`one) begin
        to_ROB_Status = `one;
        //$display(status);
        ROB_Number_o  = ROB_Number;
        //$display(ROB_Number);
        case(OpCode) 
        `add,`addi,`lui,`auipc,`jal,`jalr: val = rs1+rs2;
        `sub : val = rs1-rs2;
        `xor,`xori : val = rs1^rs2;
        `or,`ori : val = rs1|rs2;
        `and,`andi : val = rs1&rs2;
        `sll,`slli : val = rs1<<rs2[4:0];
        `srl,`srli : val = rs1>>rs2[4:0];
        `sra,`srai : begin
            // $finish;
            temp = rs1[31];
            val = rs1>>rs2[4:0];
            
            for(i=32-rs2[4:0];i<32;++i) begin
                val = val | (temp<<i);
            end
        end
        `slt,`slti : val = $signed(rs1) < $signed(rs2) ;
        `sltu,`sltiu : val = rs1 <rs2;
        `beq : val=rs1==rs2;
        `bne : val=rs1!=rs2;
        `blt : val=$signed(rs1)<$signed(rs2);
        `bge : val=$signed(rs1)>=$signed(rs2);
        `bltu : begin 
            val=rs1<rs2;
            // $display("rs1:",rs1);
            // $display("rs2:",rs2);
            // $display("fuckccckc");
        end
        `bgeu : val=rs1>=rs2;
        endcase
        //$display(val);
        end
        else begin
            to_ROB_Status = `zero;
        end
    end
end
endmodule;