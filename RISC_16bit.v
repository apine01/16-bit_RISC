// 16 bit RISC Processor

`include "RISC_16bit_cu.v"
`include "RISC_16bit_mods.v"



module RISC_16
  (
    i_clk
	);
  
  input i_clk;
  
  wire [15:0] w_Instr;  // instructions that will be read out from instruction memory
  
  wire [15:0] w_PC_in;             // Input to program counter
  reg [15:0]  r_PC_out;            // Output of program counter, selects which address of instruction memory is read
  wire [15:0] w_PC_adder_out;      // Adder that increments PC by 2
  
// The following are the various inputs that can be selected to go to the PC-------------------------//             
  wire [15:0] w_PC_br;             // Selected when there is a branch                                //    
  wire [15:0] w_PC_j;              // Selected when there is a jump                                  //                   
  wire [15:0] w_PC_2;              // Selected in all other cases(data processing, loading, storing) //         
//---------------------------------------------------------------------------------------------------//
  
// Outputs for the control unit 
  wire Reg_Dst, Alu_Src, Mem_to_Reg, Reg_Wr, Mem_rd, Mem_wr, Branch, Jmp;  


  wire [1:0] ALU_OP; // part of ALU control unit, selects correct operation depending on instruction

  wire [2:0] w_read_address_1; // address to be read on port one of the GPR
  wire [2:0] w_read_address_2; // address to be read on port one of the GPR
  
  wire [2:0] w_write_destination; // address which will be written into for the GPR
  
  wire [15:0] w_read_data_1; // ouput that is read for port 1 of GPR
  wire [15:0] w_read_data_2; // ouput that is read for port 2 of GPR

  wire [2:0] w_ALU_Sel; // selects mode for ALU
  wire [15:0]  w_data2;  // second input of ALU, can be read data from port 2 or extended offset wire
  wire [15:0]  imm_ext;  // immediate extension, repeats MSB of w_offset for a total of 16 bits
  
  wire [15:0] w_ALU_out; // ALU output
  
  wire     w_ALU_cout; // carry out if computation exceeds limits
  wire w_ALU_overflow; // overflows when operation leaks into signed bit 
  wire     w_ALU_zero; // outputs if all zeros
  wire   w_ALU_signed; // Signed bit
  
  wire [15:0] w_Dmem_out; // Data memory output 
  
  wire [15:0] w_Write_Data; // data written into GPR, can be Dmem output or ALU
  
  wire [5:0]      w_offset; // offset from instructions            
  wire [15:0] shift_offset; // shift applied to immediate extension by one bit left
  
  wire [11:0]  w_Joffset;   // jump offset
  wire [12:0] shift_jump;   // shift left applied to jump offset
  
  wire [1:0] PC_sel;        // Selects PC input
  
  
  
  
  wire          Vcc; // high value to enable GPR, always enabled for this code
  assign Vcc = 1'b1;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//-----------------------------------------------------------------------
// Program counter
// Updates PC output, which chooses instruction Memory address, every clock cycle
//---------------{{{{{{{{{{{ 	
initial                     
  r_PC_out = 16'b0;         
                            
always @(posedge i_clk)     
  r_PC_out <= w_PC_in;       // PC output which connects to imem address select
//--------------------------}}}}}}}}}}}



//-----------------------------------------------------------------------
// Program counter control, includes program counter adder
// selects PC input
//---------------{{{{{{{{{{{ 	
assign imm_ext = {{10{w_Instr[5]}}, w_Instr[5:0]};            // assigning immediate extend

// data processing -----------------------------------//
assign w_PC_2 = r_PC_out + 16'd2;                     //
                                                      //
