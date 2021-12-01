`include "def.v"
module MemCtrl
(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,
    input wire clear,
    //FROM LSB
    input wire data_w_en,
    input wire[`InstSize] data_addr,
    input wire[`InstSize] data_val,
    input wire data_r_en,
    input wire[`InstSize] data_len,
    output wire LSB_en_o,
    output wire[`InstSize] LSB_data_o,
   //FROM ICaChe
    input wire ICache_en_i,
    input wire[`InstSize] ICache_Addr,
    output wire ICache_en_o,
    output wire[`InstSize] ICache_Data,
    //From Ram
    input wire [`MemSize] ram_in,
    output wire mem_wr_o,
    output wire[`InstSize] mem_addr,
    output wire[`MemSize] mem_wr_data
);
reg[1:0] Cur_Status;
reg[5:0] Cur_Cycle;
reg[`InstSize] Val; 
always @(posedge clk_in) begin
    if(rst_in||clear) begin
        mem_wr_o <= `zero;
        ICache_en_o <= `zero;
        Val <= 0;
        LSB_en_o <= `zero;
        Cur_Status <= `Off;
        Cur_Cycle <= 0;
    end
    else if(rdy_in) begin
        case(Cur_Status) 
            `Off: begin
                if(data_w_en) begin
                    Cur_Status <= `Reading_Data;
                    mem_wr_o <= 1;
                    mem_addr <= data_addr;
                    mem_wr_data <= data_val[7:0];
                end
                else if(data_r_en) begin
                    Cur_Status <= `Reading_Data;
                    mem_wr_o <= 0;
                    mem_addr <= data_addr;
                end
                else if(ICache_en_i) begin
                    Cur_Status <= `Getting_Inst;
                    mem_wr_o <= 0;
                    mem_addr <= ICache_Addr;
                end
                Cur_Cycle <= 0;
                Val <= 0;
                ICache_en_o <= 0;
                LSB_en_o <= 0;
            end
            `Reading_Data:begin
                case(Cur_Cycle) 
                `0:begin
                    Cur_Cycle <= Cur_Cycle+1;
                    mem_addr <= mem_addr+1;
                end
                `1:begin
                    if(data_len == 1) begin
                        Cur_Cycle <= 0;
                        Cur_Status <= `Off;
                        LSB_en_o <= 1;
                        LSB_data_o <= ram_in;
                        Val<=0;
                    end
                    else begin
                        Cur_Cycle <= Cur_Cycle+1;
                        Val[7:0] <= ram_in;
                        mem_addr <= mem_addr+1;
                    end
                end
                `2:begin
                    if(data_len == 2) begin
                        Cur_Cycle <= 0;
                        Cur_Status <= `Off;
                        LSB_en_o <= 1;
                        LSB_data_o <= {ram_in,Val[7:0]};
                        Val<=0; 
                    end
                    else begin
                        Cur_Cycle <= Cur_Cycle+1;
                        Val[15:8] <= ram_in;
                        mem_addr <= mem_addr+1;
                    end
                end
                `3:begin
                    Cur_Cycle <= Cur_Cycle+1;
                    Val[23:16] <= ram_in;
                end
                `4:begin
                    Cur_Cycle <= 0;
                    Cur_Status <= `Off;
                    LSB_en_o <= 1;
                    LSB_data_o <= {ram_in,Val[23:0]};
                    Val<=0; 
                end
                endcase
            end
            `Getting_Inst:begin
                case(Cur_Cycle) 
                `0:begin
                    Cur_Cycle <= Cur_Cycle+1;
                    mem_addr <= mem_addr+1;
                end
                `1:begin
                    Cur_Cycle <= Cur_Cycle+1;
                    Val[7:0] <= ram_in;
                    mem_addr <= mem_addr+1;
                end
                `2:begin
                    Cur_Cycle <= Cur_Cycle+1;
                    Val[15:8] <= ram_in;
                    mem_addr <= mem_addr+1;
                end
                `3:begin
                    Cur_Cycle <= Cur_Cycle+1;
                    Val[23:16] <= ram_in;
                end
                `4:begin
                    Cur_Cycle <= 0;
                    Cur_Status <= `Off;
                    ICache_en_o <= 1;
                    ICache_Data <= {ram_in,Val[23:0]};
                    Val[31:24] <= ram_in;
                end
                endcase
            end
            `Writing_Data:begin
                case(Cur_Cycle) 
                `0:begin
                    if(data_len == 1) begin
                        Cur_Cycle <= 0;
                        Cur_Status <= `Off;
                        LSB_en_o <= 1;
                        mem_wr_o <= 0;
                        Val<=0;
                    end
                    else begin
                        Cur_Cycle <= Cur_Cycle+1;
                        mem_addr <= mem_addr+1;
                        mem_wr_data = data_val[15:8];
                    end
                end
                `1:begin
                    if(data_len == 2) begin
                        Cur_Cycle <= 0;
                        Cur_Status <= `Off;
                        LSB_en_o <= 1;
                        mem_wr_o <= 0;
                        Val<=0;
                    end
                    else begin
                        Cur_Cycle <= Cur_Cycle+1;
                        mem_addr <= mem_addr+1;
                        mem_wr_data = data_val[23:16];
                    end
                end
                `2:begin
                    Cur_Cycle <= Cur_Cycle+1;
                    Val[31:24] <= ram_in;
                    mem_addr <= mem_addr+1;
                end
                `3:begin
                    Cur_Cycle <= 0;
                    Cur_Status <= `Off;
                    LSB_en_o <= 1;
                    mem_wr_o <= 0;
                    Val<=0;
                end
                endcase
            end
        endcase
    end
end
endmodule