/*
* PROJECT: AQUAXIS Giga Ethernet MAC
* ----------------------------------------------------------------------
*
* tb_aq_gemac_udp.v
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
* 2007/01/06 1st release
* 2007/08/22 remove pause test
* 2011/04/24 rename
* 2013/01/22 modify
*/
`timescale 1ps / 1ps

module tb_aq_gemac_udp;
	parameter MY_MAC_ADRS  = 48'h332211000000;
	parameter MY_IP_ADRS   = 32'h5A00A8C0;		// 192.168.0.90
	parameter REC_DSTPORT0 = 16'd0004;			// 1024
	parameter REC_DSTPORT1 = 16'd0104;			// 1025
	parameter REC_DSTPORT2 = 16'd0204;			// 1026
	parameter REC_DSTPORT3 = 16'd0304;			// 1027
	parameter SEND_DSTPORT = 16'd0004;			// 1024
	parameter PEER_IP_ADRS = 32'h1A00A8C0;		// 192.168.0.26

	parameter	TIME10N	= 10000;	// 100MHz
	parameter	TIME8N	=  8000;	// 125MHz

	reg			RST_N;

	reg			CLK100M;

	reg			EMAC_CLK125M;	// Clock 125MHz
	wire		EMAC_GTX_CLK;	// Tx Clock(Out) for 1000 Mode

	reg			EMAC_TX_CLK;	// Tx Clock(In)  for 10/100 Mode
	wire [7:0]	EMAC_TXD;		// Tx Data
	wire			EMAC_TX_EN;		// Tx Data Enable
	wire			EMAC_TX_ER;		// Tx Error
	wire			EMAC_COL;		// Collision signal
	wire			EMAC_CRS;		// CRS

	wire			EMAC_RX_CLK;	// Rx Clock(In)  for 10/100/1000 Mode
	wire [7:0]		EMAC_RXD;		// Rx Data
	wire			EMAC_RX_DV;		// Rx Data Valid
	wire			EMAC_RX_ER;		// Rx Error

	reg			EMAC_INT;		// Interrupt
	wire			EMAC_RST;

	reg			MIIM_MDC;		// MIIM Clock
	reg			MIIM_MDIO;		// MIIM I/O

	wire [47:0]	PEER_MAC_ADDRESS;
	reg [31:0]	PEER_IP_ADDRESS;
	reg [47:0]	MY_MAC_ADDRESS;
	reg [31:0]	MY_IP_ADDRESS;

	// Send UDP
	reg			SEND_REQUEST;
	reg [15:0]	SEND_LENGTH;
	wire			SEND_BUSY;
	reg [15:0]	SEND_SRCPORT;
	reg			SEND_DATA_VALID;
	wire			SEND_DATA_READ;
	reg [31:0]	SEND_DATA;

	// Receive UDP
	wire			REC_REQUEST;
	wire [15:0]	REC_LENGTH;
	wire			REC_BUSY;
	wire [3:0]	REC_DATA_VALID;
	reg			REC_DATA_READ;
	wire [31:0]	REC_DATA;

	aq_gemac_udp u_aq_gemac_udp(
		.RST_N			( RST_N		),

		.CLK100M		( CLK100M	),

		.EMAC_CLK125M	( CLK125M	),

		.EMAC_GTX_CLK	( EMAC_GTX_CLK	),
		.EMAC_TX_CLK	( EMAC_TX_CLK	),
		.EMAC_TXD		( EMAC_TXD		),
		.EMAC_TX_EN		( EMAC_TX_EN	),
		.EMAC_TX_ER		( EMAC_TX_ER	),
		.EMAC_COL		( EMAC_COL		),
		.EMAC_CRS		( EMAC_CRS		),

		.EMAC_RX_CLK	( EMAC_RX_CLK	),
		.EMAC_RXD		( EMAC_RXD		),
		.EMAC_RX_DV		( EMAC_RX_DV	),
		.EMAC_RX_ER		( EMAC_RX_ER	),

		.EMAC_INT		( EMAC_INT		),
		.EMAC_RST		( EMAC_RST		),

		.MIIM_MDC		( MIIM_MDC		),
		.MIIM_MDIO		( MIIM_MDIO		),

		.PEER_MAC_ADDRESS   ( PEER_MAC_ADDRESS		),
		.PEER_IP_ADDRESS	( PEER_IP_ADRS	),
		.MY_MAC_ADDRESS		( MY_MAC_ADRS	),
		.MY_IP_ADDRESS		( MY_IP_ADRS	),

		// Send UDP
		.SEND_REQUEST		( SEND_REQUEST		),
		.SEND_LENGTH		( SEND_LENGTH	   ),
		.SEND_BUSY			( SEND_BUSY			),
		.SEND_DSTPORT		( SEND_DSTPORT	),
		.SEND_SRCPORT		( SEND_SRCPORT		),
		.SEND_DATA_VALID	( SEND_DATA_VALID	),
		.SEND_DATA_READ		( SEND_DATA_READ	),
		.SEND_DATA			( SEND_DATA			),

		// Receive UDP
		.REC_REQUEST		( REC_REQUEST		),
		.REC_LENGTH			( REC_LENGTH		),
		.REC_BUSY			( REC_BUSY			),
		.REC_DSTPORT0		( REC_DSTPORT0	),
		.REC_DSTPORT1		( REC_DSTPORT1	),
		.REC_DSTPORT2		( REC_DSTPORT2	),
		.REC_DSTPORT3		( REC_DSTPORT3	),
		.REC_DATA_VALID		( REC_DATA_VALID	),
		.REC_DATA_READ		( REC_DATA_READ		),
		.REC_DATA			( REC_DATA			)
);

	assign #100		EMAC_RXD	= EMAC_TXD;
	assign #100		EMAC_RX_DV	= EMAC_TX_EN;
	assign #100		EMAC_RX_ER	= EMAC_TX_ER;
	assign #100		EMAC_CRS	= EMAC_TX_EN;
	assign 			EMAC_COL	= 1'b0;
	
	assign EMAC_GTX_CLK = EMAC_RX_CLK;

	initial begin
		RST_N		= 0;
		CLK100M		= 0;
		EMAC_CLK125M		= 0;
		repeat (10) @(negedge CLK100M);
		RST_N		= 1;
	end

	always begin
		#(TIME10N/2) CLK100M <= ~CLK100M;
	end

	always begin
		#(TIME8N/2) EMAC_CLK125M <= ~EMAC_CLK125M;
	end
/*
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
			@(negedge BUFF_CLK);
			TX_BUFF_WE		= 0;
			TX_BUFF_START	= 0;
			TX_BUFF_END		= 0;
			TX_BUFF_DATA	= 32'd0;
			@(negedge BUFF_CLK);
		end
	endtask

	initial begin
		TX_BUFF_WE		= 0;
		TX_BUFF_START	= 0;
		TX_BUFF_END	= 0;
		TX_BUFF_DATA	= 32'd0;

		wait(RST_N);

		repeat (10) @(negedge BUFF_CLK);

		wait(TX_BUFF_READY);

		// ICMP Echo Request
		WRITE(1'b1,1'b0,32'h004A0000);	// 74Byte
		WRITE(1'b0,1'b0,32'h22b10600);
		WRITE(1'b0,1'b0,32'h1300d0c7);
		WRITE(1'b0,1'b0,32'hbcf5cc20);
		WRITE(1'b0,1'b0,32'h00450008);
		WRITE(1'b0,1'b0,32'h3d9e3c00);
		WRITE(1'b0,1'b0,32'h01800000);
		WRITE(1'b0,1'b0,32'ha8c00000);	// IP CheckSum: 0x1929
		WRITE(1'b0,1'b0,32'ha8c00901);
		WRITE(1'b0,1'b0,32'h00080101);
		WRITE(1'b0,1'b0,32'h00020000);	// ICMP CheckSim: 0x3E5C
		WRITE(1'b0,1'b0,32'h6261000d);
		WRITE(1'b0,1'b0,32'h66656463);
		WRITE(1'b0,1'b0,32'h6a696867);
		WRITE(1'b0,1'b0,32'h6e6d6c6b);
		WRITE(1'b0,1'b0,32'h7271706f);
		WRITE(1'b0,1'b0,32'h76757473);
		WRITE(1'b0,1'b0,32'h63626177);
		WRITE(1'b0,1'b0,32'h67666564);
		WRITE(1'b0,1'b1,32'h00006968);

		repeat (10) @(negedge BUFF_CLK);

		wait(TX_BUFF_READY);

		// UDP Packet
		WRITE(1'b1,1'b0,32'h004A0000);	// 78Byte
		WRITE(1'b0,1'b0,32'hFFFFFFFF);
		WRITE(1'b0,1'b0,32'h0013FFFF);
		WRITE(1'b0,1'b0,32'hCCCA6020);
		WRITE(1'b0,1'b0,32'h00450008);
		WRITE(1'b0,1'b0,32'hFBD03C00);
		WRITE(1'b0,1'b0,32'h11800000);
		WRITE(1'b0,1'b0,32'hA8C00000);	// IP CheckSum: 0x4745
		WRITE(1'b0,1'b0,32'hFFFFC801);
		WRITE(1'b0,1'b0,32'h0A04FFFF);
		WRITE(1'b0,1'b0,32'h28009859);
		WRITE(1'b0,1'b0,32'h00200000);	// UDP CheckSum: 0xAACB
		WRITE(1'b0,1'b0,32'h00080000);
		WRITE(1'b0,1'b0,32'h80200001);
		WRITE(1'b0,1'b0,32'h00000000);
		WRITE(1'b0,1'b0,32'h13000000);
		WRITE(1'b0,1'b0,32'hCCCA6020);
		WRITE(1'b0,1'b0,32'hFFFFFFFF);
		WRITE(1'b0,1'b0,32'h0000FFFF);
		WRITE(1'b0,1'b1,32'h00000000);

		repeat (10) @(negedge BUFF_CLK);

		wait(TX_BUFF_READY);

		// TCP Packet
		WRITE(1'b1,1'b0,32'h004A0000);	// 78Byte
		WRITE(1'b0,1'b0,32'hFFFFFFFF);
		WRITE(1'b0,1'b0,32'h0201FFFF);
		WRITE(1'b0,1'b0,32'h06050403);
		WRITE(1'b0,1'b0,32'h00450008);
		WRITE(1'b0,1'b0,32'h12343C00);
		WRITE(1'b0,1'b0,32'h06FF0000);
		WRITE(1'b0,1'b0,32'h02010000);	// IP CheckSum: 0xC291
		WRITE(1'b0,1'b0,32'h12110403);
		WRITE(1'b0,1'b0,32'h21201413);
		WRITE(1'b0,1'b0,32'h31302322);
		WRITE(1'b0,1'b0,32'h41403332);
		WRITE(1'b0,1'b0,32'h04504342);
		WRITE(1'b0,1'b0,32'h00000000);	// TCP CheckSum: 0x0F10
		WRITE(1'b0,1'b0,32'h00000000);
		WRITE(1'b0,1'b0,32'h00000000);
		WRITE(1'b0,1'b0,32'h00000000);
		WRITE(1'b0,1'b0,32'h00000000);
		WRITE(1'b0,1'b0,32'h00000000);
		WRITE(1'b0,1'b1,32'h00000000);

		repeat (10) @(negedge BUFF_CLK);

		wait(TX_BUFF_READY);

		// Dummy Frame
		WRITE(1'b1,1'b0,32'h00400000);	// 64Byte
		WRITE(1'b0,1'b0,32'h04030201);
		WRITE(1'b0,1'b0,32'h12110605);
		WRITE(1'b0,1'b0,32'h16151413);
		WRITE(1'b0,1'b0,32'ha5a50000);
		WRITE(1'b0,1'b0,32'h03020100);
		WRITE(1'b0,1'b0,32'h07060504);
		WRITE(1'b0,1'b0,32'h0B0A0908);
		WRITE(1'b0,1'b0,32'h0F0E0D0C);
		WRITE(1'b0,1'b0,32'h13121110);
		WRITE(1'b0,1'b0,32'h17161514);
		WRITE(1'b0,1'b0,32'h1B1A1918);
		WRITE(1'b0,1'b0,32'h1F1E1D1C);
		WRITE(1'b0,1'b0,32'h23222120);
		WRITE(1'b0,1'b0,32'h27262524);
		WRITE(1'b0,1'b0,32'h2B2A2928);
		WRITE(1'b0,1'b1,32'h2F2E2D2C);

		repeat (10) @(negedge BUFF_CLK);

		wait(TX_BUFF_READY);

		// Dummy Frame
		WRITE(1'b1,1'b0,32'h00410000);	// 65Byte
		WRITE(1'b0,1'b0,32'h04030201);
		WRITE(1'b0,1'b0,32'h12110605);
		WRITE(1'b0,1'b0,32'h16151413);
		WRITE(1'b0,1'b0,32'ha5a50000);
		WRITE(1'b0,1'b0,32'h03020100);
		WRITE(1'b0,1'b0,32'h07060504);
		WRITE(1'b0,1'b0,32'h0B0A0908);
		WRITE(1'b0,1'b0,32'h0F0E0D0C);
		WRITE(1'b0,1'b0,32'h13121110);
		WRITE(1'b0,1'b0,32'h17161514);
		WRITE(1'b0,1'b0,32'h1B1A1918);
		WRITE(1'b0,1'b0,32'h1F1E1D1C);
		WRITE(1'b0,1'b0,32'h23222120);
		WRITE(1'b0,1'b0,32'h27262524);
		WRITE(1'b0,1'b0,32'h2B2A2928);
		WRITE(1'b0,1'b0,32'h2F2E2D2C);
		WRITE(1'b0,1'b1,32'h33323130);

		repeat (10) @(negedge BUFF_CLK);

		wait(TX_BUFF_READY);

		// Dummy Frame
		WRITE(1'b1,1'b0,32'h00420000);	// 66Byte
		WRITE(1'b0,1'b0,32'h04030201);
		WRITE(1'b0,1'b0,32'h12110605);
		WRITE(1'b0,1'b0,32'h16151413);
		WRITE(1'b0,1'b0,32'ha5a50000);
		WRITE(1'b0,1'b0,32'h03020100);
		WRITE(1'b0,1'b0,32'h07060504);
		WRITE(1'b0,1'b0,32'h0B0A0908);
		WRITE(1'b0,1'b0,32'h0F0E0D0C);
		WRITE(1'b0,1'b0,32'h13121110);
		WRITE(1'b0,1'b0,32'h17161514);
		WRITE(1'b0,1'b0,32'h1B1A1918);
		WRITE(1'b0,1'b0,32'h1F1E1D1C);
		WRITE(1'b0,1'b0,32'h23222120);
		WRITE(1'b0,1'b0,32'h27262524);
		WRITE(1'b0,1'b0,32'h2B2A2928);
		WRITE(1'b0,1'b0,32'h2F2E2D2C);
		WRITE(1'b0,1'b1,32'h33323130);

		repeat (10) @(negedge BUFF_CLK);

		wait(TX_BUFF_READY);

		// Dummy Frame
		WRITE(1'b1,1'b0,32'h00430000);	// 67Byte
		WRITE(1'b0,1'b0,32'h04030201);
		WRITE(1'b0,1'b0,32'h12110605);
		WRITE(1'b0,1'b0,32'h16151413);
		WRITE(1'b0,1'b0,32'ha5a50000);
		WRITE(1'b0,1'b0,32'h03020100);
		WRITE(1'b0,1'b0,32'h07060504);
		WRITE(1'b0,1'b0,32'h0B0A0908);
		WRITE(1'b0,1'b0,32'h0F0E0D0C);
		WRITE(1'b0,1'b0,32'h13121110);
		WRITE(1'b0,1'b0,32'h17161514);
		WRITE(1'b0,1'b0,32'h1B1A1918);
		WRITE(1'b0,1'b0,32'h1F1E1D1C);
		WRITE(1'b0,1'b0,32'h23222120);
		WRITE(1'b0,1'b0,32'h27262524);
		WRITE(1'b0,1'b0,32'h2B2A2928);
		WRITE(1'b0,1'b0,32'h2F2E2D2C);
		WRITE(1'b0,1'b1,32'h33323130);

		repeat (10) @(negedge BUFF_CLK);
*/
/*
		PAUSE_QUANTA_DATA	= 16'h0800;
		PAUSE_SEND_ENABLE	= 1;
		TX_PAUSE_ENABLE		= 1;

		repeat (1000) @(negedge BUFF_CLK);

		PAUSE_QUANTA_DATA   = 16'h0800;
		PAUSE_SEND_ENABLE   = 0;
		TX_PAUSE_ENABLE	 = 0;
*/
/*
		repeat (1000) @(negedge BUFF_CLK);

		$finish();

	end

	initial begin
		MAC_ADDRESS			= 48'hBC9A78563412;
		GIG_MODE			= 1;
		FULL_DUPLEX			= 1;
		PAUSE_QUANTA_DATA	= 16'h0000;
		PAUSE_SEND_ENABLE	= 0;
		TX_PAUSE_ENABLE		= 0;
		MAX_RETRY			= 4'd8;
		RX_BUFF_RE			= 0;
		RANDOM_TIME_MEET	= 1;
	end

	initial begin
		wait(RX_BUFF_VALID);
		@(negedge BUFF_CLK);

		// Read ICMP
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 0;		@(negedge BUFF_CLK);

		wait(RX_BUFF_VALID);
		@(negedge BUFF_CLK);

		// Read UDP
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 0;		@(negedge BUFF_CLK);

		wait(RX_BUFF_VALID);
		@(negedge BUFF_CLK);

		// Read TCP
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 0;		@(negedge BUFF_CLK);

		wait(RX_BUFF_VALID);
		@(negedge BUFF_CLK);

		// Read Dummy(64Byte)
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 0;		@(negedge BUFF_CLK);

		wait(RX_BUFF_VALID);
		@(negedge BUFF_CLK);

		// Read Dummy(65Byte)
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 0;		@(negedge BUFF_CLK);

		wait(RX_BUFF_VALID);
		@(negedge BUFF_CLK);

		// Read Dummy(66Byte)
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 0;		@(negedge BUFF_CLK);

		wait(RX_BUFF_VALID);
		@(negedge BUFF_CLK);

		// Read Dummy(67Byte)
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 1;		@(negedge BUFF_CLK);
		RX_BUFF_RE = 0;		@(negedge BUFF_CLK);

		repeat (100) @(negedge BUFF_CLK);

		//$finish();
	end
*/
endmodule
