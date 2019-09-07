/*
* PROJECT: AQUAXIS Giga Ethernet MAC
* ----------------------------------------------------------------------
*
* IP Controller with Gigabit MAC
* File: aq_gemac_ip.v
* Copyright (C) 2007-2013 H.Ishihara, http://www.aquaxis.com/
*
* Permission is hereby granted, free of charge, to any person obtaining
* a copy of this software and associated documentation files (the
* "Software"), to deal in the Software without restriction, including
* without limitation the rights to use, copy, modify, merge, publish,
* distribute, sublicense, and/or sell copies of the Software, and to
* permit persons to whom the Software is furnished to do so, subject to
* the following conditions:
*
* The above copyright notice and this permission notice shall be
* included in all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
* NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
* LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
* OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
* WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*
* For further information please contact.
*   http://www.aquaxis.com/
*   info(at)aquaxis.com or hidemi(at)sweetcafe.jp
*
* 2012/05/28 H.Ishihara	Create
* 2013/02/15 H.Ishiahra	Modify for signal name
*/
`timescale 1ps / 1ps

module aq_gemac_ip2
(
	input			RST_N,
	input			SYS_CLK,

	// GEMAC Interface
	input			EMAC_TX_CLK,
	output [7:0]	EMAC_TXD,
	output			EMAC_TX_EN,
	output			EMAC_TX_ER,
	input			EMAC_RX_CLK,
	input [7:0]		EMAC_RXD,
	input			EMAC_RX_DV,
	input			EMAC_RX_ER,
	input			EMAC_COL,
	input			EMAC_CRS,

	// RX Buffer Interface
	input			RX_BUFF_RE,			// RX Buffer Read Enable
	output [31:0]	RX_BUFF_DATA,		// RX Buffer Data
	output			RX_BUFF_EMPTY,		// RX Buffer Empty(1: Empty, 0: No Empty)
	output			RX_BUFF_VALID,		// RX Buffer Valid
	output [15:0]	RX_BUFF_LENGTH,		// RX Buffer Length
	output [15:0]	RX_BUFF_STATUS,		// RX Buffer Status

	// TX Buffer Interface
	input			TX_BUFF_WE,			// TX Buffer Write Enable
	input			TX_BUFF_START,		// TX Buffer Data Start
	input			TX_BUFF_END,		// TX Buffer Data End
	output			TX_BUFF_READY,		// TX Buffer Ready
	input [31:0]	TX_BUFF_DATA,		// TX Buffer Data
	output			TX_BUFF_FULL,		// TX Buffer Full
	output [9:0]	TX_BUFF_SPACE,		// TX Buffer Space

	// From CPU
	input [15:0]	PAUSE_QUANTA_DATA,	// Pause Quanta value
	input			PAUSE_SEND_ENABLE,	// Pause Send Enable
	input			TX_PAUSE_ENABLE,	// TX MAC Pause Enable

	output [47:0]	PEER_MAC_ADDRESS,
	input [31:0]	PEER_IP_ADDRESS,
	input [47:0]	MY_MAC_ADDRESS,
	input [31:0]	MY_IP_ADDRESS,

	output			ARPC_ENABLE,		// ARP Cache Request Enable
	input			ARPC_REQUEST,		// ARP Cache Request
	output			ARPC_VALID,			// ARP Cache Valid

	input [3:0]		MAX_RETRY,			// Max Retry
	input			GIG_MODE,			// Operation Mode(1: Giga Mode, 0: 10/100Mbps)
	input			FULL_DUPLEX,		// Operation Mode(1: Full Duplex, 0: Half Duplex)

 output [15:0] L3_EXT_STATUS
);

	wire		tx_buff_we, tx_buff_start, tx_buff_end, tx_buff_ready, tx_buff_full;
	wire [31:0]	tx_buff_data;
	wire [9:0]	tx_buff_space;

	wire		rx_buff_re, rx_buff_empty, rx_buff_valid;
	wire [31:0]	rx_buff_data;
	wire [15:0]	rx_buff_length;
	wire [15:0]	rx_buff_status;

	wire		etx_buff_we, etx_buff_start, etx_buff_end, etx_buff_ready, etx_buff_full;
	wire [31:0]	etx_buff_data;
	wire [9:0]	etx_buff_space;

	wire		erx_buff_re;
	wire		erx_buff_empty, erx_buff_valid;
	wire [31:0]	erx_buff_data;
	wire [15:0]	erx_buff_length;
	wire [15:0]	erx_buff_status;

	wire		random_time_meet;
	wire [3:0]	max_retry;
	wire		giga_mode;
	wire		full_duplex;

//	wire [15:0]	l3_ext_status;
	wire		tx_clk, rx_clk;

	// Layer 3 Controller
	aq_gemac_l3_ctrl u_aq_gemac_l3_ctrl(
		.RST_N				( RST_N					),
		.CLK				( SYS_CLK				),

		// RX Buffer Interface
		.RX_BUFF_RE			( rx_buff_re			),
		.RX_BUFF_DATA		( rx_buff_data			),
		.RX_BUFF_EMPTY		( rx_buff_empty			),
		.RX_BUFF_VALID		( rx_buff_valid			),
		.RX_BUFF_LENGTH		( rx_buff_length		),
		.RX_BUFF_STATUS		( rx_buff_status		),

		// TX Buffer Interface
		.TX_BUFF_WE			( tx_buff_we			),
		.TX_BUFF_START		( tx_buff_start			),
		.TX_BUFF_END		( tx_buff_end			),
		.TX_BUFF_READY		( tx_buff_ready			),
		.TX_BUFF_DATA		( tx_buff_data			),
		.TX_BUFF_FULL		( tx_buff_full			),
		.TX_BUFF_SPACE		( tx_buff_space			),

		// External RX Buffer Interface
		.ERX_BUFF_RE		( RX_BUFF_RE			),
		.ERX_BUFF_DATA		( RX_BUFF_DATA			),
		.ERX_BUFF_EMPTY		( RX_BUFF_EMPTY		),
		.ERX_BUFF_VALID		( RX_BUFF_VALID		),
		.ERX_BUFF_LENGTH	( RX_BUFF_LENGTH		),
		.ERX_BUFF_STATUS	( RX_BUFF_STATUS		),

		// External TX Buffer Interface
		.ETX_BUFF_WE		( TX_BUFF_WE			),
		.ETX_BUFF_START		( TX_BUFF_START		),
		.ETX_BUFF_END		( TX_BUFF_END			),
		.ETX_BUFF_READY		( TX_BUFF_READY		),
		.ETX_BUFF_DATA		( TX_BUFF_DATA			),
		.ETX_BUFF_FULL		( TX_BUFF_FULL			),
		.ETX_BUFF_SPACE		( TX_BUFF_SPACE		),

		.MAC_ADDRESS		( MY_MAC_ADDRESS		),
		.IP_ADDRESS			( MY_IP_ADDRESS			),

		.ARPC_ENABLE		( ARPC_ENABLE			),
		.ARPC_REQUEST		( ARPC_REQUEST			),
		.ARPC_VALID			( ARPC_VALID			),
		.ARPC_IP_ADDRESS	( PEER_IP_ADDRESS		),
		.ARPC_MAC_ADDRESS   ( PEER_MAC_ADDRESS		),

		.STATUS				( L3_EXT_STATUS			)
	);

	// Giga Ethernet MAC
	aq_gemac u_aq_gemac(
		.RST_N				( RST_N				),

		// GMII,MII Interface
		.TX_CLK				( EMAC_TX_CLK		),
		.TXD				( EMAC_TXD			),
		.TX_EN				( EMAC_TX_EN		),
		.TX_ER				( EMAC_TX_ER		),
		.RX_CLK				( EMAC_RX_CLK		),
		.RXD				( EMAC_RXD			),
		.RX_DV				( EMAC_RX_DV		),
		.RX_ER				( EMAC_RX_ER		),
		.COL				( EMAC_COL			),
		.CRS				( EMAC_CRS			),

		// System Clock
		.CLK				( SYS_CLK			),

		// RX Buffer Interface
		.RX_BUFF_RE			( rx_buff_re		),
		.RX_BUFF_DATA		( rx_buff_data		),
		.RX_BUFF_EMPTY		( rx_buff_empty		),
		.RX_BUFF_VALID		( rx_buff_valid		),
		.RX_BUFF_LENGTH		( rx_buff_length	),
		.RX_BUFF_STATUS		( rx_buff_status	),

		// TX Buffer Interface
		.TX_BUFF_WE			( tx_buff_we		),
		.TX_BUFF_START		( tx_buff_start		),
		.TX_BUFF_END		( tx_buff_end		),
		.TX_BUFF_READY		( tx_buff_ready		),
		.TX_BUFF_DATA		( tx_buff_data		),
		.TX_BUFF_FULL		( tx_buff_full		),
		.TX_BUFF_SPACE		( tx_buff_space		),

		// From CPU
		.PAUSE_QUANTA_DATA	( PAUSE_QUANTA_DATA	),
		.PAUSE_SEND_ENABLE	( PAUSE_SEND_ENABLE	),
		.TX_PAUSE_ENABLE	( TX_PAUSE_ENABLE	),

		// Setting
		.RANDOM_TIME_MEET   ( random_time_meet	),
		.MAC_ADDRESS		( MY_MAC_ADDRESS	),
		.IP_ADDRESS			( MY_IP_ADDRESS		),
		.PORT0				( REC_DST_PORT0		),
		.PORT1				( REC_DST_PORT1		),
		.PORT2				( REC_DST_PORT2		),
		.PORT3				( REC_DST_PORT3		),
		.MAX_RETRY			( MAX_RETRY			),
		.GIG_MODE			( GIG_MODE			),
		.FULL_DUPLEX		( FULL_DUPLEX		)
	);

endmodule
