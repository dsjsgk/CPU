

`define OpSize 5:0

`define Waiting 4'b100

`define RegAddrSize 4:0

`define REGSize 31:0

`define MAXN 32'd1000

`define MemSize 7:0

`define M_SSize 3:0



`define Off 4'b0

`define Getting_Inst 4'b1

`define Reading_Data 4'b10

`define Writing_Data 4'b11

`define Writing_Data_IO 4'b101

`define Reading_Data_IO 4'b110

`define END1 10000000

`define END2 10000001

`define InstSize 31:0

`define one 1'b1

`define zero 1'b0

`define CacheBus 10:2

`define lb 6'b000000

`define lh 6'b000001

`define lw 6'b000010

`define lbu 6'b000011

`define lhu 6'b000100

`define sb 6'b000101

`define sh 6'b000110

`define sw 6'b000111

`define add 6'b001000

`define addi 6'b001001

`define sub 6'b001010

`define lui 6'b001011

`define auipc 6'b001100

`define xor 6'b001101

`define xori 6'b001110

`define or 6'b001111

`define ori 6'b010000

`define and 6'b010001

`define andi 6'b010010

`define sll 6'b010011

`define slli 6'b010100

`define srl 6'b010101

`define srli 6'b010110

`define sra 6'b010111

`define srai 6'b011000

`define slt 6'b011001

`define slti 6'b011010

`define sltu 6'b011011

`define sltiu 6'b011100

`define beq 6'b011101

`define bne 6'b011110

`define blt 6'b011111

`define bge 6'b100000

`define bltu 6'b100001

`define bgeu 6'b100010

`define jal 6'b100011

`define jalr 6'b100100
