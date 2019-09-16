//--------------------------------------------------------------------
// top.v - top-level MIPS single cycle with instruction and data memories
// David_Harris@hmc.edu 9 November 2005
// Updated to SystemVerilog and modfied for clarity
// John Nestor, May 2018
// Key changes to this module:
//   1. Modfied dmem to use byte addressing rather than word addressing
//      for consistency
//--------------------------------------------------------------------

module mipstop(input logic         clk, reset, 
           output logic [31:0] writedata, dataadr,instrTB, 
           output logic        memwrite);

   logic [31:0]                pc_f, instr, readdata;
   assign instrTB = instr;
  
  // instantiate processor and memories
  mips mips(.clk, .reset, .pc_f, .instr, .memwrite, .aluout(dataadr), .writedata, .readdata);
   
  imem imem(.adr(pc_f), .rd(instr));
   
  dmem dmem(.clk, .we(memwrite), .adr(dataadr), .wd(writedata), .rd(readdata));
  

endmodule
