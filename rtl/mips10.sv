//--------------------------------------------------------------
// mips.sv - single-cycle MIPS processor
// David_Harris@hmc.edu and Sarah_Harris@hmc.edu 23 October 2005
// Updated to SystemVerilog dmh 12 November 2010
// Refactored into separate files & updated using additional SystemVerilog
// features by John Nestor May 2018
// Key modifications to this file:
//  1. Use enum for opcode & function code for aid in simulation
//  2. Use explicit port style in instantiations
//--------------------------------------------------------------

module mips(input  logic        clk, reset,
            output logic [31:0] pc_f,
            input logic [31:0]  instr,
            output logic        memWrite,
            output logic [31:0] aluout, writedata,
            input logic [31:0]  readdata);

   import mips_decls_p::*;
   logic[31:0] instrFixed;
   logic stall, jumpFlush, memW;
      always_ff @(posedge clk)   //instr reg for controller
       begin
       if (reset)
        begin
            instrFixed <= '0;
        end
       else if(jumpFlush)
        begin 
            instrFixed <= 32'h00000020;
        end
       else if(stall) instrFixed <= instrFixed;
       else instrFixed <= instr;
       end
   // instruction fields
   // using enumerate type makes symbolic values visible during simulation
   opcode_t opcode;
   funct_t funct;
   assign opcode = opcode_t'(instrFixed[31:26]);
   assign funct = funct_t'(instrFixed[5:0]); // caution: will show "phantom" function codes for
                                        // non-R-Type instructions
   
   // status signals
   logic                        zero;
   logic sign;

   // control signals

   logic                        memtoreg, alusrc, regdst, regwrite, jump, pcsrc, branch, branchNE, memwrite;
   logic [2:0]                  alucontrol;

   controller U_C(.opcode, .funct, .zero, 
                  .memtoreg, .memwrite, .pcsrc, .branch, .branchNE,
                  .alusrc, .regdst, .regwrite, .jump,
                  .alucontrol, .sign);
   
   datapath U_DP(.clk, .reset, .memtoreg, .pcsrc, .branch, .stall, .jumpFlush,.memW,
                 .alusrc, .regdst, .memwrite, .regwrite, .jump,
                 .alucontrol,.zero, .pc_f, .instr,
                 .aluout, .writedata, .readdata, .sign);
                 
                 assign memWrite = memW;
endmodule
