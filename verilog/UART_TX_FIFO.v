//////////////////////////////////////////////////////////////////////
////                                                              ////
////  UART_TX_FIFO.v                                              ////
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
////  UART core transmitter FIFO.                                 ////
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
// Revision 1.2  2001/05/17 18:34:18  gorban
// First 'stable' release. Should be sythesizable now. Also added new header.
//
// Revision 1.0  2001-05-17 21:27:13+02  jacob
// Initial revision
//
//

`include "timescale.v"
`include "UART_defines.v"

module UART_TX_FIFO (clk,
	wb_rst_i, data_in, data_out,
// Control signals
	push, // push strobe, active high
	pop,   // pop strobe, active high
// status signals
	underrun,
	overrun,
	count,
	fifo_reset
	);

// FIFO parameters
parameter fifo_width = `FIFO_WIDTH;
parameter fifo_depth = `FIFO_DEPTH;
parameter fifo_pointer_w = `FIFO_POINTER_W;
parameter fifo_counter_w = `FIFO_COUNTER_W;

input				clk;
input				wb_rst_i;
input				push;
input				pop;
input	[fifo_width-1:0]	data_in;
input				fifo_reset;
output	[fifo_width-1:0]	data_out;
output				overrun;
output				underrun;
output	[fifo_counter_w-1:0]	count;

wire	[fifo_width-1:0]	data_out;

// FIFO itself
reg	[fifo_width-1:0]	fifo[fifo_depth-1:0];

// FIFO pointers
reg	[fifo_pointer_w-1:0]	top;
reg	[fifo_pointer_w-1:0]	bottom;

reg	[fifo_counter_w-1:0]	count;
reg				overrun;
reg				underrun;

// These registers and signals are to detect rise of of the signals.
// Not that it slows the maximum rate by 2, meaning you must reset the signals and then
// assert them again for the operation to repeat
// This is done to accomodate wait states
reg				push_delay; 
reg				pop_delay;

wire				push_rise = push_delay & push;
wire				pop_rise  = pop_delay  & pop;

wire [fifo_pointer_w-1:0] top_plus_1 = top + 1;

always @(posedge clk or posedge wb_rst_i)
begin
	if (wb_rst_i)
		push_delay <= #1 1'b0;
	else
		push_delay <= #1 ~push;
end

always @(posedge clk or posedge wb_rst_i)
begin
	if (wb_rst_i)
		pop_delay <= #1 1'b0;
	else
		pop_delay <= #1 ~pop;
end


always @(posedge clk or posedge wb_rst_i) // synchronous FIFO
begin
	if (wb_rst_i)
	begin
		top		<= #1 0;
		bottom		<= #1 1;
		underrun	<= #1 1'b0;
		overrun		<= #1 1'b0;
		count		<= #1 0;
		fifo[0]		<= #1 0;
		fifo[1]		<= #1 0;
		fifo[2]		<= #1 0;
		fifo[3]		<= #1 0;
		fifo[4]		<= #1 0;
		fifo[5]		<= #1 0;
		fifo[6]		<= #1 0;
		fifo[7]		<= #1 0;
		fifo[8]		<= #1 0;
		fifo[9]		<= #1 0;
		fifo[10]	<= #1 0;
		fifo[11]	<= #1 0;
		fifo[12]	<= #1 0;
		fifo[13]	<= #1 0;
		fifo[14]	<= #1 0;
		fifo[15]	<= #1 0;
	end
	else
	if (fifo_reset) begin
		top		<= #1 0;
		bottom		<= #1 1;
		underrun	<= #1 1'b0;
		overrun		<= #1 1'b0;
		count		<= #1 0;
	end
	else
	begin
		case ({push_rise, pop_rise})
		2'b00 : begin
				underrun <= #1 1'b0;
				overrun  <= #1 1'b0;
	 	        end
		2'b10 : if (count==fifo_depth)  // overrun condition
			begin
				overrun   <= #1 1'b1;
				underrun  <= #1 1'b0;
			end
			else
			begin
				top       <= #1 top_plus_1;
				fifo[top_plus_1] <= #1 data_in;
				underrun  <= #1 0;
				overrun   <= #1 0;
				count     <= #1 count + 1;
			end
		2'b01 : if (~|count)
			begin
				underrun <= #1 1'b1;  // underrun condition
				overrun  <= #1 1'b0;
			end
			else
			begin
				bottom   <= #1 bottom + 1;
				underrun <= #1 1'b0;
				overrun  <= #1 1'b0;
				count	 <= #1 count - 1;
			end
		2'b11 : begin
				bottom   <= #1 bottom + 1;
				top       <= #1 top_plus_1;
				fifo[top_plus_1] <= #1 data_in;
				underrun <= #1 1'b0;
				overrun  <= #1 1'b0;
		        end
		endcase
	end

end   // always

// please note though that data_out is only valid one clock after pop signal
assign data_out = fifo[bottom];


endmodule
