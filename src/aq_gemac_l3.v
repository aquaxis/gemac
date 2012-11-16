/*
* PROJECT: AQUAXIS Giga Ethernet MAC
* ----------------------------------------------------------------------
*
* aq_gemac_l3.v
* Copyright (C)2007-2011 H.Ishihara
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*
* For further information please contact.
*	http://www.aquaxis.com/
*	info(at)aquaxis.com or hidemi(at)sweetcafe.jp
*
* Create 2007/06/01 H.Ishihara
* 2007/01/06 1st release
* 2011/04/24 rename
*/
`timescale 1ps / 1ps

module aq_gemac_l3(
	input		RST_N,
	input		CLK,

	input			EMAC_TX_CLK,	// Tx Clock(In)  for 10/100 Mode
	output [7:0]	EMAC_TXD,		// Tx Data
	output			EMAC_TX_EN,		// Tx Data Enable
	output			EMAC_TX_ER,		// Tx Error
	input			EMAC_COL,		// Collision signal
	input			EMAC_CRS,		// CRS

	input			EMAC_RX_CLK,	// Rx Clock(In)  for 10/100/1000 Mode
	input [7:0]		EMAC_RXD,		// Rx Data
	input			EMAC_RX_DV,		// Rx Data Valid
	input			EMAC_RX_ER		// Rx Error
);

	wire			EMAC_CLK125M;
	assign			EMAC_CLK125M = 1'b0;

	wire			EMAC_GTX_CLK;

	wire			sys_clk;

	wire		tx_buff_we, tx_buff_start, tx_buff_end, tx_buff_ready, tx_buff_full;
	wire [31:0]	tx_buff_data;

	wire		rx_buff_re, rx_buff_empty, rx_buff_valid;
	wire [31:0]	rx_buff_data;
	wire [15:0]	rx_buff_length;
	wire [15:0]	rx_buff_status;

	wire		etx_buff_we, etx_buff_start, etx_buff_end, etx_buff_ready, etx_buff_full;
	wire [31:0]	etx_buff_data;

	wire		erx_buff_re, erx_buff_empty, erx_buff_valid;
	wire [31:0]	erx_buff_data;
	wire [15:0]	erx_buff_length;
	wire [15:0]	erx_buff_status;

	wire [15:0]	pause_quanta_data;
	wire		pause_send_enable;
	wire		tx_pause_enable;

	wire [47:0]	mac_address;
	wire [31:0]	ip_address;
	wire		random_time_meet;
	wire [3:0]	max_retry;
	wire		gig_mode;
	wire		full_duplex;

	aq_gemac_l3_ctrl u_aq_gemac_l3_ctrl(
		.RST_N				( RST_N	),
		.CLK				( CLK	),

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

		// External RX Buffer Interface
		.ERX_BUFF_RE		( erx_buff_re		),
		.ERX_BUFF_DATA		( erx_buff_data		),
		.ERX_BUFF_EMPTY		( erx_buff_empty	),
		.ERX_BUFF_VALID		( erx_buff_valid	),
		.ERX_BUFF_LENGTH	( erx_buff_length	),
		.ERX_BUFF_STATUS	( erx_buff_status	),

		// External TX Buffer Interface
		.ETX_BUFF_WE		( etx_buff_we		),
		.ETX_BUFF_START		( etx_buff_start	),
		.ETX_BUFF_END		( etx_buff_end		),
		.ETX_BUFF_READY		( etx_buff_ready	),
		.ETX_BUFF_DATA		( etx_buff_data		),
		.ETX_BUFF_FULL		( etx_buff_full		),

		.MAC_ADDRESS		( mac_address		),
		.IP_ADDRESS			( ip_address		)

		.ARPC_ENABLE		( ),
		.ARPC_REQUEST		( ),
		.ARPC_VALID			( ),
		.ARPC_IP_ADDRESS	( ),
		.ARPC_MAC_ADDRESS	( ),

		.STATUS				( )
	);

	assign EMAC_GTX_CLK = ~EMAC_CLK125M;

	wire	tx_clk;
	assign	tx_clk = (gig_mode)?EMAC_CLK125M:EMAC_TX_CLK;

	aq_gemac u_aq_gemac(
		.RST_N				( RST_N	),

		// GMII,MII Interface
		.TX_CLK				( tx_clk		),
		.TXD				( EMAC_TXD		),
		.TX_EN				( EMAC_TX_EN	),
		.TX_ER				( EMAC_TX_ER	),
		.RX_CLK				( ~EMAC_RX_CLK	),
		.RXD				( EMAC_RXD		),
		.RX_DV				( EMAC_RX_DV	),
		.RX_ER				( EMAC_RX_ER	),
		.COL				( EMAC_COL		),
		.CRS				( EMAC_CRS		),

		// System Clock
		.CLK				( CLK		),

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

		// From CPU
		.PAUSE_QUANTA_DATA	( pause_quanta_data	),
		.PAUSE_SEND_ENABLE	( pause_send_enable	),
		.TX_PAUSE_ENABLE	( tx_pause_enable	),

		// Setting
		.RANDOM_TIME_MEET	( random_time_meet	),
		.MAC_ADDRESS		( mac_address		),
		.MAX_RETRY			( max_retry			),
		.GIG_MODE			( gig_mode			),
		.FULL_DUPLEX		( full_duplex		)
	);

	assign	mac_address			= 48'h131210000000;
	assign	ip_address			= 32'h0101A8C0;
	assign	gig_mode			= 1'b0;
	assign	full_duplex			= 1'b1;
	assign	pause_quanta_data	= 16'h0000;
	assign	puase_send_enable	= 1'b0;
	assign	tx_pause_enable		= 1'b0;
	assign	max_retry			= 4'd8;
	assign	erx_buff_re			= 1'b00;
	assign	random_time_meet	= 1'b1;
	assign	etx_buff_we			= 1'b0;
	assign	etx_buff_start		= 1'b0;
	assign	etx_buff_end		= 1'b0;
	assign	etx_buff_data		= 1'B0;
endmodule

