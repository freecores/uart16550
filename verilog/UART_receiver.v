//////////////////////////////////////////////////////////////////////
////                                                              ////
////  UART_receiver.v                                             ////
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
////  UART core receiver logic                                    ////
////                                                              ////
////  Known problems (limits):                                    ////
////  None known                                                  ////
////                                                              ////
////  To Do:                                                      ////
////  Thourough testing.                                          ////
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
// Revision 1.1  2001/05/17 18:34:18  gorban
// First 'stable' release. Should be sythesizable now. Also added new header.
//
// Revision 1.0  2001-05-17 21:27:11+02  jacob
// Initial revision
//
//

`include "timescale.v"
`include "UART_defines.v"

module UART_receiver (clk, wb_rst_i, lcr, rf_pop, srx_i, enable, rda_int,
	counter_t, counter_b, rf_count, rf_data_out, rf_error_bit, rf_overrun);

input				clk;
input				wb_rst_i;
input	[7:0]			lcr;
input				rf_pop;
input				srx_i;
input				enable;
input				rda_int;

output	[5:0]			counter_t;
output	[3:0]			counter_b;
output	[`FIFO_COUNTER_W-1:0]	rf_count;
output	[`FIFO_REC_WIDTH-1:0]	rf_data_out;
output				rf_overrun;
output				rf_error_bit;

reg	[3:0]	rstate;
reg	[3:0]	rcounter16;
reg	[2:0]	rbit_counter;
reg	[7:0]	rshift;			// receiver shift register
reg		rparity;		// received parity
reg		rparity_error;
reg		rframing_error;		// framing error flag
reg		rbit_in;
reg		rparity_xor;

