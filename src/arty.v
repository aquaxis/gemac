`timescale 1ps / 1ps

module arty(
	input			RST_N,

	input			CLK100MHZ,

	output          EMAC_REF_CLK,

	input			EMAC_TX_CLK,	// Tx Clock(In)  for 10/100 Mode
	output [3:0]	EMAC_TXD,		// Tx Data
	output			EMAC_TX_EN,		// Tx Data Enable
//	output			EMAC_TX_ER,		// Tx Error
	input			EMAC_COL,		// Collision signal
	input			EMAC_CRS,		// CRS

	input			EMAC_RX_CLK,	// Rx Clock(In)  for 10/100/1000 Mode
	input [3:0]		EMAC_RXD,		// Rx Data
	input			EMAC_RX_DV,		// Rx Data Valid
	input			EMAC_RX_ER,		// Rx Error

	input			EMAC_INT,		// Interrupt
	output			EMAC_RST_N,		// Reset

	output			MIIM_MDC,		// MIIM Clock
	inout			MIIM_MDIO		// MIIM I/O
);
	parameter DEFAULT_MY_MAC_ADRS	= 48'h332211000000;
	parameter DEFAULT_MY_IP_ADRS	= 32'h960DA8C0;	  // 192.168.13.150
	parameter DEFAULT_PEER_IP_ADRS	= 32'h970DA8C0;	  // 192.168.13.151

	PULLUP u_RST_N(.O(RST_N));

	reg CLK50MHZ, CLK25MHZ;
	always @(posedge CLK100MHZ) begin
		CLK50MHZ <= ~CLK50MHZ;
	end
	always @(posedge CLK50MHZ) begin
		CLK25MHZ <= ~CLK25MHZ;
	end
	assign EMAC_REF_CLK = CLK25MHZ;

//	IDELAYCTRL u_IDELAYCTRL(.RDY(), .REFCLK(CLK200M), .RST(~RST_N));

	wire		tx_buff_we, tx_buff_start, tx_buff_end, tx_buff_ready, tx_buff_full;
	wire [31:0] tx_buff_data;
	wire [9:0]  tx_buff_space;

	wire		rx_buff_re, rx_buff_empty, rx_buff_valid;
	wire [31:0] rx_buff_data;
	wire [15:0] rx_buff_length;
	wire [15:0] rx_buff_status;

	wire [15:0] pause_quanta_data;
	wire		pause_send_enable;
	wire		tx_pause_enable;

	wire		random_time_meet;
	wire [3:0]  max_retry;
	wire		giga_mode;
	wire		full_duplex;

	wire		arpc_enable, arpc_request, arpc_valid;

	wire [15:0] l3_ext_status;
	wire [15:0] udp_loop_status;

	wire [47:0] peer_mac_address;

	wire EMAC_CLK125M, EMAC_GTX_CLK;
	assign EMAC_CLK125M = 1'b0;
	assign EMAC_GTX_CLK = 1'b0;

	wire EMAC_RST;
	assign EMAC_RST_N = ~EMAC_RST;

	wire EMAC_TX_ER;

		// RX Buffer Interface
	wire			RX_BUFF_RE;			// RX Buffer Read Enable
	wire [31:0]	RX_BUFF_DATA;		// RX Buffer Data
	wire			RX_BUFF_EMPTY;		// RX Buffer Empty(1: Empty, 0: No Empty)
	wire			RX_BUFF_VALID;		// RX Buffer Valid
	wire [15:0]	RX_BUFF_LENGTH;		// RX Buffer Length
	wire [31:0]	RX_BUFF_STATUS;		// RX Buffer Status

	// TX Buffer Interface
	wire			TX_BUFF_WE;			// TX Buffer Write Enable
	wire			TX_BUFF_START;		// TX Buffer Data Start
	wire			TX_BUFF_END;		// TX Buffer Data End
	wire			TX_BUFF_READY;		// TX Buffer Ready
	wire [31:0]	TX_BUFF_DATA;		// TX Buffer Data
	wire			TX_BUFF_FULL;		// TX Buffer Full
	wire [9:0]	TX_BUFF_SPACE;		// TX Buffer Space


	aq_gemac_ipctrl u_aq_gemac_ipctrl(
		.RST_N				( RST_N			),
		.SYS_CLK			( CLK100MHZ		),

		// GEMAC Interface
		.EMAC_CLK125M		(EMAC_CLK125M),		// Clock 125MHz
		.EMAC_GTX_CLK		(EMAC_GTX_CLK),		// Tx Clock(Out) for 1000 Mode

		.EMAC_TX_CLK		(EMAC_TX_CLK),		// Tx Clock(In)  for 10/100 Mode
		.EMAC_TXD			(EMAC_TXD),			// Tx Data
		.EMAC_TX_EN			(EMAC_TX_EN),			// Tx Data Enable
		.EMAC_TX_ER			(EMAC_TX_ER),			// Tx Error
		.EMAC_COL			(EMAC_COL),			// Collision signal
		.EMAC_CRS			(EMAC_CRS),			// CRS

		.EMAC_RX_CLK		(EMAC_RX_CLK),		// Rx Clock(In)  for 10/100/1000 Mode
		.EMAC_RXD			(EMAC_RXD),			// Rx Data
		.EMAC_RX_DV			(EMAC_RX_DV),			// Rx Data Valid
		.EMAC_RX_ER			(EMAC_RX_ER),			// Rx Error

		.EMAC_INT			(EMAC_INT),			// Interrupt
		.EMAC_RST			(EMAC_RST),

		// GEMAC MIIM Interface
		.MIIM_MDC			(MIIM_MDC),			// MIIM Clock
		.MIIM_MDIO			(MIIM_MDIO),			// MIIM I/O

		.MIIM_REQUEST		(1'd0),
		.MIIM_WRITE			(1'd0),
		.MIIM_PHY_ADDRESS	(4'd0),
		.MIIM_REG_ADDRESS	(4'd0),
		.MIIM_WDATA			(16'd0),
		.MIIM_RDATA			(),
		.MIIM_BUSY			(),

		// RX Buffer Interface
		.RX_BUFF_RE			(RX_BUFF_RE),			// RX Buffer Read Enable
		.RX_BUFF_DATA		(RX_BUFF_DATA),		// RX Buffer Data
		.RX_BUFF_EMPTY		(RX_BUFF_EMPTY),		// RX Buffer Empty(1: Empty, 0: No Empty)
		.RX_BUFF_VALID		(RX_BUFF_VALID),		// RX Buffer Valid
		.RX_BUFF_LENGTH		(RX_BUFF_LENGTH),		// RX Buffer Length
		.RX_BUFF_STATUS		(RX_BUFF_STATUS),		// RX Buffer Status

		// TX Buffer Interface
		.TX_BUFF_WE			(TX_BUFF_WE),			// TX Buffer Write Enable
		.TX_BUFF_START		(TX_BUFF_START),		// TX Buffer Data Start
		.TX_BUFF_END		(TX_BUFF_END),		// TX Buffer Data End
		.TX_BUFF_READY		(TX_BUFF_READY),		// TX Buffer Ready
		.TX_BUFF_DATA		(TX_BUFF_DATA),		// TX Buffer Data
		.TX_BUFF_FULL		(TX_BUFF_FULL),		// TX Buffer Full
		.TX_BUFF_SPACE		(TX_BUFF_SPACE),		// TX Buffer Space

		// From CPU
		.PAUSE_QUANTA_DATA	( 16'd0					),	// Pause Quanta value
		.PAUSE_SEND_ENABLE	( 1'd0					),	// Pause Send Enable
		.TX_PAUSE_ENABLE	( 1'd0					),	// TX MAC Pause Enable

		.PEER_MAC_ADDRESS	( peer_mac_address		),
		.PEER_IP_ADDRESS	( DEFAULT_PEER_IP_ADRS	),
		.MY_MAC_ADDRESS		( DEFAULT_MY_MAC_ADRS	),
		.MY_IP_ADDRESS		( DEFAULT_MY_IP_ADRS	),
		.PORT0				( 16'd1234				),
		.PORT1				( 16'd1236				),
		.PORT2				( 16'd1238				),
		.PORT3				( 16'd1240				),

		.ARPC_ENABLE		(arpc_enable),		// ARP Cache Request Enable
		.ARPC_REQUEST		(arpc_request),		// ARP Cache Request
		.ARPC_VALID			(arpc_valid),			// ARP Cache Valid

		.MAX_RETRY			( 4'd4					),			// Max Retry
		.GIG_MODE			( 1'b0					),			// Operation Mode(1: Giga Mode, 0: 10/100Mbps)
		.FULL_DUPLEX		( 1'b1					),		// Operation Mode(1: Full Duplex, 0: Half Duplex)

		// Send UDP
		.SEND_REQUEST		(1'd0),
		.SEND_LENGTH		(16'd0),
		.SEND_BUSY			(),
		.SEND_DSTPORT		(16'd0),
		.SEND_SRCPORT		(16'd0),
		.SEND_DATA_VALID	(1'd0),
		.SEND_DATA_READ		(),
		.SEND_DATA			(32'd0),

		// Receive UDP
		.REC_REQUEST		(),
		.REC_LENGTH			(),
		.REC_BUSY			(),
		.REC_DATA_VALID		(),
		.REC_DATA_READ		(1'd0),
		.REC_DATA			()
	);

	reg [1:0] arp_state;
	always @(posedge CLK100MHZ or negedge RST_N) begin
		if(!RST_N) begin
			arp_state <= 2'd0;
		end else begin
			case(arp_state[1:0])
				2'd0: begin
					if(arpc_valid == 1'b0) begin
						arp_state <= 2'd1;
					end
				end
				2'd1: begin
					if(arpc_enable == 1'b1) begin
						arp_state <= 2'd2;
					end
				end
				2'd2: begin
				end
			endcase
		end
	end

	assign arpc_request = (arp_state == 2'd1)?1'b1:1'b0;

	// Other Signals
	assign giga_mode			= 1'b1;
	assign full_duplex		  = 1'b1;
	assign pause_quanta_data	= 16'h0000;
	assign puase_send_enable	= 1'b0;
	assign tx_pause_enable	  = 1'b0;
	assign max_retry			= 4'd8;
	assign random_time_meet	 = 1'b1;

	ether_udp_loop u_ether_udp_loop(
		.RST(RST_N),
		.CLK(CLK100MHZ),

		.UDP_PEER_MAC_ADDRESS(peer_mac_address),
		.UDP_PEER_IP_ADDRESS(DEFAULT_PEER_IP_ADRS),
		.UDP_MY_MAC_ADDRESS(DEFAULT_MY_MAC_ADRS),
		.UDP_MY_IP_ADDRESS(DEFAULT_MY_IP_ADRS),

		.UDP_PEER_ENABLE(arp_state[2]),

		// for ETHER-MAC BUFFER
		.TX_WE(TX_BUFF_WE),
		.TX_START(TX_BUFF_START),
		.TX_END(TX_BUFF_END),
		.TX_READY(TX_BUFF_READY),
		.TX_DATA(TX_BUFF_DATA),
		.TX_FULL(TX_BUFF_FULL),
		.TX_SPACE(TX_BUFF_SPACE),

		.RX_RE(RX_BUFF_RE),
		.RX_DATA(RX_BUFF_DATA),
		.RX_EMPTY(RX_BUFF_EMPTY),
		.RX_VALID(RX_BUFF_VALID),
		.RX_LENGTH(RX_BUFF_LENGTH),
		.RX_STATUS(RX_BUFF_STATUS),

		.STATUS()
	);

	// LED

//	reg [31:0]  pci_cnt;
//	reg		 pci_led;
//	always @(posedge pci_clk or negedge RST_N) begin
//		if(!RST_N) begin
//			pci_cnt[31:0]   <= 32'd0;
//			pci_led		 <= 1'b0;
//		end else begin
//			if(pci_cnt[31:0] == (33000000/2 -1)) begin
//				pci_cnt[31:0]   <= 32'd0;
//				pci_led		 <= ~pci_led;
//			end else begin
//				pci_cnt[31:0]   <= pci_cnt[31:0] + 32'd1;
//			end
//		end
//	end
/*
	reg		last_rx, last_tx;
	always @(posedge CLK100M or negedge RST_N) begin
		if(!RST_N) begin
			last_rx <= 1'b0;
			last_tx <= 1'b0;
		end else begin
			if(rx_buff_re & !erx_buff_re) begin
				last_rx <= 1'b1;
			end else if(erx_buff_re) begin
				last_rx <= 1'b0;
			end
			if(tx_buff_we & !etx_buff_we) begin
				last_tx <= 1'b1;
			end else if(etx_buff_we) begin
				last_tx <= 1'b0;
			end
		end
	end
*/

endmodule
