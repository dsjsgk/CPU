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



reg q_empty;



always @(posedge clk_in) begin



    if(rst_in||clear) begin



        head <=0;



        tail <=0;



        q_empty <= `one;



//        q_full <= `zero;



        valid <= `zero;



        rd_en <= `one;



        wr_en <= `zero;



    end



    else if(rdy_in) begin



        //if(Inst_Status_in) $display("%h",Inst_in);



        // $display(q_full);



        if(q_empty==`zero) begin 



            q_empty <= (_head==_tail);



//            q_full  <= (((_tail+1)%SIZE==_head)||((_tail+2)%SIZE==_head));



            wr_en   <= (((_tail+1)%SIZE==_head)||((_tail+2)%SIZE==_head)||((_tail+3)%SIZE==_head));



            rd_en   <= (_head==_tail);



        end



        else begin



            q_empty <= (head==_tail);



//            q_full  <= (((_tail+1)%SIZE==head)||((_tail+2)%SIZE==head));



            wr_en   <= (((_tail+1)%SIZE==head)||((_tail+2)%SIZE==head)||((_tail+3)%SIZE==head));



            rd_en   <= (head==_tail);



        end



        //$display(Inst_Queue[head]);



        // $display(head);



        // $display(tail);



        if(Inst_Status_in) begin



            Inst_Queue[tail] <= Inst_in;



            



            pc_Queue[tail] <= pc_in;



        end 



        if(Inst_Status_out&&!q_empty) begin



            valid <= `one;



            Inst_out <= Inst_Queue[head];



            //$display(Inst_Queue[head]);



            pc_out <= pc_Queue[head];



        end



        else begin



            valid <= `zero;



        end



        tail<=_tail;



        //$display("fuck");



        //$display(head);



        //$display(tail);



       // $display(Inst_Status_out);



        if(q_empty==`one) begin 



            head<=head;



        end



        else begin



            head<=_head;



        end



    end



end







assign _tail = (Inst_Status_in) ? (tail+1)%SIZE:tail;



assign _head = (Inst_Status_out)  ? (head + 1)%SIZE : head;



endmodule

