//////////////////////////////////////////////////////////////////////
////                                                              ////
////  uart_wb.v                                                   ////
////                                                              ////
////                                                              ////
////  This file is part of the "UART 16550 compatible" project    ////
////  http://www.opencores.org/cores/uart16550/                   ////
////                                                              ////
////  Documentation related to this project:                      ////
////  - http://www.opencores.org/cores/uart16550/                 ////
////                                                              ////
////  Projects compatibility:                                     ////
////  - WISHBONE                                                  ////
////  RS232 Protocol                                              ////
////  16550D uart (mostly supported)                              ////
////                                                              ////
////  Overview (main Features):                                   ////
////  UART core WISHBONE interface.                               ////
////                                                              ////
////  Known problems (limits):                                    ////
////  Inserts one wait state on all transfers.                    ////
////  Note affected signals and the way they are affected.        ////
////                                                              ////
////  To Do:                                                      ////
////  Nothing.                                                    ////
////                                                              ////
////  Author(s):                                                  ////
////      - gorban@opencores.org                                  ////
////      - Jacob Gorban                                          ////
////      - Igor Mohor (igorm@opencores.org)                      ////
////                                                              ////
////  Created:        2001/05/12                                  ////
////  Last Updated:   2001/05/17                                  ////
////                  (See log for the revision history)          ////
////                                                              ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000, 2001 Authors                             ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
//
// CVS Revision History
//
// $Log: not supported by cvs2svn $
// Revision 1.9  2001/10/20 09:58:40  gorban
// Small synopsis fixes
//
// Revision 1.8  2001/08/24 21:01:12  mohor
// Things connected to parity changed.
// Clock devider changed.
//
// Revision 1.7  2001/08/23 16:05:05  mohor
// Stop bit bug fixed.
// Parity bug fixed.
// WISHBONE read cycle bug fixed,
// OE indicator (Overrun Error) bug fixed.
// PE indicator (Parity Error) bug fixed.
// Register read bug fixed.
//
// Revision 1.4  2001/05/31 20:08:01  gorban
// FIFO changes and other corrections.
//
// Revision 1.3  2001/05/21 19:12:01  gorban
// Corrected some Linter messages.
//
// Revision 1.2  2001/05/17 18:34:18  gorban
// First 'stable' release. Should be sythesizable now. Also added new header.
//
// Revision 1.0  2001-05-17 21:27:13+02  jacob
// Initial revision
//
//

// UART core WISHBONE interface 
//
// Author: Jacob Gorban   (jacob.gorban@flextronicssemi.com)
// Company: Flextronics Semiconductor
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on

module uart_wb (clk, wb_rst_i, 
	wb_we_i, wb_stb_i, wb_cyc_i, wb_ack_o,
	wb_dat_i, wb_dat_o, wb_dat8_i, wb_dat8_o, wb_dat32_o, wb_sel_i,
	we_o, re_o // Write and read enable output for the core
);

input 		  clk;

// WISHBONE interface	
input 		  wb_rst_i;
input 		  wb_we_i;
input 		  wb_stb_i;
input 		  wb_cyc_i;
input [3:0]   wb_sel_i;
`ifdef DATA_BUS_WIDTH_8
input [7:0]  wb_dat_i; //input WISHBONE bus 
output [7:0] wb_dat_o;
reg [7:0] 	 wb_dat_o;
wire [7:0] 	 wb_dat_i;
`else // for 32 data bus mode
input [31:0]  wb_dat_i; //input WISHBONE bus 
output [31:0] wb_dat_o;
reg [31:0] 	  wb_dat_o;
wire [31:0]   wb_dat_i;
`endif
input [7:0]   wb_dat8_o; // internal 8 bit output to be put into wb_dat_o
output [7:0]  wb_dat8_i;
input [31:0]  wb_dat32_o; // 32 bit data output (for debug interface)
output 		  wb_ack_o;
output 		  we_o;
output 		  re_o;

wire 			  we_o;
reg 			  wb_ack_o;
reg [7:0] 	  wb_dat8_i;
wire [7:0] 	  wb_dat8_o;

always @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i) 
		wb_ack_o <= #1 1'b0;
	else 
		wb_ack_o <= #1 wb_stb_i & wb_cyc_i & ~wb_ack_o; // 1 clock wait state on all transfers

assign we_o =  wb_we_i & wb_cyc_i & wb_stb_i; //WE for registers	
assign re_o = ~wb_we_i & wb_cyc_i & wb_stb_i; //RE for registers	

`ifdef DATA_BUS_WIDTH_8 // 8-bit data bus
always @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i)
		wb_dat_o <= #1 0;
	else
		wb_dat_o <= #1 wb_dat8_o;

always @(wb_dat_i)
	wb_dat8_i = wb_dat_i;

`else // 32-bit bus
// put output to the correct byte in 32 bits using select line
always @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i)
		wb_dat_o <= #1 0;
	else if (re_o)
		case (wb_sel_i)
			4'b0001: wb_dat_o <= #1 {24'b0, wb_dat8_o};
			4'b0010: wb_dat_o <= #1 {16'b0, wb_dat8_o, 8'b0};
			4'b0100: wb_dat_o <= #1 {8'b0, wb_dat8_o, 16'b0};
			4'b1000: wb_dat_o <= #1 {wb_dat8_o, 24'b0};
			4'b1111: wb_dat_o <= #1 wb_dat32_o; // debug interface output
 			default: wb_dat_o <= #1 0;
			// later add here selects for 16 and 32 bits
		endcase // case(wb_sel_i)

// handle input (this will add a little timing overhead on input but it should asynchronous
// or another one clock delay will be introduced)
always @(wb_sel_i or wb_dat_i)
	case (wb_sel_i)
		4'b0001 : wb_dat8_i = wb_dat_i[7:0];
		4'b0010 : wb_dat8_i = wb_dat_i[15:8];
		4'b0100 : wb_dat8_i = wb_dat_i[23:16];
		4'b1000 : wb_dat8_i = wb_dat_i[31:24];
		default : wb_dat8_i = wb_dat_i[7:0];
	endcase // case(wb_sel_i)

`endif // !`ifdef DATA_BUS_WIDTH_8

endmodule










