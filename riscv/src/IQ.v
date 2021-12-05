`include "def.v"

module IQ (
    input  wire                 clk_in,
    input  wire                 rst_in,		
	input  wire					rdy_in,
    input  wire                 clear,
    //wires from IF
    input  wire Inst_Status_in ,
    input  wire[`InstSize] Inst_in ,
    input  wire[`REGSize] pc_in ,
    output reg wr_en ,
    //wires from ID
    input wire Inst_Status_out ,
    output reg[`InstSize] Inst_out ,
    output reg[`REGSize] pc_out ,
    output reg valid ,
    output reg rd_en
);
parameter SIZE = 32;
reg [`InstSize] head,tail;
wire [`InstSize] _head,_tail;

reg[`InstSize] Inst_Queue[`InstSize];
reg[`InstSize] pc_Queue[`InstSize];
reg q_empty,q_full;
always @(posedge clk_in) begin
    if(rst_in||clear) begin
        head <=0;
        tail <=0;
        q_empty <= `one;
        q_full <= `zero;
        valid <= `zero;
        rd_en <= `zero;
        wr_en <= `one;
    end
    else if(rdy_in) begin
        if(q_empty==`zero) begin 
            q_empty <= (_head==_tail);
            q_full  <= (((_head+1)%SIZE==_tail)||((_head+2)%SIZE==_tail));
            wr_en   <= !(((_head+1)%SIZE==_tail)||((_head+2)%SIZE==_tail));
            rd_en   <= !(_head==_tail);
        end
        else begin
            q_empty <= (head==_tail);
            q_full  <= (((head+1)%SIZE==_tail)||((head+2)%SIZE==_tail));
            wr_en   <= !(((head+1)%SIZE==_tail)||((head+2)%SIZE==_tail));
            rd_en   <= !(head==_tail);
        end
        
        if(Inst_Status_in) begin
            Inst_Queue[tail] <= Inst_in;
            pc_Queue[tail] <= pc_in;
        end 
        if(Inst_Status_out&&!q_empty) begin
            valid <= `one;
            Inst_out <= Inst_Queue[head];
            pc_out <= pc_Queue[head];
        end
        else begin
            valid <= `zero;
        end
        tail<=_tail;
        if(q_empty==`zero) begin 
            head<=head;
        end
        else begin
            head=_head;
        end
    end
end

assign _tail = (Inst_Status_in) ? (tail+1)%SIZE:tail;
assign _head = (Inst_Status_out)  ? (head + 1)%SIZE : head;
endmodule