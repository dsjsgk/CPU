`include "def.v"
module IF(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,
    input wire clear,
    input wire IQ_isfull,

    //IQ
    output reg Inst_Status_out,
    output  reg[`InstSize] Inst_out ,
    output  reg[`REGSize] pc_out ,

    //ROB
    input  wire commit_en,
    input  wire[`InstSize] goal,

    // input  wire

    //ICache
    input wire Inst_Status_in,
    input wire[`InstSize] Inst_in,
    output reg[`InstSize] Addr,
    output reg Inst_en
);
reg[`InstSize] cur_pc,next_pc;
always @(posedge clk_in) begin
    if(rst_in) begin
        cur_pc <= 0;
        next_pc <= 4;
        Inst_Status_out <= `zero;
        Inst_en <= `zero;
    end
    else if(clear) begin
        cur_pc <= goal;
        next_pc <= goal+4;
        Inst_Status_out <= `zero;
        Inst_en <= `zero;
    end
    else if(rdy_in)begin
            if(IQ_isfull!=`one && Inst_Status_in == `one) begin
                Inst_out <= Inst_in;
                pc_out <= cur_pc;
                cur_pc <= next_pc;
                next_pc <= next_pc+4;
                Inst_Status_out <= `one;
                Addr <= next_pc;
                Inst_en <= `zero;
            end
            else if(IQ_isfull==`one) begin
                Addr <= cur_pc;
                Inst_en <= `zero;
                Inst_Status_out <= `zero;
            end
            else begin
                Addr <= cur_pc;
                Inst_en <= `one;
                Inst_Status_out <= `zero;
            end
    end
end

endmodule;