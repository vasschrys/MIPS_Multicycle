`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/25/2019 03:01:02 PM
// Design Name: 
// Module Name: HazardUnit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module HazardUnit(input logic branch, memtoreg_e,regwrite_e, regwrite_m, memtoreg_m, regwrite_w, input logic[4:0] rs_d, rt_d, rs_e, rt_e, writereg_e, writereg_m, writereg_w,
                    output logic stallF, stallD, forwardAD, forwardBD, flushE, output logic[1:0] forwardAE, forwardBE);
                    
                    logic lwstall, branchstall;
always_comb
begin
   //forwardAE
	if ((rs_e != 0) && (rs_e == writereg_m) && regwrite_m)     
		 	forwardAE = 2'b10;
	else if ((rs_e != 0) && (rs_e == writereg_w) && regwrite_w) 
		 	forwardAE = 2'b01;
	else	    	forwardAE = 2'b00;
	
	//forwardBE
	if ((rt_e != 0) && (rt_e == writereg_m) && regwrite_m)     
                 forwardBE = 2'b10;
        else if ((rt_e != 0) && (rt_e == writereg_w) && regwrite_w) 
                 forwardBE = 2'b01;
        else            forwardBE = 2'b00;
        
        branchstall = branch && regwrite_e && ((writereg_e == rs_d || writereg_e == rt_d) || (branch && memtoreg_m && (writereg_m == rs_d || writereg_m== rt_d)));
	
	lwstall = ((rs_d==rt_e) || (rt_d==rt_e)) && memtoreg_e;
            
        stallF = lwstall || branchstall;
        stallD = lwstall || branchstall;
        flushE = lwstall || branchstall;

	forwardAD = (rs_d !=0) && (rs_d == writereg_m) && regwrite_m;
	forwardBD = (rt_d !=0) && (rt_d == writereg_m) && regwrite_m;  



	
	
	
end

endmodule
