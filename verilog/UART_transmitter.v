//////////////////////////////////////////////////////////////////////
////                                                              ////
////  UART_transmitter.v                                          ////
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
////  UART core transmitter logic                                 ////
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
// Revision 1.3  2001/05/27 17:37:49  gorban
// Fixed many bugs. Updated spec. Changed FIFO files structure. See CHANGES.txt file.
//
// Revision 1.2  2001/05/21 19:12:02  gorban
// Corrected some Linter messages.
//
// Revision 1.1  2001/05/17 18:34:18  gorban
// First 'stable' release. Should be sythesizable now. Also added new header.
//
// Revision 1.0  2001-05-17 21:27:12+02  jacob
// Initial revision
//
//

`include "timescale.v"
//`include "UART_defines.v"

module UART_transmitter (clk, wb_rst_i, lcr, tf_push, wb_dat_i, enable,	stx_o, state, tf_count, tx_reset);

input				clk;
input				wb_rst_i;
input	[7:0]			lcr;
input				tf_push;
input	[7:0]			wb_dat_i;
input				enable;
input				tx_reset;
output				stx_o;
output	[2:0]			state;
output	[`FIFO_COUNTER_W-1:0]	tf_count;

reg	[2:0]	state;
reg	[3:0]	counter16;
reg	[2:0]	bit_counter;   // counts the bits to be sent
reg	[6:0]	shift_out;	// output shift register
reg		stx_o;
reg		parity_xor;  // parity of the word
reg		tf_pop;
reg		bit_out;

// TX FIFO instance
//
// Transmitter FIFO signals
wire	[`FIFO_WIDTH-1:0]	tf_data_in;
wire	[`FIFO_WIDTH-1:0]	tf_data_out;
wire				tf_push;
wire				tf_underrun;
wire				tf_overrun;
wire	[`FIFO_COUNTER_W-1:0]	tf_count;

assign tf_data_in = wb_dat_i;

UART_FIFO fifo_tx(	// error bit signal is not used in transmitter FIFO
	.clk(		clk		), 
	.wb_rst_i(	wb_rst_i	),
	.data_in(	tf_data_in	),
	.data_out(	tf_data_out	),
	.push(		tf_push		),
	.pop(		tf_pop		),
	.underrun(	tf_underrun	),
	.overrun(	tf_overrun	),
	.count(		tf_count	),
	.fifo_reset(	tx_reset	)
);

// TRANSMITTER FINAL STATE MACHINE

`define S_IDLE        3'd0
`define S_SEND_START  3'd1
`define S_SEND_BYTE   3'd2
`define S_SEND_PARITY 3'd3
`define S_SEND_STOP   3'd4
`define S_POP_BYTE    3'd5

always @(posedge clk or posedge wb_rst_i)
begin
  if (wb_rst_i)
  begin
	state       <= #1 `S_IDLE;
	stx_o       <= #1 1'b0;
	counter16   <= #1 4'b0;
	shift_out   <= #1 7'b0;
	bit_out     <= #1 1'b0;
	parity_xor  <= #1 1'b0;
	tf_pop      <= #1 1'b0;
	bit_counter <= #1 3'b0;
  end
  else
  if (enable)
  begin
	case (state)
	`S_IDLE	 :	if (~|tf_count) // if tf_count==0
			begin
				state <= #1 `S_IDLE;
				stx_o <= #1 1'b0;
			end
			else
			begin
				tf_pop <= #1 1'b0;
				stx_o  <= #1 1'b0;
				state  <= #1 `S_POP_BYTE;
			end
	`S_POP_BYTE :	begin
				tf_pop <= #1 1'b1;
				case (lcr[/*`LC_BITS*/1:0])  // number of bits in a word
				2'b00 : begin
					bit_counter <= #1 3'b100;
					parity_xor  <= #1 ^tf_data_out[4:0];
				     end
				2'b01 : begin
					bit_counter <= #1 3'b101;
					parity_xor  <= #1 ^tf_data_out[5:0];
				     end
				2'b10 : begin
					bit_counter <= #1 3'b110;
					parity_xor  <= #1 ^tf_data_out[6:0];
				     end
				2'b11 : begin
					bit_counter <= #1 3'b111;
					parity_xor  <= #1 ^tf_data_out[7:0];
				     end
				endcase
				{shift_out[6:0], bit_out} <= #1 tf_data_out;
				state <= #1 `S_SEND_START;
			end
	`S_SEND_START :	begin
				tf_pop <= #1 1'b0;
				if (~|counter16)
					counter16 <= #1 4'b1111;
				else
				if (counter16 == 4'b0001)
				begin
					counter16 <= #1 0;
					state <= #1 `S_SEND_BYTE;
				end
				else
					counter16 <= #1 counter16 - 4'b0001;
				stx_o <= #1 1'b1;
			end
	`S_SEND_BYTE :	begin
				if (~|counter16)
					counter16 <= #1 4'b1111;
				else
				if (counter16 == 4'b0001)
				begin
					if (bit_counter > 3'b0)
					begin
						bit_counter <= #1 bit_counter - 1;
						{shift_out[5:0],bit_out  } <= #1 {shift_out[6:1], shift_out[0]};
						state <= #1 `S_SEND_BYTE;
					end
					else   // end of byte
					if (~lcr[`LC_PE])
					begin
						state <= #1 `S_SEND_STOP;
					end
					else
					begin
						case ({lcr[`LC_EP],lcr[`LC_SP]})
						2'b00:	bit_out <= #1 ~parity_xor;
						2'b01:	bit_out <= #1 1'b1;
						2'b10:	bit_out <= #1 parity_xor;
						2'b11:	bit_out <= #1 1'b0;
						endcase
						state <= #1 `S_SEND_PARITY;
					end
					counter16 <= #1 0;
				end
				else
					counter16 <= #1 counter16 - 4'b0001;
				stx_o <= #1 bit_out; // set output pin
			end
	`S_SEND_PARITY :	begin
				if (~|counter16)
					counter16 <= #1 4'b1111;
				else
				if (counter16 == 4'b0001)
				begin
					counter16 <= #1 4'b0;
					state <= #1 `S_SEND_STOP;
				end
				else
					counter16 <= #1 counter16 - 4'b0001;
				stx_o <= #1 bit_out;
			end
	`S_SEND_STOP :  begin
				if (~|counter16)
					counter16 <= #1 4'b1111;
				else
				if (counter16 == 4'b0001)
				begin
					counter16 <= #1 0;
					state <= #1 `S_IDLE;
				end
				else
					counter16 <= #1 counter16 - 4'b0001;
				stx_o <= #1 1'b0;
			end

		default : // should never get here
			state <= #1 `S_IDLE;
	endcase
  end // end if enable
end // transmitter logic
	
endmodule