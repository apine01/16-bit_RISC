// modules for 16 bit RISC processor

//---------------------------------------------------------------------------
// MUX for GPR and program counter
module MUX_3
  ( 
    i_in0,
	i_in1,
	i_in2,
	i_sel,
	o_out
	);
	
  input [15:0] i_in0, i_in1, i_in2;  
  
  input [1:0] i_sel;
  
  output reg [15:0] o_out;
  
always @(*) begin
  case(i_sel)
    2'b00 : 
	  o_out = i_in0;
    2'b01 : 
	  o_out = i_in1;
    2'b10 : 
	  o_out = i_in2;
    default :
	  o_out = 16'b0;
  endcase 
end 
endmodule 


//---------------------------------------------------------------------------
// Arithmetic Logic Unit (ALU) for 16bit RISC
// 16 bit with 3 bit select
module ALU
  (
  i_ALU_sel,
  i_A,
  i_B,
  o_ALU_out,
  o_ALU_cout,
  o_ALU_overflow,
  o_ALU_zero,
  o_ALU_signed
  );
  
  input [2:0] i_ALU_sel;  // selects which operation will be done on A and B
  
  input [15:0] i_A;
  
  input [15:0] i_B;
  
  output reg [15:0] o_ALU_out;  // output after arithmetic has been done
  
  output o_ALU_cout;                      // carry out if computation exceeds limits
  
  output o_ALU_overflow;                  // overflows when operation leaks into signed bit
    
  output o_ALU_zero;                      // outputs if all zeros
  
  output o_ALU_signed;                    // Sgned bit
  
  // some wire connections
  wire [15:0] A;
   assign A = i_A;  // easy readbility 
  wire [15:0] B;
   assign B = i_B;  // easy readbility 
   
// failsafe, carry out
  wire [16:0] flag; 
  assign flag = {1'b0,i_A} + {1'b0,i_B};
  assign o_ALU_cout = flag[16];     // sends out flag when MSB is used
  
//----------------------------------------------------------------------------------------------

always @(*) begin
    case(i_ALU_sel)
      3'b000 :              // addition
        o_ALU_out = A + B;
      3'b001 :              // subtraction 
        o_ALU_out = A - B;
      3'b010 :              // invert
        o_ALU_out = ~A;
      3'b011 :              // logical shift left
        o_ALU_out = A<<B;
      3'b100 :              // logical shift right
        o_ALU_out = A>>B;
      3'b101 :              // AND 
        o_ALU_out = A & B;
      3'b110 :              // OR
        o_ALU_out = A | B; 
      3'b111 :  begin       // Set when less than 
	    if (A < B)
        o_ALU_out = 16'd1; 
	    else
		o_ALU_out = 16'd0;
	  end 
	
      default : 
        o_ALU_out = A + B;   // default value
    endcase
end  
  
  assign o_ALU_overflow = ( o_ALU_out[15] == (A[15] && B[15]) ) ? 1'b0 : 1'b1;
  
  assign o_ALU_zero = (o_ALU_out) ? 1'b0 : 1'b1;
  
  assign o_ALU_signed = o_ALU_out[15]; 

endmodule 
//
//
//---------------------------------------------------------------------------





//---------------------------------------------------------------------------
// instruction memory v1
// 16 entry data memory with 16 bits each entry (ROM)

module imem
  (
	i_Addr,
	o_InstrData
	);
  
  input [15:0] i_Addr;          // Specifies which data entry will be read out, will be given from Program Counter for current executions
  
  output [15:0] o_InstrData;   // Output that will be read out
  
  wire [3:0] rom_addr;
  assign rom_addr = i_Addr[4:1];    // address selected will be from 2nd to 5th bit values, ignores 0.
  
  
//-----------------------------------------------------------------------------------------
//instruction memory

  reg [15:0] instr_m [14:0]; // instruction memory, can have a value of 0,1,2...14, each of those is 16 bits, example below
                             //   bits					     unpacked value
						     // 00000000000000 					  0
						     // 00110100000000 					  1
						     // 10010100000000 					  2
						     // ...						            .
						     // ...						            .
						     // ...						            .
						     // 10000010000001 					  14

initial $readmemb("C:/Users/alanp/txt_files/instr_test.prog", instr_m, 0, 14); // prog file with instructions


  assign o_InstrData = instr_m[rom_addr];   
                                              
