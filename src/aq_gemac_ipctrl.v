/*
* PROJECT: AQUAXIS Giga Ethernet MAC
* ----------------------------------------------------------------------
*
* IP Controller with Gigabit MAC
* File: aq_gemac_udp.v
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
* 2012/05/28	H.Ishihara	Create
*/
`timescale 1ps / 1ps

module aq_gemac_ipctrl(
	input			RST_N,
	input			SYS_CLK,

	// GEMAC Interface
	input			EMAC_CLK125M,		// Clock 125MHz
	output			EMAC_GTX_CLK,		// Tx Clock(Out) for 1000 Mode

	input			EMAC_TX_CLK,		// Tx Clock(In)  for 10/100 Mode
	output [7:0]	EMAC_TXD,			// Tx Data
	output			EMAC_TX_EN,			// Tx Data Enable
	output			EMAC_TX_ER,			// Tx Error
	input			EMAC_COL,			// Collision signal
	input			EMAC_CRS,			// CRS

	input			EMAC_RX_CLK,		// Rx Clock(In)  for 10/100/1000 Mode
	input [7:0]		EMAC_RXD,			// Rx Data
	input			EMAC_RX_DV,			// Rx Data Valid
	input			EMAC_RX_ER,			// Rx Error

	input			EMAC_INT,			// Interrupt
	output			EMAC_RST,

	// GEMAC MIIM Interface
	input			MIIM_MDC,			// MIIM Clock
	inout			MIIM_MDIO,			// MIIM I/O

	input			MIIM_REQUEST,
	input			MIIM_WRITE,
	input [3:0]		MIIM_PHY_ADDRESS,
	input [3:0]		MIIM_REG_ADDRESS,
	input [15:0]	MIIM_WDATA,
	output [15:0]	MIIM_RDATA,
	output			MIIM_BUSY,

	// RX Buffer Interface
	input			RX_BUFF_RE,			// RX Buffer Read Enable
	output [31:0]	RX_BUFF_DATA,		// RX Buffer Data
	output			RX_BUFF_EMPTY,		// RX Buffer Empty(1: Empty, 0: No Empty)
	output			RX_BUFF_VALID,		// RX Buffer Valid
	output [15:0]	RX_BUFF_LENGTH,		// RX Buffer Length
	output [31:0]	RX_BUFF_STATUS,		// RX Buffer Status

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
	input [15:0]	PORT0,
	input [15:0]	PORT1,
	input [15:0]	PORT2,
	input [15:0]	PORT3,

	output			ARPC_ENABLE,		// ARP Cache Request Enable
	input			ARPC_REQUEST,		// ARP Cache Request
	output			ARPC_VALID,			// ARP Cache Valid

	input [3:0]		MAX_RETRY,			// Max Retry
	input			GIG_MODE,			// Operation Mode(1: Giga Mode, 0: 10/100Mbps)
	input			FULL_DUPLEX,		// Operation Mode(1: Full Duplex, 0: Half Duplex)

	// Send UDP
	input			SEND_REQUEST,
	input [15:0]	SEND_LENGTH,
	output			SEND_BUSY,
	input [47:0]	SEND_MAC_ADDRESS,
	input [31:0]	SEND_IP_ADDRESS,
	input [15:0]	SEND_DST_PORT,
	input [15:0]	SEND_SRC_PORT,
	input			SEND_DATA_VALID,
	output			SEND_DATA_READ,
	input [31:0]	SEND_DATA,

	// Receive UDP
	output			REC_REQUEST,
	output [15:0]	REC_LENGTH,
	output			REC_BUSY,
	output [3:0]	REC_DATA_VALID,
	output [47:0]	REC_SRC_MAC,
	output [31:0]	REC_SRC_IP,
	output [15:0]	REC_SRC_PORT,
	input			REC_DATA_READ,
	output [31:0]	REC_DATA
);

	wire [7:0]	gEMAC_TXD;
	wire		gEMAC_TX_EN;
	wire		gEMAC_TX_ER;
	wire		gEMAC_COL;
	wire		gEMAC_CRS;
	wire [7:0]	gEMAC_RXD;
	wire		gEMAC_RX_DV;
	wire		gEMAC_RX_ER;

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

	wire [15:0]	l3_ext_status;

	wire [47:0]	peer_mac_address_o;

	wire		tx_clk, rx_clk;

	// Ethernet MAC
	assign EMAC_RST	= ~RST_N;	// Active High
	assign tx_clk	= (giga_mode)?EMAC_CLK125M:EMAC_TX_CLK;
	assign rx_clk	= EMAC_RX_CLK;

	// I/O
`ifdef RGMII
	aq_gemac_gmii2rgmii u_aq_gemac_gmii2rgmii(
		.rst_b		( rst_b			),

		.tx_clk		( tx_clk		),
		.gmii_txd	( gEMAC_TXD		),
		.gmii_txe	( gEMAC_TX_EN	),
		.gmii_txer	( gEMAC_TX_ER	),
		.gmii_rxd	( gEMAC_RXD		),
		.gmii_rxe	( gEMAC_RX_DV	),
		.gmii_rxer	( gEMAC_RX_ER	),

		.rx_clk		( rx_clk		),
		.rgmii_txd	( EMAC_TXD[3:0]	),
		.rgmii_txe	( EMAC_TX_ER	),
		.rgmii_rxd	( EMAC_RXD[3:0]	),
		.rgmii_rxe	( EMAC_RX_ER	),
		.rgmii_tck	( EMAC_GTX_CLK	)
	);
	assign gEMAC_COL <= 1'b0;
	assign gEMAC_CRS <= 1'b0;
