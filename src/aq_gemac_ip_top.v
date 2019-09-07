/*
* PROJECT: AQUAXIS Giga Ethernet MAC
* ----------------------------------------------------------------------
*
* IP Controller with Gigabit MAC
* File: aq_gemac_ip_top.v
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

module aq_gemac_ip_top
#(
	parameter USE_MIIM	= 1
)
(
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

	output			EMAC_RST,

	// GEMAC MIIM Interface
	input			MIIM_MDC,			// MIIM Clock
	inout			MIIM_MDIO,			// MIIM I/O

	input			MIIM_REQUEST,
	input			MIIM_WRITE,
	input [4:0]		MIIM_PHY_ADDRESS,
	input [4:0]		MIIM_REG_ADDRESS,
	input [15:0]	MIIM_WDATA,
	output [15:0]	MIIM_RDATA,
	output			MIIM_BUSY,

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
	input [15:0]	REC_DST_PORT0,
	input [15:0]	REC_DST_PORT1,
	input [15:0]	REC_DST_PORT2,
	input [15:0]	REC_DST_PORT3,
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

	wire		tx_clk, rx_clk;

	// Ethernet MAC
	assign EMAC_RST	= ~RST_N;	// Active High
	assign tx_clk	= (GIG_MODE)?EMAC_CLK125M:EMAC_TX_CLK;
	assign rx_clk	= EMAC_RX_CLK;
/*
	// MIIM Controller
`ifdef USE_MIIM
	wire miim_mdio_o, miim_mdio_e;
	assign MDIO = (miim_mdio_e)?miim_mdio_o:1'bZ;
`else
	assign MIIM_BUSY		= 1'b0;
	assign MIIM_RDATA[15:0]	= 15'd0;
	assign MDIO				= 1'bZ;
`endif
*/
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

	// ------------------------------------------------------------
	// Module
	// ------------------------------------------------------------
	// GEMAC Modules
	aq_gemac_ip
	#(
		.USE_MIIM			( USE_MIIM		)
	)
	u_aq_gemac_ip(
		.RST_N				( RST_N			),
		.SYS_CLK			( SYS_CLK		),

		// GEMAC Interface
		.EMAC_TX_CLK		( tx_clk		),
		.EMAC_TXD			( gEMAC_TXD		),
		.EMAC_TX_EN			( gEMAC_TX_EN	),
		.EMAC_TX_ER			( gEMAC_TX_ER	),
		.EMAC_COL			( gEMAC_COL		),
		.EMAC_CRS			( gEMAC_CRS		),
		.EMAC_RX_CLK		( rx_clk		),
		.EMAC_RXD			( gEMAC_RXD		),
		.EMAC_RX_DV			( gEMAC_RX_DV	),
		.EMAC_RX_ER			( gEMAC_RX_ER	),

		// GEMAC MIIM Interface
		.MIIM_MDIO_CLK		( MDC			),
		.MIIM_MDIO_DI		( MDIO			),
		.MIIM_MDIO_DO		( miim_mdio_o	),
		.MIIM_MDIO_T		( miim_mdio_e	),

		.MIIM_REQUEST		( MIIM_REQUEST		),
		.MIIM_WRITE			( MIIM_WRITE		),
		.MIIM_PHY_ADDRESS	( MIIM_PHY_ADDRESS	),
		.MIIM_REG_ADDRESS	( MIIM_REG_ADDRESS	),
		.MIIM_WDATA			( MIIM_WDATA		),
		.MIIM_RDATA			( MIIM_RDATA		),
		.MIIM_BUSY			( MIIM_BUSY			),

		// RX Buffer Interface
		.RX_BUFF_RE			( RX_BUFF_RE		),
		.RX_BUFF_DATA		( RX_BUFF_DATA		),
		.RX_BUFF_EMPTY		( RX_BUFF_EMPTY		),
		.RX_BUFF_VALID		( RX_BUFF_VALID		),
		.RX_BUFF_LENGTH		( RX_BUFF_LENGTH	),
		.RX_BUFF_STATUS		( RX_BUFF_STATUS	),

		// TX Buffer Interface
		.TX_BUFF_WE			( TX_BUFF_WE		),
		.TX_BUFF_START		( TX_BUFF_START		),
		.TX_BUFF_END		( TX_BUFF_END		),
		.TX_BUFF_READY		( TX_BUFF_READY		),
		.TX_BUFF_DATA		( TX_BUFF_DATA		),
		.TX_BUFF_FULL		( TX_BUFF_FULL		),
		.TX_BUFF_SPACE		( TX_BUFF_SPACE		),

		// From CPU
		.PAUSE_QUANTA_DATA	(),
		.PAUSE_SEND_ENABLE	(),
		.TX_PAUSE_ENABLE	(),

		.PEER_MAC_ADDRESS	( PEER_MAC_ADDRESS	),
		.PEER_IP_ADDRESS	( PEER_IP_ADDRESS	),
		.MY_MAC_ADDRESS		( MY_MAC_ADDRESS	),
		.MY_IP_ADDRESS		( MY_IP_ADDRESS		),

		.ARPC_ENABLE		( ARPC_ENABLE		),
		.ARPC_REQUEST		( ARPC_REQUEST		),
		.ARPC_VALID			( ARPC_VALID		),

		.MAX_RETRY			( MAX_RETRY			),
		.GIG_MODE			( GIG_MODE			),
		.FULL_DUPLEX		( FULL_DUPLEX		),

		// Send UDP
		.SEND_REQUEST		( SEND_REQUEST			),
		.SEND_LENGTH		( SEND_LENGTH			),
		.SEND_BUSY			( SEND_BUSY				),
		.SEND_MAC_ADDRESS	( SEND_MAC_ADDRESS		),
		.SEND_IP_ADDRESS	( SEND_IP_ADDRESS		),
		.SEND_DST_PORT		( SEND_DST_PORT			),
		.SEND_SRC_PORT		( SEND_SRC_PORT			),
		.SEND_DATA_VALID	( SEND_DATA_VALID		),
		.SEND_DATA_READ		( SEND_DATA_READ		),
		.SEND_DATA			( SEND_DATA				),

		// Receive UDP
		.REC_REQUEST		( REC_REQUEST			),
		.REC_LENGTH			( REC_LENGTH			),
		.REC_BUSY			( REC_BUSY				),
		.REC_DST_PORT0		( REC_DST_PORT0			),
		.REC_DST_PORT1		( REC_DST_PORT1			),
		.REC_DST_PORT2		( REC_DST_PORT2			),
		.REC_DST_PORT3		( REC_DST_PORT3			),
		.REC_SRC_MAC		( REC_SRC_MAC			),
		.REC_SRC_IP			( REC_SRC_IP			),
		.REC_SRC_PORT		( REC_SRC_PORT			),
		.REC_DATA_VALID		( REC_DATA_VALID[3:0]	),
		.REC_DATA_READ		( REC_DATA_READ			),
		.REC_DATA			( REC_DATA				)
	);
/*
ila_0 u_ila_0(
.clk(SYS_CLK),
.probe0(EMAC_TX_CLK),
.probe1(EMAC_TXD),
.probe2(EMAC_TX_EN),
.probe3(EMAC_TX_ER),
.probe4(EMAC_COL),
.probe5(EMAC_CRS),
.probe6(EMAC_RX_CLK),
.probe7(EMAC_RXD),
.probe8(EMAC_RX_DV),
.probe9(EMAC_RX_ER)
);
*/
endmodule
