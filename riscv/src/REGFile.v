`include "def.v"

module REGFile (
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,
    //FROM COMMIT
    input wire clear,

    //FROM ISSUE
    input wire Status_Change_1,
    input wire[`RegAddrSize] register_addr_1,
    input wire[`InstSize] goal_1,

    //FROM COMMIT
    input wire Status_Change_2,
    input wire[`RegAddrSize] register_addr_2,
    input wire[`InstSize] goal_2,
    input wire[`RegAddrSize] Number,

    //GET DATA
    input wire en_in_1,
    input wire en_in_2,
    input wire [`RegAddrSize] register_addr_1_out,
    input wire [`RegAddrSize] register_addr_2_out,
    output reg[`InstSize] Status_1,
    output reg[`InstSize] Status_2,
    output reg[`InstSize] data_1,
    output reg[`InstSize] data_2
);
reg[`InstSize] register_data[`InstSize];
reg[`InstSize] register_status[`InstSize];
parameter MAXN = 32'd1000;
integer i;
initial begin
    for(i=0;i<32;++i) begin
        register_data[i]=0;
        register_status[i]=MAXN;
    end
end
always @(posedge clk_in) begin
    if(rst_in==`one||clear==`one) begin
        for(i=0;i<32;++i) begin
            register_status[i] <= `MAXN;
        end
    end
    else if(rdy_in) begin
        if(Status_Change_1==`one) begin
            register_data[register_addr_1] <= goal_1;
        end
        if(clear==`one||rst_in==`one) begin
            for(i=0;i<32;++i) begin
                register_status[i]<=MAXN;
            end
        end
        if(Status_Change_2==`one) begin
            if(Number==register_status[register_addr_2]) begin
                register_data[register_addr_2] <= goal_2;
                register_status[register_addr_2] <= MAXN;
            end
            else begin
                register_data[register_addr_2] <= goal_2;
            end
        end
    end
end
always @(*) begin
    if(en_in_1==`one) begin
        //en_out_1=`one;
        Status_1=register_status[register_addr_1_out];
        data_1=register_data[register_addr_1_out];
    end
    else begin
        //en_out_1=`zero;
    end
    if(en_in_2==`one) begin
        //en_out_2=`one;
        Status_2=register_status[register_addr_2_out];
        data_2=register_data[register_addr_2_out];
    end
    else begin
        //en_out_2=`zero;
    end
end
endmodule