module IF(
    input wire clk_in;
    input wire rst_in;
    input wire rdy_in;

    input wire IQ_isfull,

    //IQ
    input wire wr_en,
    output wire Inst_Status_out,
    output  wire[`InstSize] Inst_out ,
    output  wire[`REGSize] pc_out ,

    //ROB
    input  wire commit_en,
    input  wire[`InstSize] goal;

    // input  wire

    //ICache
    input wire Inst_Status_in,
    input wire[`InstSize] Inst_in,
    output wire[`InstSize] Addr,
    output wire Inst_en,
);
reg[`InstSize] cur_pc,next_pc;
always @(posedge clk_in) begin
    if(rst_in) begin
        pc <= 0;
        next_pc <= 4;
    end
    else begin
        if(commit_en==one) begin
            pc <= goal;
            npc <= goal + 4;
            Addr <= goal;
            Inst_en <= one; 
            Inst_Status_out <= zero;
        end
        else begin
            if(IQ_isfull!=one && Inst_Status_in == one) begin
                Inst_out <= Inst_in;
                pc_out <= cur_pc;
                cur_pc <= next_pc;
                next_pc <= next_pc+4;
                Inst_Status_out <= one;
                Addr <= next_pc;
                Inst_en <= one;
            end
            else begin
                Addr <= cur_pc;
                Inst_en <= one;
                Inst_Status_out <= zero;
            end
        end
    end
end

endmodule;