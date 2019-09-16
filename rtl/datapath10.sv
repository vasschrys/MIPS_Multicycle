//--------------------------------------------------------------
// datapath.sv - single-cycle MIPS datapath
// David_Harris@hmc.edu and Sarah_Harris@hmc.edu 23 October 2005
// Updated to SystemVerilog dmh 12 November 2010
// Refactored into separate files & updated using additional SystemVerilog
// features by John Nestor May 2018
// Key modifications to this file (to enhance clarity):
//  1. Use explicit port connections in instantiations
//  2. Use explicitly named instruction subfields
//--------------------------------------------------------------

module datapath(input  logic        clk, reset,
                input logic         memtoreg, memwrite, pcsrc, alusrc,branch,
                input logic         regdst, regwrite, jump,sign, 
                input logic [2:0]   alucontrol,
                output logic        zero, stall,jumpFlush, memW,
                output logic [31:0] pc_f,
                input logic [31:0]  instr,
                output logic [31:0] aluout,
                output logic [31:0] writedata,
                input logic [31:0]  readdata);


logic stallF;
assign stall = stallF;

   // instruction fields of interest in the datapath
   logic signVal;
   logic [4:0]                      rs_d;
   logic [4:0]                      rt_d;
   logic [4:0]                      rd_d;
   logic [15:0]                     immed;  // i-type immediate field
   logic [25:0]                     jpadr;  // j-type pseudo-address
   logic [31:0] instr_d, rd1_branch, rd2_branch;
   logic PCSrcD, equalD;
   logic [31:0]                     signimm_d, signimmsh, signimm_e, rd1_d, rd2_d;
   assign rs_d = instr_d[25:21];
   assign rt_d = instr_d[20:16];
   assign rd_d = instr_d[15:11];
   assign immed = instr_d[15:0];
   assign jpadr = instr_d[25:0];
   
   assign signVal = sign;

   // internal datapath signals
   
   logic [4:0]                      writereg, writereg_e;
   logic [31:0]                     pcnext, pcnextbr, pcplus4_f, pcbranch, pcplus4_d,rd1_m,rd2_m, pcbranchD, pcnext_f;
  
   logic [31:0]                     srca, srcb, aluout_e, writedata_e;
   logic [31:0]                     resultW;
   logic [31:0]                     pcjump;

   // next PC logic

   assign pcjump = {pcplus4_d[31:28], jpadr, 2'b00};  // jump target address

   //flopr #(32) U_PCREG(.clk(clk), .reset(reset), .d(pcnext), .q(pc));
   
   logic regwrite_e, memtoreg_e, memwrite_e,alusrc_e, regdst_e;
   logic [31:0] rd1_e, rd2_e;
   logic [4:0]  rs_e, rt_e, rd_e;
   logic [2:0] alucontrol_e;
   
   logic regwrite_m, memtoreg_m, memwrite_m;
   logic[31:0] aluout_m,writedata_m, readdata_m;
   logic[4:0] writereg_m;
      
   
   logic regwrite_w, memtoreg_w;
   logic [31:0] aluout_w, readdata_w;
   logic [4:0] writereg_w;
   
   //logic regDstFixed, alusrcFixed;
   
   
   HazardUnit hazardSignals(.branch, .memtoreg_e, .regwrite_e, .regwrite_m, .memtoreg_m, .regwrite_w, .rs_d, .rt_d, .rs_e, .rt_e, .writereg_e, .writereg_m, .writereg_w,
                       .stallF, .stallD, .forwardAD, .forwardBD, .flushE, .forwardAE, .forwardBE);
                       
   logic stallD, forwardAD, forwardBD, flushE;
   logic [1:0] forwardAE, forwardBE;
   
   
   
   logic [31:0] pcfBeforeJMux;
   //assign pc = pc_f;
   //PC and grab instruction-----------------------------
   pr_pc PCReg(.clk, .reset, .stall_f(stallF),.pcnext_f,.pc_f(pc_f));
   
   adder       U_PCADD1(.a(pc_f), .b(32'h4), .y(pcplus4_f));    //PC + 4 adder
   
   sl2         U_IMMSH(.a(signimm_d), .y(signimmsh));
   
   adder       U_PCADD2(.a(pcplus4_d), .b(signimmsh), .y(pcbranchD));   //PC branch adder

   mux2 #(32)  U_PCBRMUX(.d0(pcplus4_f), .d1(pcbranchD), .s(PCSrcD),.y(pcnextbr));  //PC mux 1
   mux2 #(32) U_PCJumpMux(.d0(pcnextbr), .d1(pcjump), .s(jump), .y(pcnext_f));   //PC mux for jump
//----------------------------------------------------------


logic brjflush;
assign brjflush = PCSrcD || jump; //assign brjflush = PCSrcD || jump;
assign jumpFlush = jump;

//Decode instr and PC -----------------------------------------

 pr_f_d pipelineFD(.clk, .reset, .clear(brjflush), .stall_d(stallD),
  .instr_f(instr), .pcplus4_f,.instr_d, .pcplus4_d);
  //-----------------------------------------------------------------
  
  
  //regdst fix:
  //miniReg regDestination(.clk,.reset,.dst(regdst),.dstOut(regDstFixed));
  
  //alusrc fix:
  //miniReg aluSrcFix(.clk, .reset, .dst(alusrc), .dstOut(alusrcFixed));
  

  
 //Grab reg values and branch------------------------------------------------------------
pr_d_e pipelineDE (.clk, .reset, .flush_e(flushE),
.regwrite_d(regwrite), .memtoreg_d(memtoreg), .memwrite_d(memwrite),
.alucontrol_d(alucontrol),
.alusrc_d(alusrc), .regdst_d(regdst),
 .rd1_d, .rd2_d,
.rs_d, .rt_d, .rd_d,
 .signimm_d,
.regwrite_e, .memtoreg_e, .memwrite_e,
  .alucontrol_e,
   .alusrc_e, .regdst_e,
.rd1_e, .rd2_e,
  .rs_e, .rt_e, .rd_e,
   .signimm_e);
   
   mux2 #(32)  U_RD1BrMUX(.d0(rd1_d), .d1(aluout_m),.s(forwardAD), .y(rd1_branch));
   mux2 #(32)  U_RD2BrMUX(.d0(rd2_d), .d1(aluout_m),.s(forwardBD), .y(rd2_branch));  //muxes for branch
   assign equalD = (rd1_branch == rd2_branch);   //Supposed to be this!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   //assign equalD = 1'b0;
   assign PCSrcD = equalD && branch;    //branch
   //-------------------------------------------------------
   
   
   //Get correct values for alu and get result-----------------------------------
   pr_e_m pipelineEM(.clk,.reset,.regwrite_e, .memtoreg_e, .memwrite_e,
      .aluout_e,
      .writedata_e,
     .writereg_e,
      .regwrite_m, .memtoreg_m, .memwrite_m,
      .aluout_m,
     .writedata_m,
      .writereg_m);

   assign memW= memwrite_m;
   mux2 #(5)   U_WRMUX(.d0(rt_e), .d1(rd_e), .s(regdst_e), .y(writereg_e)); //write reg mux
          
                        // ALU logic
                        
    //assign srca = rd1_e;    
    mux3 #(32) U_SRCAMUX(.d0(rd1_e), .d1(resultW), .d2(aluout_m), .s(forwardAE), .y(srca));  
    logic[31:0] srcBoption;
    mux3 #(32) U_SRCBPREMUX(.d0(rd2_e), .d1(resultW), .d2(aluout_m), .s(forwardBE), .y(srcBoption));             
    mux2 #(32)  U_SRCBMUX(.d0(srcBoption), .d1(signimm_e), .s(alusrc_e), .y(srcb));
    
    
    assign writedata_e = srcBoption; //was rd2_e for lab 9
    
    alu_211 U_ALU(.a(srca), .b(srcb), .f(alucontrol_e), .y(aluout_e), .zero(zero));
   //---------------------------------------------------------------------------
   
   
   //Data Memory Results-----------------------------------------------------------------
   pr_m_w pipelineMW (.clk, .reset,.regwrite_m, .memtoreg_m,.aluout_m, .readdata_m(readdata), .writereg_m, .regwrite_w, .memtoreg_w,.aluout_w, .readdata_w, .writereg_w);
   // assign writedata = rd2_d;
   // assign aluout = rd1_d + signimm_d;
   // assign writedata = writedata_m;
       // assign aluout = aluout_m;
  //---------------------------------------------------------------------------------------------
   
   mux2 #(32)  U_RESMUX(.d0(aluout_w), .d1(readdata_w),.s(memtoreg_w), .y(resultW));  //mux for determining value to be written in reg
   
   regfile     U_RF(.clk(clk), .we3(regwrite_w), .ra1(rs_d), .ra2(rt_d),
                    .wa3(writereg_w), .wd3(resultW), .rd1(rd1_d), .rd2(rd2_d));  //rd2 wwas going to writedata

   signext     U_SE(.a(immed), .y(signimm_d), .sign(signVal));
   
  always_comb
  begin
//  if(memwrite)
//    begin
//        if(forwardBD == 1'b1 && instr_d == 32'hac670044) writedata = aluout_e; //was 2 bit
//        else if(forwardBD == 1'b1) writedata = readdata_w;
//        else writedata = rd2_d; //else writedata = rd2_d;
//        aluout = rd1_d + signimm_d;
//    end
//  else
    //begin
        writedata = writedata_m;
        aluout = aluout_m;
    end
  
  //end
   
 

endmodule
