/*
* PROJECT: AQUAXIS Giga Ethernet MAC
* ----------------------------------------------------------------------
*
* tb_aq_gemac_ip.v
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
* 2013/02/26 H.Ishihara	Create
*/
`timescale 1ps / 1ps

module tb_aq_gemac_ip;

	parameter	TIME10N	= 10000;
	parameter	TIME8N	=  8000;

	reg			RST_N;
	reg			SYS_CLK;

	reg			TX_BUFF_WE, TX_BUFF_START, TX_BUFF_END;
	wire		TX_BUFF_READY;
	reg	[31:0]	TX_BUFF_DATA;
	wire		TX_BUFF_FULL;
	wire [9:0]	TX_BUFF_SPACE;

	reg			RX_BUFF_RE;
	wire		RX_BUFF_EMPTY;
	wire [31:0]	RX_BUFF_DATA;
	wire		RX_BUFF_VALID;
	wire [15:0]	RX_BUFF_LENGTH;
	wire [15:0]	RX_BUFF_STATUS;

	reg			MAC_CLK;

	reg			MIIM_CLK;
	
	wire [7:0]	TXD;
	wire		TX_EN;
	wire		TX_ER;
	wire		CRS;
	wire		COL;
	wire [7:0]	RXD;
	wire		RX_DV;
	wire		RX_ER;

	reg [15:0]	PAUSE_QUANTA_DATA;
	reg			PAUSE_SEND_ENABLE;
	reg			TX_PAUSE_ENABLE;

	reg [47:0]	MY_MAC_ADDRESS;
	reg [31:0]	MY_IP_ADDRESS;
	wire [47:0]	PEER_MAC_ADDRESS;
	reg [31:0]	PEER_IP_ADDRESS;

	reg [3:0]	MAX_RETRY;
	reg			GIG_MODE;
	reg			FULL_DUPLEX;

	wire		ARPC_ENABLE;
	reg			ARPC_REQUEST;
	wire		ARPC_VALID;

	reg			SEND_REQUEST;
	reg [15:0]	SEND_LENGTH;
	wire		SEND_BUSY;
	reg [47:0]	SEND_MAC_ADDRESS;
	reg [31:0]	SEND_IP_ADDRESS;
	reg [15:0]	SEND_DST_PORT;
	reg [15:0]	SEND_SRC_PORT;
	reg			SEND_DATA_VALID;
	wire		SEND_DATA_READ;
	reg [31:0]	SEND_DATA;

	wire		REC_REQUEST;
	wire [15:0]	REC_LENGTH;
	wire		REC_BUSY;
	reg [15:0]	REC_DST_PORT0;
	reg [15:0]	REC_DST_PORT1;
	reg [15:0]	REC_DST_PORT2;
	reg [15:0]	REC_DST_PORT3;
	wire [3:0]	REC_DATA_VALID;
	wire [47:0]	REC_SRC_MAC;
	wire [31:0]	REC_SRC_IP;
	wire [15:0]	REC_SRC_PORT;
	reg			REC_DATA_READ;
	wire [31:0]	REC_DATA;

	aq_gemac_ip_top
	#(
		.USE_MIIM			( 0					)
	)
	u_aq_gemac_ip_top(
		.RST_N				( RST_N				),
		.SYS_CLK			( SYS_CLK			),

		// GEMAC Interface
		.EMAC_CLK125M		( MAC_CLK			),
		.EMAC_GTX_CLK		( EMAC_GTX_CLK		),

		.EMAC_TX_CLK		( MAC_CLK			),
		.EMAC_TXD			( TXD				),
		.EMAC_TX_EN			( TX_EN				),
		.EMAC_TX_ER			( TX_ER				),
		.EMAC_COL			( COL				),
		.EMAC_CRS			( CRS				),

		.EMAC_RX_CLK		( MAC_CLK			),
		.EMAC_RXD			( RXD				),
		.EMAC_RX_DV			( RX_DV				),
		.EMAC_RX_ER			( RX_ER				),

		.EMAC_RST			( EMAC_RST			),

		// GEMAC MIIM Interface
		.MIIM_MDC			( MIIM_CLK			),
		.MIIM_MDIO			( MIIM_MDIO			),

		.MIIM_REQUEST		(),
		.MIIM_WRITE			(),
		.MIIM_PHY_ADDRESS	(),
		.MIIM_REG_ADDRESS	(),
		.MIIM_WDATA			(),
		.MIIM_RDATA			(),
		.MIIM_BUSY			(),

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
		.PAUSE_QUANTA_DATA	( PAUSE_QUANTA_DATA	),
		.PAUSE_SEND_ENABLE	( PAUSE_SEND_ENABLE	),
		.TX_PAUSE_ENABLE	( TX_PAUSE_ENABLE	),

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
		.SEND_REQUEST		( SEND_REQUEST		),
		.SEND_LENGTH		( SEND_LENGTH		),
		.SEND_BUSY			( SEND_BUSY			),
		.SEND_MAC_ADDRESS	( SEND_MAC_ADDRESS	),
		.SEND_IP_ADDRESS	( SEND_IP_ADDRESS	),
		.SEND_DST_PORT		( SEND_DST_PORT		),
		.SEND_SRC_PORT		( SEND_SRC_PORT		),
		.SEND_DATA_VALID	( SEND_DATA_VALID	),
		.SEND_DATA_READ		( SEND_DATA_READ	),
		.SEND_DATA			( SEND_DATA			),

		// Receive UDP
		.REC_REQUEST		( REC_REQUEST		),
		.REC_LENGTH			( REC_LENGTH		),
		.REC_BUSY			( REC_BUSY			),
		.REC_DST_PORT0		( REC_DST_PORT0		),
		.REC_DST_PORT1		( REC_DST_PORT1		),
		.REC_DST_PORT2		( REC_DST_PORT2		),
		.REC_DST_PORT3		( REC_DST_PORT3		),
		.REC_DATA_VALID		( REC_DATA_VALID	),
		.REC_SRC_MAC		( REC_SRC_MAC		),
		.REC_SRC_IP			( REC_SRC_IP		),
		.REC_SRC_PORT		( REC_SRC_PORT		),
		.REC_DATA_READ		( REC_DATA_READ		),
		.REC_DATA			( REC_DATA			)
	);

	assign #100		RXD		= TXD;
	assign #100		RX_DV	= TX_EN;
	assign #100		RX_ER	= TX_ER;
	assign #100		CRS		= TX_EN;
	assign 			COL		= 1'b0;

	// Reset, Clock
	initial begin
		RST_N		= 0;
		SYS_CLK		= 0;
		MAC_CLK		= 0;
		MIIM_CLK	= 0;
		repeat (10) @(negedge SYS_CLK);
		RST_N		= 1;
	end

	// System Clock(100MHz)
	always begin
	    #(TIME10N/2) SYS_CLK <= ~SYS_CLK;
	end

	// PHY I/F Clock(125MHz)
	always begin
	    #(TIME8N/2) MAC_CLK <= ~MAC_CLK;
	end

	// Initialize for Signal
	initial begin
		MY_MAC_ADDRESS		= 48'h151413121110;
		MY_IP_ADDRESS		= 32'h0101A8C0;
		PEER_IP_ADDRESS		= 32'h0201A8C0;

		MAX_RETRY			= 4'd8;
		GIG_MODE			= 1;
		FULL_DUPLEX			= 1;

		PAUSE_QUANTA_DATA	= 16'h0000;
		PAUSE_SEND_ENABLE	= 0;
		TX_PAUSE_ENABLE		= 0;

		RX_BUFF_RE			= 0;
		
		ARPC_REQUEST		= 0;
		
		SEND_REQUEST		= 0;
		SEND_LENGTH			= 16'd0;
		SEND_MAC_ADDRESS	= 48'd0;
		SEND_IP_ADDRESS		= 32'd0;
		SEND_DST_PORT		= 16'd0;
		SEND_SRC_PORT		= 16'd0;
		SEND_DATA_VALID		= 0;
		SEND_DATA			= 32'd0;
		
		REC_DST_PORT0		= 16'h0040;
		REC_DST_PORT1		= 16'h0140;
		REC_DST_PORT2		= 16'h0240;
		REC_DST_PORT3		= 16'h0340;
		REC_DATA_READ		= 1;
	end

	initial begin
		wait(RX_BUFF_VALID);
		@(negedge SYS_CLK);

		repeat (100) @(negedge SYS_CLK);

		//$finish();
	end

	task WRITE;
		input			Start;
		input			End;
		input [31:0]	Data;
		begin
			wait(!TX_BUFF_FULL);

			TX_BUFF_WE		= 1;
			TX_BUFF_START	= Start;
			TX_BUFF_END		= End;
			TX_BUFF_DATA	= Data;
			@(posedge SYS_CLK);
			TX_BUFF_WE		= 0;
			TX_BUFF_START	= 0;
			TX_BUFF_END		= 0;
			TX_BUFF_DATA	= 32'd0;
			@(posedge SYS_CLK);
		end
	endtask
	
	// ARP Request task
	task ARP_REQ;
		input [31:0]	IpAdrs;
		begin
			// ARP Request
			$display("========================================");
			$display(" ARP Request(%d)", $time/1000);
			$display("========================================");
			wait( ARPC_ENABLE	);
		
			ARPC_REQUEST 		= 1;
			PEER_IP_ADDRESS		= IpAdrs;

			$display(" - Request for %08x(%d)", IpAdrs, $time/1000);

			@(posedge SYS_CLK);

			$display(" - Wait for !ARPC_ENABLE");
			
			wait( !ARPC_ENABLE	);
			ARPC_REQUEST = 0;
			@(posedge SYS_CLK);
			
			$display(" - Wait for ARP Transmit Reply");
			wait( u_aq_gemac_ip_top.u_aq_gemac_ip.u_aq_gemac_l3_ctrl.ArpState == 5'd28	);
			$display(" - Detect with ARP Transmit Reply(%d)", $time/1000);
			@(posedge SYS_CLK);
			@(posedge SYS_CLK);

			$display(" - Wait for ARP Receive Reply");
			wait( u_aq_gemac_ip_top.u_aq_gemac_ip.u_aq_gemac_l3_ctrl.ArpState == 5'd28	);
			$display(" - Detect with ARP Receive Reply(%d)", $time/1000);
			@(posedge SYS_CLK);
			@(posedge SYS_CLK);

			$display(" - Wait for ARPC_VALID");

			wait( ARPC_VALID	);
			@(posedge SYS_CLK);

			$display(" - Detect with ARPC_VALID");
			$display(" - Finished ARP Request");
			@(posedge SYS_CLK);
		end
	endtask

	// ICMP Request
	task ICMP_REQ;
		input [31:0]	DstIpAdrs;
		input [31:0]	SrcIpAdrs;
		begin
			// ARP Request
			$display("========================================");
			$display(" ICMP Request(%d)", $time/1000);
			$display("========================================");
			wait( TX_BUFF_READY	);
			@(posedge SYS_CLK);
			$display(" - Request(%d)", $time/1000);
			// ICMP Echo Request
			WRITE( 1'b1, 1'b0, 32'h004A0000);	// 74Byte
			WRITE( 1'b0, 1'b0, 32'h22b10600);
			WRITE( 1'b0, 1'b0, 32'h1300d0c7);
			WRITE( 1'b0, 1'b0, 32'hbcf5cc20);
			WRITE( 1'b0, 1'b0, 32'h00450008);
			WRITE( 1'b0, 1'b0, 32'h3d9e3c00);
			WRITE( 1'b0, 1'b0, 32'h01800000);
			WRITE( 1'b0, 1'b0, {SrcIpAdrs[15:0], 16'h0000});	// IP CheckSum: 0x1929
			WRITE( 1'b0, 1'b0, {DstIpAdrs[15:0], SrcIpAdrs[31:16]});
			WRITE( 1'b0, 1'b0, {16'h0008, DstIpAdrs[31:16]});
			WRITE( 1'b0, 1'b0, 32'h00020000);	// ICMP CheckSim: 0x3E5C
			WRITE( 1'b0, 1'b0, 32'h6261000d);
			WRITE( 1'b0, 1'b0, 32'h66656463);
			WRITE( 1'b0, 1'b0, 32'h6a696867);
			WRITE( 1'b0, 1'b0, 32'h6e6d6c6b);
			WRITE( 1'b0, 1'b0, 32'h7271706f);
			WRITE( 1'b0, 1'b0, 32'h76757473);
			WRITE( 1'b0, 1'b0, 32'h63626177);
			WRITE( 1'b0, 1'b0, 32'h67666564);
			WRITE( 1'b0, 1'b1, 32'h00006968);

			$display(" - Wait for TX_BUFF_READY");
			wait( TX_BUFF_READY	);

			$display(" - Wait for ICMP Transmit Reply");
			wait( u_aq_gemac_ip_top.u_aq_gemac_ip.u_aq_gemac_l3_ctrl.IcmpState == 5'd25	);
			$display(" - Detect with ICMP Transmit Reply(%d)", $time/1000);
			@(posedge SYS_CLK);
			@(posedge SYS_CLK);

			$display(" - Wait for ICMP Receive Reply");
			wait( u_aq_gemac_ip_top.u_aq_gemac_ip.u_aq_gemac_l3_ctrl.IcmpState == 5'd25	);
			$display(" - Detect with ICMP Receive Reply(%d)", $time/1000);
			@(posedge SYS_CLK);
			@(posedge SYS_CLK);

			$display(" - Finished ICMP Request");
			@(posedge SYS_CLK);
		end
	endtask

	// UDP Transmit
	task UDP_TRANSMIT;
		input [31:0]	DstIpAdrs;
		input [31:0]	SrcIpAdrs;
		input [15:0]	DstPort;
		input [15:0]	SrcPort;
		begin
			// UDP Transmit
			$display("========================================");
			$display(" UDP Transmit(%d)", $time/1000);
			$display("========================================");
			wait( TX_BUFF_READY	);
			@(posedge SYS_CLK);
			$display(" - Request(%d)", $time/1000);
			// UDP Transmit Request
			WRITE( 1'b1, 1'b0, 32'h004A0000);	// 74Byte
			WRITE( 1'b0, 1'b0, 32'h22b10600);
			WRITE( 1'b0, 1'b0, 32'h1300d0c7);
			WRITE( 1'b0, 1'b0, 32'hbcf5cc20);
			WRITE( 1'b0, 1'b0, 32'h00450008);
			WRITE( 1'b0, 1'b0, 32'h3d9e3c00);
			WRITE( 1'b0, 1'b0, 32'h11800000);
			WRITE( 1'b0, 1'b0, {SrcIpAdrs[15:0], 16'h0000});
			WRITE( 1'b0, 1'b0, {DstIpAdrs[15:0], SrcIpAdrs[31:16]});
			WRITE( 1'b0, 1'b0, {SrcPort[15:0], DstIpAdrs[31:16]});
			WRITE( 1'b0, 1'b0, {17'h2800, DstPort[15:0]});
			WRITE( 1'b0, 1'b0, 32'h62610000);
			WRITE( 1'b0, 1'b0, 32'h66656463);
			WRITE( 1'b0, 1'b0, 32'h6a696867);
			WRITE( 1'b0, 1'b0, 32'h6e6d6c6b);
			WRITE( 1'b0, 1'b0, 32'h7271706f);
			WRITE( 1'b0, 1'b0, 32'h76757473);
			WRITE( 1'b0, 1'b0, 32'h63626177);
			WRITE( 1'b0, 1'b0, 32'h67666564);
			WRITE( 1'b0, 1'b1, 32'h00006968);

			$display(" - Wait for TX_BUFF_READY");
			wait( TX_BUFF_READY	);

			$display(" - Finished UDP Transmit");
			@(posedge SYS_CLK);
		end
	endtask
	
	// UDP Request
	task UDP_REQ;
		input [47:0]	DstMacAdrs;
		input [31:0]	DstIpAdrs;
		input [15:0]	DstPort;
		input [15:0]	SrcPort;
		input [15:0]	Length;
		reg [15:0]		Count;
		begin
			// UDP Transmit
			$display("========================================");
			$display(" UDP Request(%d)", $time/1000);
			$display("========================================");
			wait( !SEND_BUSY	);
			@(posedge SYS_CLK);
			$display(" - Request(%d)", $time/1000);
			SEND_MAC_ADDRESS	= DstMacAdrs;
			SEND_IP_ADDRESS		= DstIpAdrs;
			SEND_DST_PORT		= DstPort;
			SEND_SRC_PORT		= SrcPort;
			SEND_LENGTH			= Length;
			Count				= Length;
			SEND_REQUEST		= 1;
			@(posedge SYS_CLK);

			wait( SEND_BUSY	);
			SEND_REQUEST		= 0;

			SEND_DATA_VALID		= 1;
			while( Count >= 4	)
			begin
				SEND_DATA	= {Count, Count};
				wait( SEND_DATA_READ	);
				@(posedge SYS_CLK);
				Count = Count -4;
			end
			SEND_DATA_VALID		= 0;

			wait( !SEND_BUSY	);

			$display(" - Finished UDP Transmit");
			@(negedge SYS_CLK);
		end
	endtask
	
	initial begin
		$display("========================================");
		$display(" Simulation for GEMAC");
		$display("========================================");
		$display(" - System Reqest");
		TX_BUFF_WE		= 0;
		TX_BUFF_START	= 0;
		TX_BUFF_END		= 0;
		TX_BUFF_DATA	= 32'd0;

		wait(RST_N);

		repeat (10) @(negedge SYS_CLK);

		wait(TX_BUFF_READY);
		$display(" - Simluation Start");

		// ARP Request
		ARP_REQ( 32'h0101A8C0 );

		// ICMP Request
		ICMP_REQ( 32'h0101A8C0,  32'h0901A8C0 );

		$display("========================================");
		$display(" UDP Normal Transmit -> PORT 0");
		$display("========================================");
		UDP_TRANSMIT( 32'h0101A8C0, 32'h0901A8C0, 16'h0040, 16'h0080 );
		wait( REC_DATA_VALID[0]	);
		$display(" Detect with UDP Port 0(%d)", $time/1000);
		@(negedge SYS_CLK);
		wait( !REC_BUSY	);
		@(negedge SYS_CLK);
		
		$display("========================================");
		$display(" UDP Send Request -> PORT 1");
		$display("========================================");
		UDP_REQ( 48'h010102020303, 32'h0101A8C0, 16'h0140, 16'h0080, 16'd32);
		wait( REC_DATA_VALID[1]	);
		$display(" Detect with UDP Port 1(%d)", $time/1000);
		@(negedge SYS_CLK);
		wait( !REC_BUSY	);
		@(negedge SYS_CLK);
		
		$display("========================================");
		$display(" UDP Send Request -> PORT 2");
		$display("========================================");
		UDP_REQ( 48'h010102020303, 32'h0101A8C0, 16'h0240, 16'h0080, 16'd32);
		wait( REC_DATA_VALID[2]	);
		$display(" Detect with UDP Port 2(%d)", $time/1000);
		@(negedge SYS_CLK);
		wait( !REC_BUSY	);
		@(negedge SYS_CLK);
		
		$display("========================================");
		$display(" UDP Send Request -> PORT 3");
		$display("========================================");
		UDP_REQ( 48'h010102020303, 32'h0101A8C0, 16'h0340, 16'h0080, 16'd32);
		wait( REC_DATA_VALID[3]	);
		$display(" Detect with UDP Port 3(%d)", $time/1000);
		@(negedge SYS_CLK);
		wait( !REC_BUSY	);
		@(negedge SYS_CLK);
		
		@(negedge SYS_CLK);

		PAUSE_QUANTA_DATA	= 16'h0800;
		PAUSE_SEND_ENABLE	= 0;
		TX_PAUSE_ENABLE		= 0;

		repeat (100) @(negedge SYS_CLK);

		$display("========================================");
		$display(" Finished Simulation(%d)", $time/1000);
		$display("========================================");

		$finish();
	end
	
	//
	always @(posedge SYS_CLK) begin
		if( REC_DATA_VALID[0] == 1 )
		$display(" REC_DATA_VALID[0] - %08X(%d)", REC_DATA[31:0], $time/1000);
		if( REC_DATA_VALID[1] == 1 )
		$display(" REC_DATA_VALID[1] - %08X(%d)", REC_DATA[31:0], $time/1000);
		if( REC_DATA_VALID[2] == 1 )
		$display(" REC_DATA_VALID[2] - %08X(%d)", REC_DATA[31:0], $time/1000);
		if( REC_DATA_VALID[3] == 1 )
		$display(" REC_DATA_VALID[3] - %08X(%d)", REC_DATA[31:0], $time/1000);
	end
	
endmodule
