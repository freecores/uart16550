//////////////////////////////////////////////////////////////////////
////                                                              ////
////  UART_defines.v                                              ////
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
////  Defines of the Core                                         ////
////                                                              ////
////  Known problems (limits):                                    ////
////  None                                                        ////
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
// Revision 1.4  2001/05/21 19:12:02  gorban
// Corrected some Linter messages.
//
// Revision 1.3  2001/05/17 18:34:18  gorban
// First 'stable' release. Should be sythesizable now. Also added new header.
//
// Revision 1.0  2001-05-17 21:27:11+02  jacob
// Initial revision
//
//

`define ADDR_WIDTH	3

// Register addresses
`define REG_RB	3'd0	// receiver buffer
`define REG_TR  3'd0	// transmitter
`define REG_IE	3'd1	// Interrupt enable
`define REG_II  3'd2	// Interrupt identification
`define REG_FC  3'd2	// FIFO control
`define REG_LC	3'd3	// Line Control
`define REG_MC	3'd4	// Modem control
`define REG_LS  3'd5	// Line status
`define REG_MS  3'd6	// Modem status
`define REG_DL1	3'd0	// Divisor latch bytes (1-4)
`define REG_DL2	3'd1
`define REG_DL3	3'd4
`define REG_DL4	3'd5

// Interrupt Enable register bits
`define IE_RDA	0	// Received Data available interrupt
`define IE_THRE	1	// Transmitter Holding Register empty interrupt
`define IE_RLS	2	// Receiver Line Status Interrupt
`define	IE_MS	3	// Modem Status Interrupt

// Interrupt Identification register bits
`define II_IP	0	// Interrupt pending when 0
`define II_II	3:1	// Interrupt identification

// Interrupt identification values for bits 3:1
`define II_RLS	3'b011	// Receiver Line Status
`define II_RDA	3'b010	// Receiver Data available
`define II_TI	3'b110	// Timeout Indication
`define II_THRE	3'b001	// Transmitter Holding Register empty
`define II_MS	3'b000	// Modem Status

// FIFO Control Register bits
`define FC_TL	1:0	// Trigger level

// FIFO trigger level values
`define FC_1	2'b00
`define FC_4	2'b01
`define FC_8	2'b10
`define FC_14	2'b11

// Line Control register bits
`define LC_BITS	1:0	// bits in character
`define LC_SB	2	// stop bits
`define LC_PE	3	// parity enable
`define LC_EP	4	// even parity
`define LC_SP	5	// stick parity
`define LC_BC	6	// Break control
`define	LC_DL	7	// Divisor Latch access bit

// Modem Control register bits
`define MC_DTR	0
`define MC_RTS	1
`define MC_OUT1	2
`define	MC_OUT2	3
`define	MC_LB	4	// Loopback mode

// Line Status Register bits
`define LS_DR	0	// Data ready
`define LS_OE	1	// Overrun Error
`define LS_PE	2	// Parity Error
`define	LS_FE	3	// Framing Error
`define LS_BI	4	// Break interrupt
`define LS_TFE	5	// Transmit FIFO is empty
`define LS_TE	6	// Transmitter Empty indicator
`define LS_EI	7	// Error indicator

// Modem Status Register bits
`define MS_DCTS	0	// Delta signals
`define MS_DDSR	1
`define MS_TERI	2
`define	MS_DDCD	3
`define MS_CCTS	4	// Complement signals
`define MS_CDSR	5
`define MS_CRI	6
`define	MS_CDCD	7


// FIFO parameter defines

`define FIFO_WIDTH	8
`define FIFO_DEPTH	16
`define FIFO_POINTER_W	4
`define FIFO_COUNTER_W	5
// receiver fifo has width 10 because it has parity and framing error bits
`define FIFO_REC_WIDTH  10
