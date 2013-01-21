/*
* PROJECT: AQUAXIS Giga Ethernet MAC
* ----------------------------------------------------------------------
*
* Gigabit MAC
* File: aq_gemac.v
* Copyright (C) 2007-2012 H.Ishihara, http://www.aquaxis.com/
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
* 2007/06/01	H.Ishihara	Create
* 2011/04/24	rename
*/
module aq_gemac(
	// System Reset
	input			RST_N,				// System Reset

	// GMII,MII Interface
	input			TX_CLK,				// TX Clock(GigaMode: 125MHz. 10/100Mbps: 25MHz)
	output [7:0]	TXD,				// TX Data
	output			TX_EN,				// TX Data Enable
	output			TX_ER,				// TX Data Error
	input			RX_CLK,				// RX Clock
	input [7:0]		RXD,				// RX Data
	input			RX_DV,				// RX Data Valid
	input			RX_ER,				// RX Data Error
	input			COL,				// Collision
	input			CRS,				// Carry Sence signal

	// System Clock
	input			CLK,				// System Clock

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

	// Setting
	input			RANDOM_TIME_MEET,	//
	input [47:0]	MAC_ADDRESS,		// Mac Address
	input [31:0]	IP_ADDRESS,			// IP Address
	input [15:0]	PORT0,
	input [15:0]	PORT1,
	input [15:0]	PORT2,
	input [15:0]	PORT3,
	input [3:0]		MAX_RETRY,			// Max Retry
	input			GIG_MODE,			// Operation Mode(1: Giga Mode, 0: 10/100Mbps)
	input			FULL_DUPLEX			// Operation Mode(1: Full Duplex, 0: Half Duplex)
);

	wire			rx_mac_we;
	wire			rx_mac_start;
	wire			rx_mac_end;
	wire [15:0]		rx_mac_status;
	wire [7:0]		rx_mac_data;
	wire			rx_mac_full;

	wire			pause_quanta_valid;
	wire [15:0]		pause_quanta;
	wire			pause_quanta_complete;

	wire			tx_mac_req;
	wire			tx_mac_re;
	wire			tx_mac_eop;
	wire			tx_mac_finish;
	wire			tx_mac_retry;
	wire [7:0]		tx_mac_data;

	wire			pause_apply;
	wire			pause_quanta_sub;

	aq_gemac_rx_mac u_aq_gemac_rx_mac(
		.RST_N					( RST_N					),
		.CLK					( RX_CLK				),

		.RX_D					( RXD					),
		.RX_DV					( RX_DV					),
		.RX_ER					( RX_ER					),

		.BUFF_WE				( rx_mac_we				),
		.BUFF_START				( rx_mac_start			),
		.BUFF_END				( rx_mac_end			),
		.BUFF_STATUS			( rx_mac_status			),
		.BUFF_DATA				( rx_mac_data			),
		.BUFF_FULL				( rx_mac_full			),

		.PAUSE_QUANTA_VALID		( pause_quanta_valid	),
		.PAUSE_QUANTA			( pause_quanta			),
		.PAUSE_QUANTA_COMPLETE	( pause_quanta_complete	),

		.GIG_MODE				( GIG_MODE				),

		.MAC_ADDRESS			( MAC_ADDRESS			),
		.IP_ADDRESS				( IP_ADDRESS			),

		.PORT0					( PORT0					),
		.PORT1					( PORT1					),
		.PORT2					( PORT2					),
		.PORT3					( PORT3					)
	);

	aq_gemac_rx_buff u_aq_gemac_rx_buff(
		.RST_N			( RST_N				),

		.MAC_CLK		( RX_CLK			),
		.MAC_WE			( rx_mac_we			),
		.MAC_START		( rx_mac_start		),
		.MAC_END		( rx_mac_end		),
		.MAC_STATUS		( rx_mac_status		),
		.MAC_DATA		( rx_mac_data		),
		.MAC_FULL		( rx_mac_full		),

		.BUFF_CLK		( CLK				),
		.BUFF_RE		( RX_BUFF_RE		),
		.BUFF_EMPTY		( RX_BUFF_EMPTY		),
		.BUFF_DATA		( RX_BUFF_DATA		),

		.FRAME_VALID	( RX_BUFF_VALID		),
		.FRAME_LENGTH   ( RX_BUFF_LENGTH	),
		.FRAME_STATUS   ( RX_BUFF_STATUS	)
	);

	aq_gemac_flow_ctrl u_aq_gemac_flow_ctrl(
		.RST_N					( RST_N					),
		.CLK					( CLK					),

		.TX_PAUSE_ENABLE		( TX_PAUSE_ENABLE		),

		.PAUSE_QUANTA_VALID		( pause_quanta_valid	),
		.PAUSE_QUANTA			( pause_quanta			),
		.PAUSE_QUANTA_COMPLETE	( pause_quanta_complete	),

		.PAUSE_APPLY			( pause_apply			),
		.PAUSE_QUANTA_SUB		( pause_quanta_sub		)
	);

	aq_gemac_tx_buff u_aq_gemac_tx_buff(
		.RST_N			( RST_N			),

		.BUFF_CLK		( CLK			),
		.BUFF_WE		( TX_BUFF_WE	),
		.BUFF_START		( TX_BUFF_START	),
		.BUFF_END		( TX_BUFF_END	),
		.BUFF_READY		( TX_BUFF_READY	),
		.BUFF_DATA		( TX_BUFF_DATA	),
		.BUFF_FULL		( TX_BUFF_FULL	),
		.BUFF_SPACE		( TX_BUFF_SPACE	),

		.MAC_CLK		( TX_CLK		),
		.MAC_REQ		( tx_mac_req	),
		.MAC_RE			( tx_mac_re		),
		.MAC_EOP		( tx_mac_eop	),
		.MAC_FINISH		( tx_mac_finish	),
		.MAC_RETRY		( tx_mac_retry	),
		.MAC_DATA		( tx_mac_data	)
	);

	aq_gemac_tx_mac u_aq_gemac_tx_mac(
		.RST_N				( RST_N				),
		.CLK				( TX_CLK			),

		.TX_D				( TXD				),
		.TX_EN				( TX_EN				),
		.TX_ER				( TX_ER				),
		.TX_CRS				( CRS				),

		.TX_REQ				( tx_mac_req		),

		.BUFF_RD			( tx_mac_re			),
		.BUFF_EOP			( tx_mac_eop		),
		.BUFF_FINISH		( tx_mac_finish		),
		.BUFF_RETRY			( tx_mac_retry		),
		.BUFF_DATA			( tx_mac_data		),

		.PAUSE_QUANTA_DATA	( PAUSE_QUANTA_DATA	),
		.PAUSE_SEND_ENABLE	( PAUSE_SEND_ENABLE	),

		.PAUSE_APPLY		( pause_apply		),
		.PAUSE_QUANTA_SUB	( pause_quanta_sub	),

		.MAC_ADDRESS		( MAC_ADDRESS		),
		.RANDOM_TIME_MEET	( RANDOM_TIME_MEET	),
		.MAX_RETRY			( MAX_RETRY			),
		.GIG_MODE			( GIG_MODE			),
		.FULL_DUPLEX		( FULL_DUPLEX		)
	);

endmodule
