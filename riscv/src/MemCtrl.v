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

    input wire[3:0] data_len,

    output reg LSB_en_o,

    output reg[`InstSize] LSB_data_o,

   //FROM ICaChe

    input wire ICache_en_i,

    input wire[`InstSize] ICache_Addr,

    output reg ICache_en_o,

    output reg[`InstSize] ICache_Data,

    //From Ram

    input wire [`MemSize] ram_in,

    output reg mem_wr_o,

    output reg[`InstSize] mem_addr,

    output reg[`MemSize] mem_wr_data,

    //

    input wire io_buffer_full

);

reg[3:0] Cur_Status;

reg[5:0] Cur_Cycle;

reg[`InstSize] Val; 

reg program_end;

reg[`InstSize] Clk_Number;



always @(posedge clk_in) begin

    

    if(rst_in) begin

        Clk_Number <= 0;

        mem_wr_o <= `zero;

        ICache_en_o <= `zero;

        Val <= 0;

        LSB_en_o <= `zero;

        Cur_Status <= `Off;

        Cur_Cycle <= 0;

        // program_end=0;

    end

    // else if(program_end) begin

    //     mem_addr <= 196612;

    //     if(mem_wr_o) mem_wr_o <= 0;

    //     else mem_wr_o<= 1;

    // end

    else if(clear&&Cur_Status!=`Writing_Data&&Cur_Status!=`Writing_Data_IO) begin

        mem_wr_o <= `zero;

        ICache_en_o <= `zero;

        Val <= 0;

        LSB_en_o <= `zero;

        Cur_Status <= `Off;

        Cur_Cycle <= 0;

    end

    else if(rdy_in) begin

        //$display("LSB_en_o",LSB_en_o);

        

    // $display(Clk_Number);

        if(Clk_Number == `END1) begin

            mem_wr_o <= 1;

            mem_addr <= 0;

            mem_wr_data <= 1;

            Clk_Number <= Clk_Number +1;

        end

        else if(Clk_Number == `END2) begin

            mem_wr_o <= 1;

            mem_addr <= 196612;

            mem_wr_data <= 1;

        end

        else begin case(Cur_Status)

            `Off: begin

                if(data_w_en) begin

                    if(data_addr[17:16]==2'b11) begin

                        Cur_Status <= `Writing_Data_IO;

                        mem_wr_o <= 0;Clk_Number <= 0;

                    end

                    else 

                    begin

                        Cur_Status <= `Writing_Data;

                        mem_wr_o <= 1;

                        mem_addr <= data_addr;

                        mem_wr_data <= data_val[7:0];Clk_Number <= Clk_Number +1;

                    end

                end

                else if(data_r_en) begin

                    if(data_addr[17:16]==2'b11) begin

                        Cur_Status <= `Reading_Data_IO;

                        mem_wr_o <= 0;Clk_Number <= 0;

                    end

                    else 

                    begin

                        Cur_Status <= `Reading_Data;

                        mem_wr_o <= 0;

                        mem_addr <= data_addr;Clk_Number <= Clk_Number +1;

                    end

                    // $display("Load_addr",data_addr);

                end

                else if(ICache_en_i) begin

                    Cur_Status <= `Getting_Inst;

                    mem_wr_o <= 0;

                    mem_addr <= ICache_Addr;Clk_Number <= Clk_Number +1;

                end

                else begin

                    Clk_Number <= Clk_Number +1;

                end

                Cur_Cycle <= 0;

                Val <= 0;

                ICache_en_o <= 0;

                LSB_en_o <= 0;

            end

            `Reading_Data:begin



                case(Cur_Cycle) 



                0:begin



                    Cur_Cycle <= Cur_Cycle+1;



                    mem_addr <= mem_addr+1;



                end



                1:begin



                    if(data_len == 1) begin



                        Cur_Cycle <= 0;



                        Cur_Status <= `Waiting;



                        LSB_en_o <= 1;



                        LSB_data_o <= ram_in;



                        // $display(ram_in);



                        // $display("1--------------------------------");



                        Val<=0;



                    end



                    else begin



                        Cur_Cycle <= Cur_Cycle+1;



                        Val[7:0] <= ram_in;



                        mem_addr <= mem_addr+1;



                    end



                end



                2:begin



                    if(data_len == 2) begin



                        Cur_Cycle <= 0;



                        Cur_Status <= `Waiting;



                        LSB_en_o <= 1;



                        LSB_data_o <= {ram_in,Val[7:0]};



                        // $display("1--------------------------------");



                        Val<=0; 



                    end



                    else begin



                        Cur_Cycle <= Cur_Cycle+1;



                        Val[15:8] <= ram_in;



                        mem_addr <= mem_addr+1;



                    end



                end



                3:begin



                    Cur_Cycle <= Cur_Cycle+1;



                    Val[23:16] <= ram_in;



                end



                4:begin



                    Cur_Cycle <= 0;



                    Cur_Status <= `Waiting;



                    LSB_en_o <= 1;



                    // $display("1--------------------------------");



                    LSB_data_o <= {ram_in,Val[23:0]};



                    Val<=0; 



                end



                endcase



            end

            `Getting_Inst:begin

                case(Cur_Cycle) 

                0:begin

                    Cur_Cycle <= Cur_Cycle+1;

                    mem_addr <= mem_addr+1;

                end

                1:begin

                    Cur_Cycle <= Cur_Cycle+1;

                    Val[7:0] <= ram_in;

                    mem_addr <= mem_addr+1;

                end

                2:begin

                    Cur_Cycle <= Cur_Cycle+1;

                    Val[15:8] <= ram_in;

                    mem_addr <= mem_addr+1;

                end

                3:begin

                    Cur_Cycle <= Cur_Cycle+1;

                    Val[23:16] <= ram_in;

                end

                4:begin

                    Cur_Cycle <= 0;

                    Cur_Status <= `Waiting;

                    ICache_en_o <= 1;

                    ICache_Data <= {ram_in,Val[23:0]};

                    Val[31:24] <= ram_in;

                end

                endcase

            end

            `Writing_Data:begin

                case(Cur_Cycle) 

                0:begin

                    if(data_len == 1) begin

                        Cur_Cycle <= 0;

                        Cur_Status <= `Waiting;

                        LSB_en_o <= 1;

                        mem_wr_o <= 0;

                        mem_addr <= 0;

                        // $display("1--------------------------------W");

                        Val<=0;

                    end

                    else begin

                        Cur_Cycle <= Cur_Cycle+1;

                        mem_addr <= mem_addr+1;

                        mem_wr_data <= data_val[15:8];

                    end

                end

                1:begin

                    if(data_len == 2) begin

                        Cur_Cycle <= 0;

                        Cur_Status <= `Waiting;

                        LSB_en_o <= 1;

                        mem_wr_o <= 0;

                        // $display("1--------------------------------W");

                        mem_addr <= 0;

                        Val<=0;

                    end

                    else begin

                        Cur_Cycle <= Cur_Cycle+1;

                        mem_addr <= mem_addr+1;

                        mem_wr_data <= data_val[23:16];

                    end

                end

                2:begin

                    Cur_Cycle <= Cur_Cycle+1;

                    mem_wr_data <= data_val[31:24];

                    mem_addr <= mem_addr+1;

                end

                3:begin

                    Cur_Cycle <= 0;

                    Cur_Status <= `Waiting;

                    LSB_en_o <= 1;

                    mem_wr_o <= 0;

                    // $display("1--------------------------------W");

                    mem_addr <= 0;

                    Val<=0;

                end

                endcase

            end

            `Waiting:begin

                //$display(`Waiting);

                Cur_Status <= `Off;

                LSB_en_o <= 0;

                ICache_en_o <= 0;

                mem_addr <= 0;

            end

            `Writing_Data_IO:begin

                case(Cur_Cycle) 

                0:begin

                    Cur_Cycle <= 1;

                end

                1:begin

                    Cur_Cycle <= 2;

                end

                2:begin

                    if(io_buffer_full) begin

                        Cur_Cycle <= 0;

                    end

                    else begin

                        mem_addr <= data_addr;

                        mem_wr_o <= 1;

                        Cur_Cycle <= 3;

                        mem_wr_data <= data_val[7:0];

                    end

                end

                3:begin

                    Cur_Cycle <= 0;

                    mem_wr_o <= 0;

                    mem_addr <= 0;

                    Val<=0;

                    Cur_Status <= `Waiting;

                    LSB_en_o <= 1;

                end

                endcase

            end

            `Reading_Data_IO:begin

                case(Cur_Cycle) 

                0:begin

                    Cur_Cycle <= 1;

                end

                1:begin

                    Cur_Cycle <= 2;

                end

                2:begin

                    if(io_buffer_full) begin

                        Cur_Cycle <= 0;

                    end

                    else begin

                        mem_addr <= data_addr;

                        mem_wr_o <= 0;

                        Cur_Cycle <= 3;

                    end

                end

                3:begin

                    Cur_Cycle <= 4;

                    mem_wr_o <= 0;

                    // $display("1--------------------------------W");

                    mem_addr <= 0;

                    Val<=0;

                end

                4:begin

                    Cur_Cycle <= 0;

                    LSB_en_o <= 1;

                    LSB_data_o <= ram_in;

                    Val<=0; 

                    Cur_Status <= `Waiting;

                end

                endcase

            end

        endcase

        end

    end

end

endmodule