// branches ------------------------------------------//
// adds 2 to PC and then addes shifted offset         //
assign shift_offset = {imm_ext[14:0],1'b0};           // throw MSB of extend out
assign w_PC_br = w_PC_2 + shift_offset;               //
                                                      //
// jumps -------------------------------------------- //
assign shift_jump = {w_Joffset,1'b0};                //
assign w_PC_j = {r_PC_out[15:13], shift_jump};        //
                                                      //
// selecting  ----------------------------------------//
assign PC_sel = {Jmp, Branch};

MUX_3 mux_3_0
  ( 
  .i_in0(w_PC_2),
	.i_in1(w_PC_br),
	.i_in2(w_PC_j),
	.i_sel(PC_sel),
	.o_out(w_PC_in)
	);

//--------------------------}}}}}}}}}}}



//-----------------------------------------------------------------------
// Instruction Memory
// Reads out address selected by the PC from the instructions
//---------------{{{{{{{{{{{ 	
imem imem0 
       (
	     .i_Addr(r_PC_out),
	     .o_InstrData(w_Instr)  // Instructions read, instruction file within module
	     );

//--------------------------}}}}}}}}}}}



//-----------------------------------------------------------------------
// RISC control unit
// Controls the conditions of operation through enablers and selects
//---------------{{{{{{{{{{{ 
RISC_control_unit risc_cu0
  (
  .i_Instr(w_Instr),
	.Reg_Dst(Reg_Dst), .Alu_Src(Alu_Src), .Mem_to_Reg(Mem_to_Reg), .Reg_Wr(Reg_Wr), .Mem_rd(Mem_rd), .Mem_wr(Mem_wr), 
	.Branch(Branch), .Jmp(Jmp),
	.ALU_OP(ALU_OP)
	);

//--------------------------}}}}}}}}}}}


//-----------------------------------------------------------------------
// GPR control unit
// Controls data path for GPR
//---------------{{{{{{{{{{{ 
GPR_control_unit  gpr_cu1       // General purpose register control unit
  (
  .i_clk(i_clk),
	.i_Instructions(w_Instr),
	.i_Reg_Dst(Reg_Dst),
	.o_read_address_1(w_read_address_1),
	.o_read_address_2(w_read_address_2),
	.o_write_destination(w_write_destination),
	.o_offset(w_offset),
	.o_Joffset(w_Joffset)
	);
    
//--------------------------}}}}}}}}}}}

//-----------------------------------------------------------------------
// General Purpose Register (GPR)
// Register for instructions going in and loads/stores ALU and Dmem outputs
//---------------{{{{{{{{{{{ 
GPR gpr0
  (
  .i_clk(i_en),
	.i_en(Vcc),
	.i_Wen(Reg_Wr),
	.i_Write_Dest(w_write_destination),
	.i_Write_Data(w_Write_Data),                  
	.i_Read_addr_1(w_read_address_1),
	.i_Read_addr_2(w_read_address_2),
	.o_Read_Data_1(w_read_data_1),
	.o_Read_Data_2(w_read_data_2)
	);
    
//--------------------------}}}}}}}}}}}



//-----------------------------------------------------------------------
// ALU Control unit
// Controls ALU select based on instructions
//---------------{{{{{{{{{{{ 
ALU_control alu_cu0
  (
  .i_ALU_OP(ALU_OP),
	.i_Instr(w_Instr),      
	.o_ALU_sel(w_ALU_Sel)
	);
    
//--------------------------}}}}}}}}}}}


//-----------------------------------------------------------------------
// 2 input MUX for ALU
//---------------{{{{{{{{{{{ 
assign w_data2 = (Alu_Src == 1'b1)? imm_ext : w_read_data_2;  // selects extend or read output of second port, will be second operand of ALU
    
//--------------------------}}}}}}}}}}}


//-----------------------------------------------------------------------
// ALU 
//---------------{{{{{{{{{{{ 
ALU alu0
  (
  .i_ALU_sel(w_ALU_Sel),
  .i_A(w_read_data_1),
  .i_B(w_data2),
  .o_ALU_out(w_ALU_out),
  .o_ALU_cout(w_ALU_cout),
  .o_ALU_overflow(w_ALU_overflow),
  .o_ALU_zero(w_ALU_zero),
  .o_ALU_signed(w_ALU_signed)
  );
    
//--------------------------}}}}}}}}}}}


//-----------------------------------------------------------------------
// Data Memory 
//---------------{{{{{{{{{{{ 
dmem datamem0
  (
  .i_clk(i_clk),
	.i_en(Mem_rd),
	.i_Wen(Mem_wr),
	.i_Addr(w_ALU_out[2:0]),
	.i_WriteData(w_read_data_2),
	.o_ReadData(w_Dmem_out)
	);
    
//--------------------------}}}}}}}}}}}

//-----------------------------------------------------------------------
// MUX for GPR writing

assign w_Write_Data = (Mem_to_Reg==1'b1)? w_Dmem_out : w_ALU_out; 

    
//--------------------------}}}}}}}}}}}




endmodule