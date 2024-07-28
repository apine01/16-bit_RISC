// control unit for 16 bit RISC Processor

//---------------------------------------------------------------------------
// 16bit RISC processor control unit
// controls enables, writes, jumps, branches, and registers
module RISC_control_unit
  (
    i_Instr,
	Reg_Dst, Alu_Src, Mem_to_Reg, Reg_Wr, Mem_rd, Mem_wr, 
	Branch, Jmp,
	ALU_OP
	);
	
  input [15:0] i_Instr;
  
  output reg Reg_Dst, Alu_Src, Mem_to_Reg, Reg_Wr, Mem_rd, Mem_wr, Branch, Jmp;
  
  output reg [1:0] ALU_OP;
  
  
  
  
  parameter Store_W = 4'd1;
  
  parameter Load_W = 4'd0;
  
  parameter BranchEq = 4'd11;
  
  parameter BranchNotEq = 4'd12;
  
  parameter Jump = 4'd13;

  
always @(*) begin
  Reg_Dst  = 1'b0;
  Alu_Src  = 1'b0;
  Mem_to_Reg  = 1'b0;
  Reg_Wr   = 1'b0;
  Mem_rd   = 1'b0;
  Mem_wr   = 1'b0;
  Branch   = 1'b0;
  Jmp      = 1'b0;
  ALU_OP = 2'b0;
  
  // Data Processing ------------------------------------------------ ALU operations
  
  if (i_Instr[15:12] > 4'd1 && i_Instr[15:12] < 4'd11) begin
    Reg_Dst <= 1'b1;
	Reg_Wr  <= 1'b1;
  end 

  // Load Word 
  if (i_Instr[15:12] == Load_W) begin
    Alu_Src  <= 1'b1;
	Mem_to_Reg  <= 1'b1;
	Reg_Wr   <= 1'b1;
	Mem_rd   <= 1'b1;
	ALU_OP <= 2'b10;
  end 
  
  // Store Word
  if (i_Instr[15:12] == Store_W) begin
    Alu_Src  = 1'b1;
    Mem_wr   = 1'b1;
    ALU_OP = 2'b10;
  end 
  
  // Branch
  if (i_Instr[15:12] == (BranchEq | BranchNotEq) ) begin
    Branch   = 1'b1;
    ALU_OP = 2'b01;
  end 
  
  // Jump
  if (i_Instr[15:12] == Jump) 
    Jmp = 1'b1;
	
end  
endmodule 
//
//
//---------------------------------------------------------------------------





//---------------------------------------------------------------------------
// General purpose register control unit for 16bit RISC
// 
module GPR_control_unit       // General purpose register control unit
  (
    i_clk,
	i_Instructions,
	i_Reg_Dst,
	o_read_address_1,
	o_read_address_2,
	o_write_destination,
	o_offset,
	o_Joffset
	);
	
  input i_clk;
  
  input [15:0] i_Instructions;
  
  input i_Reg_Dst;
  
  output [2:0] o_read_address_1;     // address to be read for first read port
  
  output [2:0] o_read_address_2;     // address to read for second read port
  
  output [2:0] o_write_destination;  // row destination for writing to register
  
  output [5:0] o_offset;
  
  output [11:0] o_Joffset;
  
  
  assign o_read_address_1 = i_Instructions[11:9];
  
  assign o_read_address_2 = i_Instructions[8:6];
                 
  assign o_write_destination = (i_Reg_Dst == 1'b1)? i_Instructions[5:3] : i_Instructions[8:6];

  assign o_offset = i_Instructions[5:0];
  
  assign o_Joffset = i_Instructions[11:0];

  
endmodule 
//
//
//---------------------------------------------------------------------------





//---------------------------------------------------------------------------
//  Arithmetic Logic Unit (ALU) control unitfor 16bit RISC
// outputs ALU mode given the input of ALU OP and Instruction opcode
module ALU_control
  (
    i_ALU_OP,
	i_Instr,      
	o_ALU_sel
	);
	
  input [1:0] i_ALU_OP;
  
  input [15:0] i_Instr;
  
  output reg [2:0] o_ALU_sel;
  
always @(*) begin
  case({i_ALU_OP,i_Instr[15:12]})
    {2'b10, 4'hx} : 
	  o_ALU_sel = 3'b000;
	{2'b01, 4'hx} : 
	  o_ALU_sel = 3'b001;
	{2'b00, 4'h2} : 
	  o_ALU_sel = 3'b000;
	{2'b00, 4'h3} : 
	  o_ALU_sel = 3'b001;
	{2'b00, 4'h4} : 
	  o_ALU_sel = 3'b010;
	{2'b00, 4'h5} : 
	  o_ALU_sel = 3'b011;
	{2'b00, 4'h6} : 
	  o_ALU_sel = 3'b100;
	{2'b00, 4'h7} : 
	  o_ALU_sel = 3'b101;
	{2'b00, 4'h8} : 
	  o_ALU_sel = 3'b110;
	{2'b00, 4'h9} : 
	  o_ALU_sel = 3'b111;
	default :
	  o_ALU_sel = 3'b000;
  endcase 
end 

endmodule 
//
//
//---------------------------------------------------------------------------