// RX FIFO signals
reg	[`FIFO_REC_WIDTH-1:0]	rf_data_in;
wire	[`FIFO_REC_WIDTH-1:0]	rf_data_out;
reg				rf_push;
wire				rf_pop;
wire				rf_underrun;
wire				rf_overrun;
wire	[`FIFO_COUNTER_W-1:0]	rf_count;
wire				rf_error_bit; // an error (parity or framing) is inside the fifo

// RX FIFO instance
UART_RX_FIFO fifo_rx(clk, wb_rst_i, rf_data_in, rf_data_out,
	rf_push, rf_pop, rf_underrun, rf_overrun, rf_count, rf_error_bit);

// Receiver FIFO parameters redefine
defparam fifo_rx.fifo_width = `FIFO_REC_WIDTH;


wire		rcounter16_eq_7 = (rcounter16 == 4'd7);
wire		rcounter16_eq_0 = (rcounter16 == 4'd0);
wire	[3:0]	rcounter16_minus_1 = rcounter16 - 4'd1;

`define SR_IDLE		4'd0
`define SR_REC_START	4'd1
`define SR_REC_BIT	4'd2
`define	SR_REC_PARITY	4'd3
`define SR_REC_STOP	4'd4
`define SR_CHECK_PARITY	4'd5
`define SR_REC_PREPARE	4'd6
`define SR_END_BIT	4'd7
`define SR_CALC_PARITY	4'd8
`define SR_WAIT1	4'd9
`define SR_PUSH		4'd10
`define SR_LAST		4'd11

always @(posedge clk or posedge wb_rst_i)
begin
  if (wb_rst_i)
  begin
	rstate		<= #1 `SR_IDLE;
	rbit_in		<= #1 1'b0;
	rcounter16	<= #1 0;
	rbit_counter	<= #1 0;
	rparity_xor	<= #1 1'b0;
	rframing_error	<= #1 1'b0;
	rparity_error	<= #1 1'b0;
	rparity		<= #1 1'b0;
	rshift		<= #1 0;
	rf_push		<= #1 1'b0;
	rf_data_in	<= #1 0;
  end
  else
  if (enable)
  begin
	case (rstate)
	`SR_IDLE :	if (srx_i==1'b1)   // detected a pulse (start bit?)
			begin
				rstate <= #1 `SR_REC_START;
				rcounter16 <= #1 4'b1110;
			end
			else
				rstate <= #1 `SR_IDLE;
	`SR_REC_START :	begin
				if (rcounter16_eq_7)    // check the pulse
					if (srx_i==1'b0)   // no start bit
						rstate <= #1 `SR_IDLE;
					else            // start bit detected
						rstate <= #1 `SR_REC_PREPARE;
				rcounter16 <= #1 rcounter16_minus_1;
			end
	`SR_REC_PREPARE:begin
				case (lcr[/*`LC_BITS*/1:0])  // number of bits in a word
				2'b00 : rbit_counter <= #1 3'b100;
				2'b01 : rbit_counter <= #1 3'b101;
				2'b10 : rbit_counter <= #1 3'b110;
				2'b11 : rbit_counter <= #1 3'b111;
				endcase
				if (rcounter16_eq_0)
				begin
					rstate		<= #1 `SR_REC_BIT;
					rcounter16	<= #1 4'b1110;
					rshift		<= #1 0;
				end
				else
					rstate <= #1 `SR_REC_PREPARE;
				rcounter16 <= #1 rcounter16_minus_1;
			end
	`SR_REC_BIT :	begin
				if (rcounter16_eq_0)
					rstate <= #1 `SR_END_BIT;
				if (rcounter16_eq_7) // read the bit
					case (lcr[/*`LC_BITS*/1:0])  // number of bits in a word
					2'b00 : rshift[4:0]  <= #1 {srx_i, rshift[4:1]};
					2'b01 : rshift[5:0]  <= #1 {srx_i, rshift[5:1]};
					2'b10 : rshift[6:0]  <= #1 {srx_i, rshift[6:1]};
					2'b11 : rshift[7:0]  <= #1 {srx_i, rshift[7:1]};
					endcase
				rcounter16 <= #1 rcounter16_minus_1;
			end
	`SR_END_BIT :   begin
				if (rbit_counter==3'b0) // no more bits in word
					if (lcr[`LC_PE]) // choose state based on parity
						rstate <= #1 `SR_REC_PARITY;
					else
					begin
						rstate <= #1 `SR_REC_STOP;
						rparity_error <= #1 1'b0;  // no parity - no error :)
					end
				else		// else we have more bits to read
				begin
					rstate <= #1 `SR_REC_BIT;
					rbit_counter <= #1 rbit_counter - 3'b1;
				end
				rcounter16 <= #1 4'b1110;
			end
	`SR_REC_PARITY: begin
				if (rcounter16_eq_7)	// read the parity
				begin
					rparity <= #1 srx_i;
					rstate <= #1 `SR_CALC_PARITY;
				end
				rcounter16 <= #1 rcounter16_minus_1;
			end
	`SR_CALC_PARITY : begin    // rcounter equals 6
				rcounter16  <= #1 rcounter16_minus_1;
				rparity_xor <= #1 ^{rshift,rparity}; // calculate parity on all incoming data
				rstate      <= #1 `SR_CHECK_PARITY;
			  end
	`SR_CHECK_PARITY: begin	  // rcounter equals 5
				case ({lcr[`LC_EP],lcr[`LC_SP]})
				2'b00: rparity_error <= #1 ~rparity_xor;  // no error if parity 1
				2'b01: rparity_error <= #1 ~rparity;      // parity should sticked to 1
				2'b10: rparity_error <= #1 rparity_xor;   // error if parity is odd
				2'b11: rparity_error <= #1 rparity;	  // parity should be sticked to 0
				endcase
				rcounter16 <= #1 rcounter16_minus_1;
				rstate <= #1 `SR_WAIT1;
			  end
	`SR_WAIT1 :	if (rcounter16_eq_0)
			begin
				rstate <= #1 `SR_REC_STOP;
				rcounter16 <= #1 4'b1110;
			end
			else
				rcounter16 <= #1 rcounter16_minus_1;
	`SR_REC_STOP :	begin
				if (rcounter16_eq_7)	// read the parity
				begin
					rframing_error <= #1 srx_i; // no framing error if input is 0 (stop bit)
					rf_data_in <= #1 {rshift, rparity_error, rframing_error};
					rstate <= #1 `SR_PUSH;
				end
				rcounter16 <= #1 rcounter16_minus_1;
			end
	`SR_PUSH :	begin
///////////////////////////////////////
//				$display($time, ": received: %b", rf_data_in);
				rf_push    <= #1 1'b1;
				rstate     <= #1 `SR_LAST;
			end
	`SR_LAST :	begin
				if (rcounter16_eq_0)
					rstate <= #1 `SR_IDLE;
				rcounter16 <= #1 rcounter16_minus_1;
				rf_push    <= #1 1'b0;
			end
	default : rstate <= #1 `SR_IDLE;
	endcase
  end  // if (enable)
end // always of receiver

//
// Break condition detection.
// Works in conjuction with the receiver state machine
reg	[3:0]	counter_b;	// counts the 0 signals

always @(posedge clk or posedge wb_rst_i)
begin
	if (wb_rst_i)
		counter_b <= #1 4'd11;
	else
	if (enable)  // only work on enable times
		if (srx_i)
			counter_b <= #1 4'd11; // maximum character time length - 1
		else
			if (counter_b != 4'b0)            // break reached
				counter_b <= #1 counter_b - 4'd1;  // decrement break counter
end // always of break condition detection

///
/// Timeout condition detection
reg	[5:0]	counter_t;	// counts the timeout condition clocks

always @(posedge clk or posedge wb_rst_i)
begin
	if (wb_rst_i)
		counter_t <= #1 6'd44;
	else
	if (enable)
		if(rf_push || rf_pop || rda_int) // counter is reset when RX FIFO is accessed or above trigger level
			counter_t <= #1 6'd44;
		else
			if (counter_t != 6'b0)  // we don't want to underflow
				counter_t <= #1 counter_t - 6'd1;		
end
	
endmodule