endmodule
//
//
//------------------------------------------------------------------------------------------------------------------------------------------------------




//------------------------------------------------------------------------------------------------------------------------------------------------------
// data memory v1
// 16 entry data memory with 16 bits each entry (RAM)

module dmem
  (
  i_clk,
	i_en,
	i_Wen,
	i_Addr,
	i_WriteData,
	o_ReadData
	);
	
  input i_clk; 
  
  input i_en;    // enables Data memory for the device. 1 means it will be read or written in, 0 means nothing is done
  
  input i_Wen;  // 1 means that the address specified will be written, specified by the input, 
                // 0 means the input is ignored and the specified address is read
  
  input [2:0] i_Addr; // Specifies which data entry will be read out, comes from ALU output, will be first 3 bits
  
  input [15:0] i_WriteData; // Input that will be written into the address, will be given from read port 2
  
  output [15:0] o_ReadData; // Output that will be read out and selected by a multiplier
  
  
//-----------------------------------------------------------------------------------------
//data memory

reg [15:0] data_m [7:0]; // data memory, can have a value of 0,1,2...7, each of those is 16 bits, example below
                             //   bits					     unpacked value
						     // 00000000000000 					  0
						     // 00110100000000 					  1
						     // 10010100000000 					  2
						     // ...						            .
						     // ...						            .
						     // ...						            .
						     // 10000010000001 					  7

initial $readmemb("C:/Users/alanp/txt_files/RISC_datam_test.data", data_m, 0, 7); 

always @(posedge i_clk) begin 
  if (i_en && i_Wen)                 // writes into specified address of memory both both enable inputs are on
    data_m[i_Addr] <= i_WriteData; 
end 

  assign o_ReadData = (i_en == 1'b1)? data_m[i_Addr] : 16'b0;   // read data memory continously if the enable is on
                                                            // can happen simulatenously as it write to the data
endmodule
//
//
//---------------------------------------------------------------------------



//------------------------------------------------------------------------------------------------------------------------------------------------------
// general purpose register
// 16 entry register with 16 bits each entry 

module GPR
  (
    i_clk,
	i_en,
	i_Wen,
	i_Write_Dest,
	i_Write_Data,
	i_Read_addr_1,
	i_Read_addr_2,
	o_Read_Data_1,
	o_Read_Data_2
	);
	
  input i_clk; 
  
  input i_en;    // enables device. 1 means it will be read or written in, 0 means nothing is done
  
  input i_Wen;  // 1 means that the address specified will be written, specified by the input, 
                // 0 means the input is ignored and the specified address is read
  
  input [2:0] i_Write_Dest;  // Selects where in the array that data will be written in
  
  input [15:0] i_Write_Data; // Data that will be written in array 
  
  input [2:0] i_Read_addr_1; // address that will be read from for first read port
  
  input [2:0] i_Read_addr_2; // address that will be read from for second read port
  
  output [15:0] o_Read_Data_1; // first read port
  
  output [15:0] o_Read_Data_2; // second read port
  
  
  
//-----------------------------------------------------------------------------------------
// Register array

reg [15:0] gpr_array [7:0]; // register array, can have a value of 0,1,2...7, each of those is 16 bits, example below
                             //   bits					     unpacked dimension value
						     // 00000000000000 					  0
						     // 00110100000000 					  1
						     // 10010100000000 					  2
						     // ...						          .
						     // ...						          .
						     // ...						          .
						     // 10000010000001 					  7


// set array to 0 initially 
  integer i;
  
initial begin
  for(i=0; i<8; i=i+1)
  gpr_array[i] = 16'b0;
end 


always @(posedge i_clk) begin 
  if (i_en && i_Wen)                 // writes into specified address of memory both both enable inputs are on
    gpr_array[i_Write_Dest] <= i_Write_Data; 
end 

  assign o_Read_Data_1 = (i_en == 1'b1)? gpr_array[i_Read_addr_1] : 8'b0000_0000;   // read data memory continously if the enable is on
                                                                                   // can happen simulatenously as it write to the data
																				   
  assign o_Read_Data_2 = (i_en == 1'b1)? gpr_array[i_Read_addr_2] : 8'b0000_0000;   // read data memory continously if the enable is on
                                                                                   // can happen simulatenously as it write to the data
endmodule
//
//
//------------------------------------------------------------------------------------------------------------------------------------------------------