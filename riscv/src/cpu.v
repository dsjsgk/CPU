`include "def.v"
`include "IQ.v"
`include "ID.v"
`include "IF.v"
`include "ROB.v"
`include "LSB.v"
`include "ALU.v"
`include "ISSUE.v"
`include "MemCtrl.v"
`include "RS.v"
`include "ICache.v"
`include "REGFile.v"
module cpu(
  input  wire                 clk_in,			// system clock signal
  input  wire                 rst_in,			// reset signal
	input  wire					        rdy_in,			// ready signal, pause cpu when low

  input  wire [ 7:0]          mem_din,		// data input bus
  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)
	
	input  wire                 io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)
wire clear;
//CDB
wire pc_Change;
wire[`InstSize] pc_goal;
wire ROB_is_full;
wire RS_is_full;
wire LSB_is_full;
wire commited;
wire[`RegAddrSize] commit_ROB_Number;
wire[`RegAddrSize] commit_Reg_Number;
wire[`InstSize] commit_Reg_Val;
//IQ to IF
wire IQ_isfull;
wire[`InstSize] Inst_to_IQ;
wire[`InstSize] pc_to_IQ;
wire en_to_IQ;
//ICache to IF
wire en_to_IF;
wire[`InstSize] Inst_to_IF;
wire[`InstSize] Addr_to_ICache;
wire en_to_ICache;
//ID to IQ
wire IQ_is_empty;
wire ID_need_Inst;
wire[`InstSize] Inst_to_ID;
wire[`InstSize] pc_to_ID;
wire en_to_ID;
//ID to ISSUE
wire en_to_ISSUE;
wire[`OpSize] OpCode_to_ISSUE;
wire[`RegAddrSize] rs1_to_ISSUE;
wire[`RegAddrSize] rs2_to_ISSUE;
wire[`InstSize] imm_to_ISSUE;
wire[`RegAddrSize] rd_to_ISSUE;
wire[`InstSize] pc_to_ISSUE;
wire[`InstSize] Inst_btw_ID_ISSUE;
//ID to REGFile
wire en_to_REGFile_1;
wire[`RegAddrSize] ADDR_to_REGFile_1;
wire en_to_REGFile_2;
wire[`RegAddrSize] ADDR_to_REGFile_2;
//ISSUE to ROB
wire en_to_ROB;
wire[`InstSize] pc_to_ROB;
wire[`OpSize] OpCode_to_ROB;
wire[`InstSize] imm_to_ROB;
wire[`RegAddrSize] rd_to_ROB;
wire[`RegAddrSize] ROB_Number_to_ISSUE;
wire Is_io_reading;
wire[`InstSize] Inst_btw_ROB_ISSUE;
//REGFile to ISSUE
wire[`InstSize] Reg_to_ISSUE_1_Status;
wire[`InstSize] Reg_to_ISSUE_2_Status;
wire[`InstSize] Reg_to_ISSUE_1_data;
wire[`InstSize] Reg_to_ISSUE_2_data;
wire en_wr_to_RegFile;
wire [`RegAddrSize] Addr_to_RegFile;
wire [`InstSize] goal_to_RegFile;
//RS to ISSUE
wire en_ISSUE_to_RS;
wire[`RegAddrSize] ROB_Number_ISSUE_to_RS;
wire[`OpSize] OpCode_ISSUE_to_RS;
wire[`InstSize] Reg_Status_1_ISSUE_to_RS;
wire[`InstSize] Reg_Data_1_ISSUE_to_RS;
wire[`InstSize] Reg_Status_2_ISSUE_to_RS;
wire[`InstSize] Reg_Data_2_ISSUE_to_RS;
//ISSUE to LSB;
wire en_ISSUE_to_LSB;
wire[`RegAddrSize] ROB_Number_ISSUE_to_LSB;
wire[`OpSize] OpCode_ISSUE_to_LSB;
wire[`InstSize] Reg_Status_1_ISSUE_to_LSB;
wire[`InstSize] Reg_Data_1_ISSUE_to_LSB;
wire[`InstSize] Reg_Status_2_ISSUE_to_LSB;
wire[`InstSize] Reg_Data_2_ISSUE_to_LSB;
wire[`InstSize] imm_ISSUE_to_LSB;
//ALU_to_ROB
wire en_ALU_to_ROB;
wire[`RegAddrSize] ROB_Number_ALU_to_ROB;
wire[`InstSize] Value_ALU_to_ROB;
//LSB_to_ROB
wire en_LSB_to_ROB;
wire[`RegAddrSize] ROB_Number_LSB_to_ROB;
wire[`InstSize] Value_LSB_to_ROB;
//RS to ALU
wire en_ALU;
wire[`OpSize] OpCode_RS_to_ALU;
wire[`InstSize] Val1_RS_to_ALU;
wire[`InstSize] Val2_RS_to_ALU;
wire[`RegAddrSize] ROB_Number_RS_to_ALU;
//ICache to MemCtrl;
wire en_ICache_to_MemCtrl;
wire[`InstSize] Addr_ICache_to_MemCtrl;
wire[`InstSize] Data_MemCtrl_to_ICache;
wire en_MemCtrl_to_ICache;
//LSB to MemCtrl;
wire en_w_LSB_to_MemCtrl;
wire en_r_LSB_to_MemCtrl;
wire[`InstSize] Addr_LSB_to_MemCtrl;
wire[`InstSize] Val_LSB_to_MemCtrl;
wire[`InstSize] len_LSB_to_MemCtrl;
wire en_MemCtrl_to_LSB;
wire[`InstSize] data_MemCtrl_to_LSB;

