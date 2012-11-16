/*
* PROJECT: AQUAXIS Giga Ethernet MAC
* ----------------------------------------------------------------------
*
* ether_mac_fpga.v
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

module ether_mac_fpga
  (
   // PCI Loacl Bus
   PCI_RST,     // PCI Reset(Low Active)
   PCI_CLK,     // PCI Clock(33MHz)

   PCI_FRAME_N,
   PCI_IDSEL,
   PCI_DEVSEL_N,
   PCI_IRDY_N,
   PCI_TRDY_N,
   PCI_STOP_N,

   PCI_CBE,
   PCI_AD,
   PCI_PAR,

   PCI_SERR_N,
   PCI_PERR_N,
   PCI_INTA_N,

   EMAC_CLK125M,   // Clock 125MHz

   EMAC_GTX_CLK,   // Tx Clock(Out) for 1000 Mode
   EMAC_TX_CLK,    // Tx Clock(In)  for 10/100 Mode
   EMAC_TXD,       // Tx Data
   EMAC_TX_EN,     // Tx Data Enable
   EMAC_TX_ER,     // Tx Error
   EMAC_COL,       // Collision signal
   EMAC_CRS,       // CRS

   EMAC_RX_CLK,    // Rx Clock(In)  for 10/100/1000 Mode
   EMAC_RXD,       // Rx Data
   EMAC_RX_DV,     // Rx Data Valid
   EMAC_RX_ER,     // Rx Error

   EMAC_INT,   // Interrupt

   MIIM_MDC,     // MIIM Clock
   MIIM_MDIO,    // MIIM I/O

   LED
   );

   input          PCI_RST;
   input          PCI_CLK;

   input          PCI_FRAME_N;
   input          PCI_IDSEL;
   output         PCI_DEVSEL_N;
   input          PCI_IRDY_N;
   output         PCI_TRDY_N;
   output         PCI_STOP_N;

   inout [3:0]    PCI_CBE;
   inout [31:0]   PCI_AD;
   inout          PCI_PAR;

   output         PCI_SERR_N;
   output         PCI_PERR_N;
   output         PCI_INTA_N;

   input          EMAC_CLK125M;

   output         EMAC_GTX_CLK;
   input          EMAC_TX_CLK;
   output [7:0]   EMAC_TXD;
   output         EMAC_TX_EN;
   output         EMAC_TX_ER;
   input          EMAC_COL;
   input          EMAC_CRS;

   input          EMAC_RX_CLK;
   input [7:0]    EMAC_RXD;
   input          EMAC_RX_DV;
   input          EMAC_RX_ER;

   input          EMAC_INT;

   output         MIIM_MDC;
   inout          MIIM_MDIO;

	output [8:1]	LED;

   wire 	  pci_devsel_no;
   wire 	  pci_devsel_ot;
   wire 	  pci_trdy_no;
   wire 	  pci_trdy_ot;
   wire 	  pci_stop_no;
   wire 	  pci_stop_ot;
   wire [31:0] 	  pci_ad_o;
   wire 	  pci_ad_ot;
   wire 	  pci_par_o;
   wire 	  pci_par_ot;
   wire 	  pci_serr_ot;
   wire 	  pci_perr_no;
   wire 	  pci_perr_ot;
   wire 	  pci_inta_ot;
   wire 	  pci_frame_ni;
   wire 	  pci_idsel_i;
   wire 	  pci_irdy_ni;
   wire [3:0] 	  pci_cbe_i;
   wire [31:0] 	  pci_ad_i;
   wire 	  pci_par_i;

	wire	sys_clk;

	wire	jpeg_start;
	wire	jpeg_idle;
	wire	jpeg_reset;

	wire	fifo_enable;
	wire [31:0]	fifo_data;
	wire	fifo_read;

	wire	bm_enable;
	wire [15:0]	bm_width;
	wire [15:0]	bm_height;
	wire [15:0]	bm_x;
	wire [15:0]	bm_y;
	wire [7:0]	bm_r;
	wire [7:0]	bm_g;
	wire [7:0]	bm_b;

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

   // ------------------------------------------------------------
   // PCI Signals
   // ------------------------------------------------------------
   assign 	  pci_frame_ni = PCI_FRAME_N;
   assign 	  pci_idsel_i  = PCI_IDSEL;
   assign 	  pci_irdy_ni  = PCI_IRDY_N;
   assign 	  pci_cbe_i    = PCI_CBE;
   assign 	  pci_ad_i     = PCI_AD;
   assign 	  pci_par_i    = PCI_PAR;

   assign 	  PCI_DEVSEL_N = pci_devsel_ot ? 1'bz       : pci_devsel_no;
   assign 	  PCI_TRDY_N   = pci_trdy_ot   ? 1'bz       : pci_trdy_no;
   assign 	  PCI_STOP_N   = pci_stop_ot   ? 1'bz       : pci_stop_no;
   assign 	  PCI_AD       = pci_ad_ot     ? {32{1'bz}} : pci_ad_o[31:0];
   assign 	  PCI_PAR      = pci_par_ot    ? 1'bz       : pci_par_o;
   assign 	  PCI_SERR_N   = pci_serr_ot   ? 1'bz       : 1'b0;
   assign 	  PCI_PERR_N   = pci_perr_ot   ? 1'bz       : pci_perr_no;
   assign 	  PCI_INTA_N   = pci_inta_ot   ? 1'bz       : 1'b0;

	pci_top u_pci_top (
	    // PCI Loacl Bus
	    .pci_rst       ( PCI_RST       ),     // PCI Reset(Low Active)
	    .pci_clk       ( PCI_CLK       ),     // PCI Clock(33MHz)

	    .pci_frame_ni  ( pci_frame_ni  ),     //
	    .pci_idsel_i   ( pci_idsel_i   ),     //
	    .pci_devsel_no ( pci_devsel_no ),     //
	    .pci_devsel_ot ( pci_devsel_ot ),     //
	    .pci_irdy_ni   ( pci_irdy_ni   ),     //
	    .pci_trdy_no   ( pci_trdy_no   ),     //
	    .pci_trdy_ot   ( pci_trdy_ot   ),     //
	    .pci_stop_no   ( pci_stop_no   ),     //
	    .pci_stop_ot   ( pci_stop_ot   ),     //

	    .pci_cbe_i     ( pci_cbe_i     ),     //

	    .pci_ad_i      ( pci_ad_i      ),     // Address/Data Input
	    .pci_ad_o      ( pci_ad_o      ),     // Data Out
	    .pci_ad_ot     ( pci_ad_ot     ),     // 1:Output,0:Input

	    .pci_par_i     ( pci_par_i     ),     //
	    .pci_par_o     ( pci_par_o     ),     //
	    .pci_par_ot    ( pci_par_ot    ),     //

	    .pci_serr_ot   ( pci_serr_ot   ),     //
	    .pci_perr_no   ( pci_perr_no   ),     //
	    .pci_perr_ot   ( pci_perr_ot   ),     //
	    .pci_inta_ot   ( pci_inta_ot   ),     //

		.tx_buff_we			( etx_buff_we		),
		.tx_buff_start		( etx_buff_start	),
		.tx_buff_end		( etx_buff_end		),
		.tx_buff_ready		( etx_buff_ready	),
		.tx_buff_full		( etx_buff_full		),
		.tx_buff_data		( etx_buff_data		),

		.rx_buff_re			( erx_buff_re		),
		.rx_buff_empty		( erx_buff_empty	),
		.rx_buff_valid		( erx_buff_valid	),
		.rx_buff_data		( erx_buff_data		),
		.rx_buff_length		( erx_buff_length	),
		.rx_buff_status		( erx_buff_status	),

		.pause_quanta_data	( pause_quanta_data	),
		.pause_send_enable	( pause_send_enable	),
		.tx_pause_enable	( tx_pause_enable	),

		.mac_address		( mac_address		),
		.ip_address			( ip_address		),
		.random_time_meet	( random_time_meet	),
		.max_retry			( max_retry			),
		.gig_mode			( gig_mode			),
		.full_duplex		( full_duplex		),

		.soft_reset			( soft_reset		),

		.status			( LED			)
	);


	L3_EXTENSION u_L3_EXTENSION(
		.RST				( soft_reset		),
		.CLK				( PCI_CLK	),

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
		.IP_ADDRESS		( ip_address		)
	);


	assign EMAC_GTX_CLK = ~EMAC_CLK125M;

	wire	tx_clk;
	assign	tx_clk = (gig_mode)?EMAC_CLK125M:EMAC_TX_CLK;

	ETHER_MAC u_ETHER_MAC(
		.RST				( soft_reset	),

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
		.CLK				( PCI_CLK		),

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

endmodule

