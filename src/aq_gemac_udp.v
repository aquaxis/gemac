/*
* PROJECT: AQUAXIS Giga Ethernet MAC
* ----------------------------------------------------------------------
*
* aq_gemac_udp.v
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
*   http://www.aquaxis.com/
*   info(at)aquaxis.com or hidemi(at)sweetcafe.jp
*
* Create 2007/06/01 H.Ishihara
*/
`timescale 1ps / 1ps

module aq_gemac_udp(
	input			RST_N,

	input			CLK100M,

	input			EMAC_CLK125M,	// Clock 125MHz
	output			EMAC_GTX_CLK,	// Tx Clock(Out) for 1000 Mode

	input			EMAC_TX_CLK,	// Tx Clock(In)  for 10/100 Mode
	output [7:0]	EMAC_TXD,		// Tx Data
	output			EMAC_TX_EN,		// Tx Data Enable
	output			EMAC_TX_ER,		// Tx Error
	input			EMAC_COL,		// Collision signal
	input			EMAC_CRS,		// CRS

	input			EMAC_RX_CLK,	// Rx Clock(In)  for 10/100/1000 Mode
	input [7:0]		EMAC_RXD,		// Rx Data
	input			EMAC_RX_DV,		// Rx Data Valid
	input			EMAC_RX_ER,		// Rx Error

	input			EMAC_INT,		// Interrupt
	output			EMAC_RST,

	input			MIIM_MDC,		// MIIM Clock
	input			MIIM_MDIO,		// MIIM I/O

	output [47:0]	UDP_PEER_MAC_ADDRESS,
	input [31:0]	UDP_PEER_IP_ADDRESS,
	input [47:0]	UDP_MY_MAC_ADDRESS,
	input [31:0]	UDP_MY_IP_ADDRESS,

	// Send UDP
	input			UDP_SEND_REQUEST,
	input [15:0]	UDP_SEND_LENGTH,
	output			UDP_SEND_BUSY,
	input [15:0]	UDP_SEND_DSTPORT,
	input [15:0]	UDP_SEND_SRCPORT,
	input			UDP_SEND_DATA_VALID,
	output			UDP_SEND_DATA_READ,
	input [31:0]	UDP_SEND_DATA,

	// Receive UDP
	output			UDP_REC_REQUEST,
	output [15:0]	UDP_REC_LENGTH,
	output			UDP_REC_BUSY,
	input [15:0]	UDP_REC_DSTPORT0,
	input [15:0]	UDP_REC_DSTPORT1,
	output			UDP_REC_DATA_VALID0,
	output			UDP_REC_DATA_VALID1,
	input			UDP_REC_DATA_READ,
	output [31:0]	UDP_REC_DATA
);
	parameter DEFAULT_MY_MAC_ADRS  = 48'h332211000000;
	parameter DEFAULT_MY_IP_ADRS   = 32'h5A00A8C0;		// 192.168.0.90
	parameter DEFAULT_MY_REC0_PORT = 16'd0004;			// 1024
	parameter DEFAULT_MY_REC1_PORT = 16'd0104;			// 1025
	parameter DEFAULT_MY_SEND_PORT = 16'd0004;			// 1024
	parameter DEFAULT_PEER_IP_ADRS = 32'h1A00A8C0;		// 192.168.0.26

	wire		sys_clk;
	assign sys_clk = EMAC_CLK125M;

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


	wire [15:0]	pause_quanta_data;
	wire		pause_send_enable;
	wire		tx_pause_enable;

	wire		random_time_meet;
	wire [3:0]	max_retry;
	wire		giga_mode;
	wire		full_duplex;

	wire		arpc_enable, arpc_request, arpc_valid;

	wire		udp_send_request;
	wire [11:0]	udp_send_length;
	wire		udp_send_busy;
	wire [15:0]	udp_send_dstport;
	wire [15:0]	udp_send_srcport;
	wire		udp_send_data_valid;
	wire		udp_send_data_read;
	wire [31:0]	udp_send_data;

	wire		udp_rec_request;
	wire [15:0]	udp_rec_length;
	wire		udp_rec_busy;
	wire [15:0]	udp_rec_dstport0;
	wire [15:0]	udp_rec_dstport1;
	wire		udp_rec_data_valid0;
	wire		udp_rec_data_valid1;
	wire		udp_rec_data_read, udp_rec0_data_read, udp_rec1_data_read;
	wire [31:0]	udp_rec_data;

	wire [15:0]	l3_ext_status;

	wire [47:0]	peer_mac_address;

	// Ethernet MAC
	assign EMAC_RST = 1'b1;
	wire		tx_clk, rx_clk;
	assign tx_clk = (giga_mode)?EMAC_CLK125M:EMAC_TX_CLK;
	assign rx_clk = EMAC_RX_CLK;

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
		.RST_N					( RST_N					),
		.CLK					( sys_clk				),

		.UDP_PEER_MAC_ADDRESS   ( peer_mac_address		),
		.UDP_PEER_IP_ADDRESS	( DEFAULT_PEER_IP_ADRS	),
		.UDP_MY_MAC_ADDRESS		( DEFAULT_MY_MAC_ADRS	),
		.UDP_MY_IP_ADDRESS		( DEFAULT_MY_IP_ADRS	),

		// Send UDP
		.UDP_SEND_REQUEST		( udp_send_request		),
		.UDP_SEND_LENGTH		( {4'd0, udp_send_length}	),
		.UDP_SEND_BUSY			( udp_send_busy			),
		.UDP_SEND_DSTPORT		( DEFAULT_MY_SEND_PORT	),
		.UDP_SEND_SRCPORT		( udp_send_srcport		),
		.UDP_SEND_DATA_VALID	( udp_send_data_valid	),
		.UDP_SEND_DATA_READ		( udp_send_data_read	),
		.UDP_SEND_DATA			( udp_send_data			),

		// Receive UDP
		.UDP_REC_REQUEST		( udp_rec_request		),
		.UDP_REC_LENGTH			( udp_rec_length		),
		.UDP_REC_BUSY			( udp_rec_busy			),
		.UDP_REC_DSTPORT0		( DEFAULT_MY_REC0_PORT	),
		.UDP_REC_DSTPORT1		( DEFAULT_MY_REC1_PORT	),
		.UDP_REC_DATA_VALID0	( udp_rec_data_valid0	),
		.UDP_REC_DATA_VALID1	( udp_rec_data_valid1	),
		.UDP_REC_DATA_READ		( udp_rec_data_read		),
		.UDP_REC_DATA			( udp_rec_data			),

		// for ETHER-MAC BUFFER
		.TX_WE					( etx_buff_we		),
		.TX_START				( etx_buff_start	),
		.TX_END					( etx_buff_end		),
		.TX_READY				( etx_buff_ready	),
		.TX_DATA				( etx_buff_data		),
		.TX_FULL				( etx_buff_full		),
		.TX_SPACE				( etx_buff_space	),

		.RX_RE					( erx_buff_re		),
		.RX_DATA				( erx_buff_data		),
		.RX_EMPTY				( erx_buff_empty	),
		.RX_VALID				( erx_buff_valid	),
		.RX_LENGTH				( erx_buff_length	),
		.RX_STATUS				( erx_buff_status	)
	);

	// Layer 3 Extension
	aq_gemac_l3_ctrl u_aq_gemac_l3_ctrl(
		.RST_N				( RST_N					),
		.CLK				( sys_clk				),

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

		.MAC_ADDRESS		( DEFAULT_MY_MAC_ADRS	),
		.IP_ADDRESS			( DEFAULT_MY_IP_ADRS	),

		.ARPC_ENABLE		( arpc_enable			),
		.ARPC_REQUEST		( arpc_request			),
		.ARPC_VALID			( arpc_valid			),
		.ARPC_IP_ADDRESS	( DEFAULT_PEER_IP_ADRS	),
		.ARPC_MAC_ADDRESS   ( peer_mac_address		),

		.STATUS				( l3_ext_status			)
	);
	// Ethernet MAC
	aq_gemac u_aq_gemac(
		.RST_N				( RST_N					),

		// GMII,MII Interface
		.TX_CLK				( tx_clk				),
		.TXD				( gEMAC_TXD				),
		.TX_EN				( gEMAC_TX_EN			),
		.TX_ER				( gEMAC_TX_ER			),
		.RX_CLK				( rx_clk				),
		.RXD				( gEMAC_RXD				),
		.RX_DV				( gEMAC_RX_DV			),
		.RX_ER				( gEMAC_RX_ER			),
		.COL				( gEMAC_COL				),
		.CRS				( gEMAC_CRS				),

		// System Clock
		.CLK				( sys_clk				),

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

		// From CPU
		.PAUSE_QUANTA_DATA	( pause_quanta_data		),
		.PAUSE_SEND_ENABLE	( pause_send_enable		),
		.TX_PAUSE_ENABLE	( tx_pause_enable		),

		// Setting
		.RANDOM_TIME_MEET   ( random_time_meet		),
		.MAC_ADDRESS		( DEFAULT_MY_MAC_ADRS	),
		.IP_ADDRESS			( DEFAULT_MY_IP_ADRS	),
		.MAX_RETRY			( max_retry				),
		.GIG_MODE			( giga_mode				),
		.FULL_DUPLEX		( full_duplex			)
	);

	reg [1:0] arp_state;
	always @(posedge sys_clk or negedge RST_N) begin
		if(!RST_N) begin
			arp_state <= 2'd0;
		end else begin
			case(arp_state[1:0])
				2'd0: begin
					if((arpc_enable == 1'b0) && (arpc_valid == 1'b0)) begin
						arp_state <= 2'd1;
					end
				end
				2'd1: begin
					arp_state <= 2'd2;
				end
				2'd2: begin
					if(arpc_enable == 1'b0) begin
						if(arpc_valid == 1'b0) begin
							arp_state <= 2'd0;
						end else begin
							arp_state <= 2'd3;
						end
					end
				end
				2'd3: begin
				end
			endcase
		end
	end

	assign arpc_request = arp_state == 2'd1;
endmodule

