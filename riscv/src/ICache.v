`include "def.v"
module ICache (
    input wire clk_in,
    input wire rdy_in,
    input wire rst_in,
    input wire clear,
    //With IF
    input wire en_i_IF, 
    input wire[`InstSize] IF_addr,
    output reg en_o_IF,
    output reg[`InstSize] Inst_data,
    //With MemCtrl
    input wire data_en_i,
    input wire[`InstSize] data_i,
    output reg data_get_en,
    output reg[`InstSize] data_get_addr
);
reg Status[511:0];
reg[`InstSize] data[511:0];
reg[`InstSize] Addr[511:0];integer i;
always @(posedge clk_in) begin
    if(rst_in) begin
        for(i=0;i<512;++i) Status[i]<=`zero;
    end
    else if(rdy_in&&data_en_i) begin
        Status[IF_addr[`CacheBus]] <= `one;
        data[IF_addr[`CacheBus]] <= data_i;
        Addr[IF_addr[`CacheBus]] <= IF_addr;
    end
end
always @(*) begin 
    if(rst_in||clear)begin
        data_get_en = `zero;
        en_o_IF = `zero;
    end
    else if(rdy_in&&en_i_IF) begin
        if(Status[IF_addr[`CacheBus]]&&Addr[IF_addr[`CacheBus]]==IF_addr) begin
            en_o_IF = `one;
            Inst_data = data[IF_addr[`CacheBus]];
            data_get_en = `zero;
        end
        else if (data_en_i) begin
            Inst_data = data_i;
            en_o_IF = `one;
            data_get_en  = `zero;
        end
        else begin
            en_o_IF = `zero;
            data_get_en  = `one;
            data_get_addr = IF_addr;
        end
    end
    else begin
        data_get_en =`zero;
        en_o_IF = `zero;
    end
end
endmodule