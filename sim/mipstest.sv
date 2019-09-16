//------------------------------------------------
// mipstest.sv
// David_Harris@hmc.edu 23 October 2005
// Updated to SystemVerilog dmh 12 November 2010
// Testbench for MIPS processor
//------------------------------------------------

module testbench();

  logic        clk;
  logic        reset;

  logic [31:0] writedata, dataadr, instrTB, oldInstrTB;
  logic        memwrite;
  logic [6:0] clkCounter;
  logic [6:0] instrCounter;

  // instantiate device to be tested
  mipstop DUV(.clk, .reset, .writedata, .dataadr, .memwrite, .instrTB);
  
  // initialize test
  initial
    begin
      reset <= 1; # 22; reset <= 0;
      clkCounter <= 0;
      instrCounter <= 0;
      oldInstrTB <= 0;
    end

  // generate clock to sequence tests
  always
    begin
      clk <= 1; # 5; clk <= 0; # 5;
    end

  // check that 7 gets written to address 84
  always@(negedge clk)
    begin
    clkCounter <= clkCounter +1;
    if(instrTB == 8'h00000020)
        begin
            instrCounter <= instrCounter + 1;
        end
    else if(instrTB != oldInstrTB)
        begin
            instrCounter <= instrCounter + 1;
            oldInstrTB <= instrTB;
        end
      if(memwrite) begin
        if(dataadr === 84 & writedata === 7) begin
          $display("Simulation succeeded, used %d clk cycles and executed %d instructions", clkCounter+2'b11, instrCounter); //add 3 to clk ctr to account for reset
          $stop;
        end else if (dataadr !== 80) begin
          $display("Simulation failed on first store word");
          $stop;
        end
      end
    end

   localparam LIMIT = 200;  // don't let simulation go on forever
   
   integer cycle = 0;

   always @(posedge clk)
     begin
	   if (cycle>LIMIT) $stop;
	   else cycle <= cycle + 1;
     end 
   
endmodule