`else
	aq_gemac_gmii_buff u_aq_gemac_gmii_buff(
		.rst_b			( RST_N			),

		.tx_clk			( tx_clk		),
		.bgmii_txd		( gEMAC_TXD		),
		.bgmii_txe		( gEMAC_TX_EN	),
		.bgmii_txer		( gEMAC_TX_ER	),
		.bgmii_rxd		( gEMAC_RXD		),
		.bgmii_rxe		( gEMAC_RX_DV	),
		.bgmii_rxer		( gEMAC_RX_ER	),
		.bgmii_cos		( gEMAC_COL		),
		.bgmii_crs		( gEMAC_CRS		),

		.rx_clk			( rx_clk		),
		.gmii_txd		( EMAC_TXD		),
		.gmii_txe		( EMAC_TX_EN	),
		.gmii_txer		( EMAC_TX_ER	),
		.gmii_rxd		( EMAC_RXD		),
		.gmii_rxe		( EMAC_RX_DV	),
		.gmii_rxer		( EMAC_RX_ER	),
		.gmii_col		( EMAC_COS		),
		.gmii_crs		( EMAC_CRS		),
		.gmii_gtk_clk	( EMAC_GTX_CLK  )
	);
`endif

	// UDP Controller
	aq_gemac_udp_ctrl u_aq_gemac_udp_ctrl(
		.RST_N				( RST_N					),
		.CLK				( SYS_CLK				),

		.MY_MAC_ADDRESS		( MY_MAC_ADDRESS			),
		.MY_IP_ADDRESS		( MY_IP_ADDRESS			),

		// Send UDP
		.SEND_REQUEST		( SEND_REQUEST			),
		.SEND_LENGTH		( SEND_LENGTH			),
		.SEND_BUSY			( SEND_BUSY				),
		.SEND_MAC_ADDRESS	( PEER_MAC_ADDRESS      ),
		.SEND_IP_ADDRESS	( PEER_IP_ADDRESS       ),
		.SEND_DST_PORT		( SEND_DST_PORT			),
		.SEND_SRC_PORT		( SEND_SRC_PORT			),
		.SEND_DATA_VALID	( SEND_DATA_VALID		),
		.SEND_DATA_READ		( SEND_DATA_READ		),
		.SEND_DATA			( SEND_DATA				),

		// Receive UDP
		.REC_REQUEST		( REC_REQUEST			),
		.REC_LENGTH			( REC_LENGTH			),
		.REC_BUSY			( REC_BUSY				),
		.REC_DST_PORT0		( PORT0					),
		.REC_DST_PORT1		( PORT1					),
		.REC_DST_PORT2		( PORT2					),
		.REC_DST_PORT3		( PORT3					),
		.REC_DATA_VALID 	( REC_DATA_VALID[3:0]	),
		.REC_SRC_MAC		( REC_SRC_MAC		),
		.REC_SRC_IP			( REC_SRC_IP			),
		.REC_SRC_PORT		( REC_SRC_PORT				),
		.REC_DATA_READ		( REC_DATA_READ			),
		.REC_DATA			( REC_DATA				),

		// for ETHER-MAC BUFFER
		.TX_WE				( etx_buff_we			),
		.TX_START			( etx_buff_start		),
		.TX_END				( etx_buff_end			),
		.TX_READY			( etx_buff_ready		),
		.TX_DATA			( etx_buff_data			),
		.TX_FULL			( etx_buff_full			),
		.TX_SPACE			( etx_buff_space		),

		.RX_RE				( erx_buff_re			),
		.RX_DATA			( erx_buff_data			),
		.RX_EMPTY			( erx_buff_empty		),
		.RX_VALID			( erx_buff_valid		),
		.RX_LENGTH			( erx_buff_length		),
		.RX_STATUS			( erx_buff_status		),

		.ETX_WE				( TX_BUFF_WE			),
		.ETX_START			( TX_BUFF_START			),
		.ETX_END			( TX_BUFF_END			),
		.ETX_READY			( TX_BUFF_READY			),
		.ETX_DATA			( TX_BUFF_DATA			),
		.ETX_FULL			( TX_BUFF_FULL			),
		.ETX_SPACE			( TX_BUFF_SPACE			),

		.ERX_RE				( RX_BUFF_RE			),
		.ERX_DATA			( RX_BUFF_DATA			),
		.ERX_EMPTY			( RX_BUFF_EMPTY			),
		.ERX_VALID			( RX_BUFF_VALID			),
		.ERX_LENGTH			( RX_BUFF_LENGTH		),
		.ERX_STATUS			( RX_BUFF_STATUS		)
	);

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
		.ERX_BUFF_RE		( erx_buff_re			),
		.ERX_BUFF_DATA		( erx_buff_data			),
		.ERX_BUFF_EMPTY		( erx_buff_empty		),
		.ERX_BUFF_VALID		( erx_buff_valid		),
		.ERX_BUFF_LENGTH	( erx_buff_length		),
		.ERX_BUFF_STATUS	( erx_buff_status		),

		// External TX Buffer Interface
		.ETX_BUFF_WE		( etx_buff_we			),
		.ETX_BUFF_START		( etx_buff_start		),
		.ETX_BUFF_END		( etx_buff_end			),
		.ETX_BUFF_READY		( etx_buff_ready		),
		.ETX_BUFF_DATA		( etx_buff_data			),
		.ETX_BUFF_FULL		( etx_buff_full			),
		.ETX_BUFF_SPACE		( etx_buff_space		),

		.MAC_ADDRESS		( MY_MAC_ADDRESS			),
		.IP_ADDRESS			( MY_IP_ADDRESS			),

		.ARPC_ENABLE		( ARPC_ENABLE			),
		.ARPC_REQUEST		( ARPC_REQUEST			),
		.ARPC_VALID			( ARPC_VALID			),
		.ARPC_IP_ADDRESS	( PEER_IP_ADDRESS			),
		.ARPC_MAC_ADDRESS   ( peer_mac_address_o	),

		.STATUS				( l3_ext_status			)
	);
	assign PEER_MAC_ADDRESS = peer_mac_address_o;

	// Giga Ethernet MAC
	aq_gemac u_aq_gemac(
		.RST_N				( RST_N				),

		// GMII,MII Interface
		.TX_CLK				( tx_clk			),
		.TXD				( gEMAC_TXD			),
		.TX_EN				( gEMAC_TX_EN		),
		.TX_ER				( gEMAC_TX_ER		),
		.RX_CLK				( rx_clk			),
		.RXD				( gEMAC_RXD			),
		.RX_DV				( gEMAC_RX_DV		),
		.RX_ER				( gEMAC_RX_ER		),
		.COL				( gEMAC_COL			),
		.CRS				( gEMAC_CRS			),

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
		.MAC_ADDRESS		( MY_MAC_ADDRESS		),
		.IP_ADDRESS			( MY_IP_ADDRESS		),
		.PORT0				( PORT0				),
		.PORT1				( PORT1				),
		.PORT2				( PORT2				),
		.PORT3				( PORT3				),
		.MAX_RETRY			( MAX_RETRY			),
		.GIG_MODE			( GIG_MODE			),
		.FULL_DUPLEX		( FULL_DUPLEX		)
	);

	// MIIM Controller
	wire miim_mdio_o, miim_mdio_e;
	aq_gemac_miim u_aq_gemac_miim(
		.RST_N				( RST_N				),
		.CLK				( SYS_CLK			),

		.MIIM_REQUEST		( MIIM_REQUEST		),
		.MIIM_WRITE			( MIIM_WRITE		),
		.MIIM_PHY_ADDRESS	( MIIM_PHY_ADDRESS	),
		.MIIM_REG_ADDRESS	( MIIM_REG_ADDRESS	),
		.MIIM_WDATA			( MIIM_WDATA		),
		.MIIM_RDATA			( MIIM_RDATA		),
		.MIIM_BUSY			( MIIM_BUSY			),

		.MDC				( MDC				),
		.MDIO_IN			( MDIO				),
		.MDIO_OUT			( miim_mdio_o		),
		.MDIO_OUT_ENABLE	( miim_mdio_e		)
	);
	assign MDIO = (miim_mdio_e)?miim_mdio_o:1'bZ;
endmodule
