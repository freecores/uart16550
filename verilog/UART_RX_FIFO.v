//////////////////////////////////////////////////////////////////////
////                                                              ////
////  UART_RX_FIFO.v                                              ////
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
////  UART core receiver FIFO                                     ////
////                                                              ////
////  Known problems (limits):                                    ////
////  Read the FIFO_inc.v notes                                   ////
////                                                              ////
////  To Do:                                                      ////
////  Nothing.                                                    ////
////                                                              ////
////  Author(s):                                                  ////
////      - gorban@opencores.org                                  ////
////      - Jacob Gorban                                          ////
////                                                              ////
////  Created:        2001/05/12                                  ////
////  Last Updated:   2001/05/17                                  ////
////                  (See log for the revision history)          ////
////                                                              ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Jacob Gorban, gorban@opencores.org        ////
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
// Revision 1.0  2001-05-17 21:27:12+02  jacob
// Initial revision
//
//

`include "timescale.v"
`include "UART_defines.v"

module UART_RX_FIFO (clk, 
	wb_rst_i, data_in, data_out,
// Control signals
	push, // push strobe, active high
	pop,   // pop strobe, active high
// status signals
	underrun,
	overrun,
	count,
	error_bit
	);

output		error_bit;  // a parity or framing error is inside the receiver FIFO.
wire		error_bit;

`include "FIFO_inc.v"

// Additional logic for detection of error conditions (parity and framing) inside the FIFO
// for the Line Status Register bit 7
wire	[`FIFO_REC_WIDTH-1:0]	word0 = fifo[0];
wire	[`FIFO_REC_WIDTH-1:0]	word1 = fifo[1];
wire	[`FIFO_REC_WIDTH-1:0]	word2 = fifo[2];
wire	[`FIFO_REC_WIDTH-1:0]	word3 = fifo[3];
wire	[`FIFO_REC_WIDTH-1:0]	word4 = fifo[4];
wire	[`FIFO_REC_WIDTH-1:0]	word5 = fifo[5];
wire	[`FIFO_REC_WIDTH-1:0]	word6 = fifo[6];
wire	[`FIFO_REC_WIDTH-1:0]	word7 = fifo[7];

wire	[`FIFO_REC_WIDTH-1:0]	word8 = fifo[8];
wire	[`FIFO_REC_WIDTH-1:0]	word9 = fifo[9];
wire	[`FIFO_REC_WIDTH-1:0]	word10 = fifo[10];
wire	[`FIFO_REC_WIDTH-1:0]	word11 = fifo[11];
wire	[`FIFO_REC_WIDTH-1:0]	word12 = fifo[12];
wire	[`FIFO_REC_WIDTH-1:0]	word13 = fifo[13];
wire	[`FIFO_REC_WIDTH-1:0]	word14 = fifo[14];
wire	[`FIFO_REC_WIDTH-1:0]	word15 = fifo[15];

// a 1 is returned if any of the error bits in the fifo is 1
assign	error_bit = |(word0[1:0]  | word1[1:0]  | word2[1:0]  | word3[1:0]  |
		      word4[1:0]  | word5[1:0]  | word6[1:0]  | word7[1:0]  |
		      word8[1:0]  | word9[1:0]  | word10[1:0] | word11[1:0] |
		      word12[1:0] | word13[1:0] | word14[1:0] | word15[1:0] );

endmodule