////
wire[`RegAddrSize] _ROB_head;
MemCtrl MemCtrl0(
    .clear(clear),
    .clk_in(clk_in),
    .rst_in(rst_in),
    .rdy_in(rdy_in),
    //FROM LSB
    .data_w_en(en_w_LSB_to_MemCtrl),
    .data_addr(Addr_LSB_to_MemCtrl),
    .data_val(Val_LSB_to_MemCtrl),
    .data_r_en(en_r_LSB_to_MemCtrl),
    .data_len(len_LSB_to_MemCtrl),
    .LSB_en_o(en_MemCtrl_to_LSB),
    .LSB_data_o(data_MemCtrl_to_LSB),
   //FROM ICaChe
    .ICache_en_i(en_ICache_to_MemCtrl),
    .ICache_Addr(Addr_ICache_to_MemCtrl),
    .ICache_en_o(en_MemCtrl_to_ICache),
    .ICache_Data(Data_MemCtrl_to_ICache),
    //From Ram
    .ram_in(mem_din),
    .mem_wr_o(mem_wr),
    .mem_addr(mem_a),
    .mem_wr_data(mem_dout),
    .io_buffer_full(io_buffer_full)
);
IF IF0
  (
    .clear(clear),
    .clk_in(clk_in),
    .rst_in(rst_in),
    .rdy_in(rdy_in),
    .IQ_isfull(IQ_is_full),
    .Inst_Status_out(en_to_IQ),
    .Inst_out(Inst_to_IQ),
    .pc_out(pc_to_IQ) ,
    .commit_en(pc_Change),
    .goal(pc_goal),
    .Inst_Status_in(en_to_IF),
    .Inst_in(Inst_to_IF),
    .Addr(Addr_to_ICache),
    .Inst_en(en_to_ICache)
  );
ID ID0(
    .clear(clear),
    .clk_in(clk_in),
    .rst_in(rst_in),
    .rdy_in(rdy_in),
    //IQ
    .Inst_in(Inst_to_ID),
    .pc_in(pc_to_ID),
    .en_in(en_to_ID),
    .IQ_isempty(IQ_is_empty),
    .Get_Inst(ID_need_Inst),
    //ISSUE
    .en_out(en_to_ISSUE),
    .OpCode(OpCode_to_ISSUE),
    .rs1(rs1_to_ISSUE),
    .rs2(rs2_to_ISSUE),
    .imm(imm_to_ISSUE),
    .rd(rd_to_ISSUE),
    .pc(pc_to_ISSUE),
    .Inst_debug(Inst_btw_ID_ISSUE),
    //ROB
    .ROB_isfull(ROB_is_full),
    //RS
    .RS_isfull(RS_is_full),
    //LSB
    .LSB_isfull(LSB_is_full),
    //REGFile
    .en_1(en_to_REGFile_1),
    .Addr_1(ADDR_to_REGFile_1),
    .en_2(en_to_REGFile_2),
    .Addr_2(ADDR_to_REGFile_2)
); 

IQ IQ0(
    .clear(clear),
    .clk_in(clk_in),
    .rst_in(rst_in),
    .rdy_in(rdy_in),
    //wires from IF
    .Inst_Status_in(en_to_IQ),
    .Inst_in(Inst_to_IQ) ,
    .pc_in(pc_to_IQ) ,
    .wr_en(IQ_is_full) ,
    //wires from ID
    .Inst_Status_out(ID_need_Inst) ,
    .Inst_out(Inst_to_ID) ,
    .pc_out(pc_to_ID) ,
    .valid(en_to_ID) ,
    .rd_en(IQ_is_empty)
);
ISSUE ISSUE0(
    .clear(clear),
    .clk_in(clk_in),
    .rst_in(rst_in),
    .rdy_in(rdy_in),
        //Wires from ID
        .en_in(en_to_ISSUE),
        .OpCode(OpCode_to_ISSUE),
        .rs1(rs1_to_ISSUE),
        .rs2(rs2_to_ISSUE),
        .imm(imm_to_ISSUE),
        .rd(rd_to_ISSUE),
        .pc(pc_to_ISSUE),
        .Inst_debug_in(Inst_btw_ID_ISSUE),
        //ROB
        .ROB_o(en_to_ROB), 
        .pc_o(pc_to_ROB),
        .OpCode_o(OpCode_to_ROB),
        .imm_o(imm_to_ROB),
        .rd_o(rd_to_ROB),
        .ROB_Number(ROB_Number_to_ISSUE),
        .Inst_debug_out(Inst_btw_ROB_ISSUE),
        //REGFile
        .Reg_Status_1(Reg_to_ISSUE_1_Status),
        .Reg_Data_1(Reg_to_ISSUE_1_data),
        .Reg_Status_2(Reg_to_ISSUE_2_Status),
        .Reg_Data_2(Reg_to_ISSUE_2_data),
        .Status_Change(en_wr_to_RegFile),
        .register_addr(Addr_to_RegFile),
        .goal(goal_to_RegFile),
        //RS
        .RS_o(en_ISSUE_to_RS),
        .ROB_Number_o(ROB_Number_ISSUE_to_RS),
        .OpCode_RS(OpCode_ISSUE_to_RS),
        .Reg_Status_1_RS(Reg_Status_1_ISSUE_to_RS),
        .Reg_Data_1_RS(Reg_Data_1_ISSUE_to_RS),
        .Reg_Status_2_RS(Reg_Status_2_ISSUE_to_RS),
        .Reg_Data_2_RS(Reg_Data_2_ISSUE_to_RS),
        //LSB
        .LSB_o(en_ISSUE_to_LSB),
        .OpCode_LSB(OpCode_ISSUE_to_LSB),
        .Reg_Status_1_LSB(Reg_Status_1_ISSUE_to_LSB),
        .Reg_Data_1_LSB(Reg_Data_1_ISSUE_to_LSB),
        .Reg_Status_2_LSB(Reg_Status_2_ISSUE_to_LSB),
        .Reg_Data_2_LSB(Reg_Data_2_ISSUE_to_LSB),
        .imm_LSB(imm_ISSUE_to_LSB),
        .ROB_NumbertoLSB(ROB_Number_ISSUE_to_LSB)
    );
 ROB ROB0(
    .clear(clear),
    .clk_in(clk_in),
    .rst_in(rst_in),
    .rdy_in(rdy_in),
    
    //CDB
    .en_commit(commited),
    .ROB_Number(commit_ROB_Number),
    .Reg_Number(commit_Reg_Number),
    .Reg_Val(commit_Reg_Val),
    .pc_Change(pc_Change),
    .pc_goal(pc_goal),
    //ALU
    .ALU_in(en_ALU_to_ROB),
    .ROB_Number_ALU(ROB_Number_ALU_to_ROB),
    .Value(Value_ALU_to_ROB),
    //ISSUE
    .ISSUE_in(en_to_ROB),
    .pc_in(pc_to_ROB),
    .OpCode_in(OpCode_to_ROB),
    .imm_in(imm_to_ROB),
    .rd_in(rd_to_ROB),
    .ROB_Number_in(ROB_Number_to_ISSUE),
    .Inst_debug_in(Inst_btw_ROB_ISSUE),
    //ID
    .ROB_is_Full(ROB_is_full),
    //LSB
    .LSB_in(en_LSB_to_ROB),
    .ROB_Number_LSB(ROB_Number_LSB_to_ROB),
    .Value_LSB(Value_LSB_to_ROB),
    .ROB_head(_ROB_head)
);
RS RS0(
    .clear(clear),
    .clk_in(clk_in),
    .rst_in(rst_in),
    .rdy_in(rdy_in),
    //to ID
    .RS_is_full(RS_is_full),
    //from ISSUE
    .RS_in(en_ISSUE_to_RS),
    .ROB_Number(ROB_Number_ISSUE_to_RS),
    .OpCode_RS(OpCode_ISSUE_to_RS),
    .Reg_Status_1_RS(Reg_Status_1_ISSUE_to_RS),
    .Reg_Data_1_RS(Reg_Data_1_ISSUE_to_RS),
    .Reg_Status_2_RS(Reg_Status_2_ISSUE_to_RS),
    .Reg_Data_2_RS(Reg_Data_2_ISSUE_to_RS),
    //from ROB
    .commit_en(commited),
    .commit_Number(commit_ROB_Number),
    .commit_val(commit_Reg_Val),
    //to ALU
    .Calc_en(en_ALU),
    .OpCode_o(OpCode_RS_to_ALU),
    .val1(Val1_RS_to_ALU),
    .val2(Val2_RS_to_ALU),
    .ROB_Number_o(ROB_Number_RS_to_ALU)
);
ALU ALU0(
    .clear(clear),
    .clk_in(clk_in),
    .rst_in(rst_in),
    .rdy_in(rdy_in),

    .status(en_ALU),
    .OpCode(OpCode_RS_to_ALU),
    .rs1(Val1_RS_to_ALU),
    .rs2(Val2_RS_to_ALU),
    .ROB_Number(ROB_Number_RS_to_ALU),
    //transfer to ROB
    .to_ROB_Status(en_ALU_to_ROB),
    .ROB_Number_o(ROB_Number_ALU_to_ROB),
    .val(Value_ALU_to_ROB)
);
ICache ICache0(
    .clear(clear),
    .clk_in(clk_in),
    .rst_in(rst_in),
    .rdy_in(rdy_in),
    //With IF
    .en_i_IF(en_to_ICache), 
    .IF_addr(Addr_to_ICache),
    .en_o_IF(en_to_IF),
    .Inst_data(Inst_to_IF),
    //With MemCtrl
    .data_en_i(en_MemCtrl_to_ICache),
    .data_i(Data_MemCtrl_to_ICache),
    .data_get_en(en_ICache_to_MemCtrl),
    .data_get_addr(Addr_ICache_to_MemCtrl)
);
LSB LSB0(
    .clear(clear),
    .clk_in(clk_in),
    .rst_in(rst_in),
    .rdy_in(rdy_in),
    //ISSUE
    .en_in(en_ISSUE_to_LSB),
    .OpCode(OpCode_ISSUE_to_LSB),
    .Reg_Status_1(Reg_Status_1_ISSUE_to_LSB),
    .Reg_Data_1(Reg_Data_1_ISSUE_to_LSB),
    .Reg_Status_2(Reg_Status_2_ISSUE_to_LSB),
    .Reg_Data_2(Reg_Data_2_ISSUE_to_LSB),
    .imm_LSB(imm_ISSUE_to_LSB),
    .ROB_NumbertoLSB(ROB_Number_ISSUE_to_LSB),
    .Inst_debug_in(Inst_btw_ROB_ISSUE),
    //ID
    .LSB_is_full(LSB_is_full),
    //ROB
    .en_commit(commited),
    .ROB_Number(commit_ROB_Number),
    .Reg_Number(commit_Reg_Number),
    .Reg_Val(commit_Reg_Val),
    .LSB_in(en_LSB_to_ROB),
    .ROB_Number_LSB(ROB_Number_LSB_to_ROB),
    .Value(Value_LSB_to_ROB),
    .ROB_head(_ROB_head),
    //MemCtrl
    .data_w_en(en_w_LSB_to_MemCtrl),
    .data_addr(Addr_LSB_to_MemCtrl),
    .data_val(Val_LSB_to_MemCtrl),
    .data_r_en(en_r_LSB_to_MemCtrl),
    .data_len(len_LSB_to_MemCtrl),
    .LSB_en_o(en_MemCtrl_to_LSB),
    .LSB_data_o(data_MemCtrl_to_LSB)
);
REGFile REGFile0(
    .clear(clear),
    .clk_in(clk_in),
    .rst_in(rst_in),
    .rdy_in(rdy_in),

    //FROM ISSUE
    .Status_Change_1(en_wr_to_RegFile),
    .register_addr_1(Addr_to_RegFile),
    .goal_1(goal_to_RegFile),

    //FROM COMMIT
    .Status_Change_2(commited),
    .register_addr_2(commit_Reg_Number),
    .goal_2(commit_Reg_Val),
    .Number(commit_ROB_Number),

    //GET DATA
    .en_in_1(en_to_REGFile_1),
    .en_in_2(en_to_REGFile_2),
    .register_addr_1_out(ADDR_to_REGFile_1),
    .register_addr_2_out(ADDR_to_REGFile_2),
    .Status_1(Reg_to_ISSUE_1_Status),
    .Status_2(Reg_to_ISSUE_2_Status),
    .data_1(Reg_to_ISSUE_1_data),
    .data_2(Reg_to_ISSUE_2_data)
);
endmodule