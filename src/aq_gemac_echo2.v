/*
* PROJECT: AQUAXIS Giga Ethernet MAC
* ----------------------------------------------------------------------
*
* ARP/ICMP echo with Gigabit MAC
* File: aq_gemac_echo.v
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
*/
`timescale 1ps / 1ps

module aq_gemac_echo2
(
 input        RESET,

 input        CLK125M_P,
 input        CLK125M_N,

 //input        EMAC_TX_CLK, // Tx Clock(In)  for 10/100 Mode
 output       EMAC_TX_CLK, // Tx Clock(In)  for 10/100 Mode
 output [3:0] EMAC_TXD_O, // Tx Data
 output       EMAC_TX_EN, // Tx Data Enable
 output       EMAC_TX_ER, // Tx Error

 input        EMAC_RX_CLK, // Rx Clock(In)  for 10/100/1000 Mode
 input [3:0]  EMAC_RXD_I, // Rx Data
 input        EMAC_RX_DV, // Rx Data Valid
 input        EMAC_RX_ER, // Rx Error

 output [7:0] LED,

 input        SW_IP_ADDR
);

   wire       RST_N;

   // RESTE
   assign RST_N = ~RESET;

   wire [47:0] DEFAULT_MY_MAC_ADRS;
   wire [31:0] DEFAULT_MY_IP_ADRS;
   wire [31:0] DEFAULT_PEER_IP_ADRS;

   // Select for IP Address
   assign DEFAULT_MY_MAC_ADRS = (SW_IP_ADDR)?48'h332211000001:48'h332211000000;
   assign DEFAULT_MY_IP_ADRS  = (SW_IP_ADDR)?32'h960DA8C0:32'h960DA8C1;
   assign DEFAULT_PEER_IP_ADRS = (SW_IP_ADDR)?32'h960DA8C1:32'h960DA8C0;

   wire       EMAC_COL; // Collision signal
   wire       EMAC_CRS; // CRS

   wire [7:0] EMAC_TXD; // Tx Data
   wire [7:0] EMAC_RXD; // Rx Data

   assign EMAC_TXD_O[3:0] = EMAC_TXD[3:0];
   assign EMAC_RXD[3:0] = EMAC_RXD_I[3:0];
   assign EMAC_RXD[7:4] = 4'd0;

   assign EMAC_CLK125M = 1'b0;
   assign EMAC_GTX_CLK = 1'b0;
   assign EMAC_COL = 1'b0;
   assign EMAC_CRS = 1'b0;
   assign EMAC_INT = 1'b0;
   assign MIIM_MDC = 1'b0;

   // Clock
   wire       CLK125M_I;
   wire       CLK125M_B;
   wire       CLK125M;
   wire       PLL_LOCKED;

   IBUFDS u_CLK125M
     (
      .I(CLK125M_P), .IB(CLK125M_N), .O(CLK125M_I)
      );

   BUFGCE u_CLK125M_BUFGCE
     (
      .I(CLK125M_I),
      .O(CLK125M_B)
      );

   assign CLK125M = CLK125M_B;

   BUFGCE_DIV
     #(
       .BUFGCE_DIVIDE(5)
       )
   u_CLK25M
     (
      .I(CLK125M_B),
      .CE(1'b1),
      .CLR(1'b0),
      .O(CLK25M)
      );

/*
   clk_wiz_0 u_clk_wiz
     (
//      .reset(RESET),
      .clk_in1(CLK125M_I),
      .clk_out1(CLK125M),
      .clk_out2(CLK25M),
      .locked(PLL_LOCKED)
      );
*/

   // Clock Count
   reg [31:0] clk125m_count;
   reg        clk125m_led;
   always @(posedge CLK125M) begin
      if(clk125m_count < 125000000) begin
         clk125m_count <= clk125m_count +1;
      end else begin
         clk125m_count <= 0;
         clk125m_led <= ~clk125m_led;
      end
   end

   reg [31:0] clk25m_count;
   reg        clk25m_led;
   always @(posedge CLK25M) begin
      if(clk25m_count < 25000000) begin
         clk25m_count <= clk25m_count +1;
      end else begin
         clk25m_count <= 0;
         clk25m_led <= ~clk25m_led;
      end
   end

   //	PULLUP u_RST_N(.O(RST_N));
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

   assign EMAC_TX_CLK = ~CLK25M;

   wire [15:0]  l3_ext_status;

	aq_gemac_ip2 u_aq_gemac_ip2(
		.RST_N				( RST_N			),
		.SYS_CLK			( CLK125M		),

        // GEMAC Interface
		.EMAC_TX_CLK		(CLK25M),		// Tx Clock(In)  for 10/100 Mode
		.EMAC_TXD			(EMAC_TXD),			// Tx Data
		.EMAC_TX_EN			(EMAC_TX_EN),			// Tx Data Enable
		.EMAC_TX_ER			(EMAC_TX_ER),			// Tx Error
		.EMAC_COL			(EMAC_COL),			// Collision signal
		.EMAC_CRS			(EMAC_CRS),			// CRS

		.EMAC_RX_CLK		(EMAC_RX_CLK),		// Rx Clock(In)  for 10/100/1000 Mode
		.EMAC_RXD			(EMAC_RXD),			// Rx Data
		.EMAC_RX_DV			(EMAC_RX_DV),			// Rx Data Valid
		.EMAC_RX_ER			(EMAC_RX_ER),			// Rx Error

		// RX Buffer Interface
		.RX_BUFF_RE			(1'b0),			// RX Buffer Read Enable
		.RX_BUFF_DATA		(),		// RX Buffer Data
		.RX_BUFF_EMPTY		(rx_buff_empty),		// RX Buffer Empty(1: Empty, 0: No Empty)
		.RX_BUFF_VALID		(rx_buff_valid),		// RX Buffer Valid
		.RX_BUFF_LENGTH		(),		// RX Buffer Length
		.RX_BUFF_STATUS		(),		// RX Buffer Status

		// TX Buffer Interface
		.TX_BUFF_WE			(1'd0),			// TX Buffer Write Enable
		.TX_BUFF_START		(1'd0),		// TX Buffer Data Start
		.TX_BUFF_END		(1'd0),		// TX Buffer Data End
		.TX_BUFF_READY		(),		// TX Buffer Ready
		.TX_BUFF_DATA		(32'd0),		// TX Buffer Data
		.TX_BUFF_FULL		(),		// TX Buffer Full
		.TX_BUFF_SPACE		(),		// TX Buffer Space

		// From CPU
		.PAUSE_QUANTA_DATA	( 16'd0					),	// Pause Quanta value
		.PAUSE_SEND_ENABLE	( 1'd0					),	// Pause Send Enable
		.TX_PAUSE_ENABLE	( 1'd0					),	// TX MAC Pause Enable

		.PEER_MAC_ADDRESS	( peer_mac_address		),
		.PEER_IP_ADDRESS	( DEFAULT_PEER_IP_ADRS	),
		.MY_MAC_ADDRESS		( DEFAULT_MY_MAC_ADRS	),
		.MY_IP_ADDRESS		( DEFAULT_MY_IP_ADRS	),

		.ARPC_ENABLE		(arpc_enable),		// ARP Cache Request Enable
		.ARPC_REQUEST		(arpc_request),		// ARP Cache Request
		.ARPC_VALID			(arpc_valid),			// ARP Cache Valid

		.MAX_RETRY			( 4'd4					),			// Max Retry
		.GIG_MODE			( 1'b0					),			// Operation Mode(1: Giga Mode, 0: 10/100Mbps)
		.FULL_DUPLEX		( 1'b1					),		// Operation Mode(1: Full Duplex, 0: Half Duplex)
        .L3_EXT_STATUS      ( l3_ext_status )
	);

	reg [1:0] arp_state;
	always @(posedge CLK125M or negedge RST_N) begin
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
	assign giga_mode			= 1'b0;
	assign full_duplex		  = 1'b1;
	assign pause_quanta_data	= 16'h0000;
	assign puase_send_enable	= 1'b0;
	assign tx_pause_enable	  = 1'b0;
	assign max_retry			= 4'd8;
	assign random_time_meet	 = 1'b1;

   assign LED[0] = clk25m_led;
   assign LED[1] = SW_IP_ADDR;
   assign LED[2] = arpc_enable;
   assign LED[3] = arpc_valid;
   assign LED[4] = rx_buff_empty;
   assign LED[5] = l3_ext_status[0];
   assign LED[6] = l3_ext_status[1];
   assign LED[7] = l3_ext_status[2];

endmodule
