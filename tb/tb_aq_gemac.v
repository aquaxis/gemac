/*
* PROJECT: AQUAXIS Giga Ethernet MAC
* ----------------------------------------------------------------------
*
* aq_gemac.v
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
* 2007/01/01 H.Ishihara	1st release
* 2007/08/22 H.Ishihara	remove pause test
* 2011/04/24 H.Ishihara	rename
*/
`timescale 1ps / 1ps

module tb_aq_gemac;

	parameter	TIME10N	= 10000;
	parameter	TIME8N	=  8000;

	reg			RST_N;

	reg			BUFF_CLK;
	reg			TX_BUFF_WE, TX_BUFF_START, TX_BUFF_END;
	wire		TX_BUFF_READY;
	reg	[31:0]	TX_BUFF_DATA;
	wire		TX_BUFF_FULL;

	reg				RX_BUFF_RE;
	wire			RX_BUFF_EMPTY;
	wire [31:0]		RX_BUFF_DATA;
	wire			RX_BUFF_VALID;
	wire [15:0]			RX_BUFF_LENGTH;
	wire [15:0]			RX_BUFF_STATUS;

	reg			MAC_CLK;

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

	reg [47:0]	MAC_ADDRESS;
	reg			RANDOM_TIME_MEET;
	reg [3:0]	MAX_RETRY;
	reg			GIG_MODE;
	reg			FULL_DUPLEX;

	aq_gemac u_aq_gemac(
		// System Reset
		.RST_N					( RST_N		),

		// GMII,MII Interface
		.TX_CLK				( MAC_CLK	),
		.TXD					( TXD		),
		.TX_EN				( TX_EN		),
		.TX_ER				( TX_ER		),
		.RX_CLK				( MAC_CLK	),
		.RXD					( RXD		),
		.RX_DV				( RX_DV		),
		.RX_ER				( RX_ER		),
		.COL					( COL		),
		.CRS					( CRS		),

		// System Clock
		.CLK					( BUFF_CLK		),

		// RX Buffer Interface
		.RX_BUFF_RE			( RX_BUFF_RE	),
		.RX_BUFF_DATA		( RX_BUFF_DATA	),
		.RX_BUFF_EMPTY		( RX_BUFF_EMPTY	),
		.RX_BUFF_VALID		( RX_BUFF_VALID	),
		.RX_BUFF_LENGTH		( RX_BUFF_LENGTH	),
		.RX_BUFF_STATUS		( RX_BUFF_STATUS	),

		// TX Buffer Interface
		.TX_BUFF_WE			( TX_BUFF_WE	),
		.TX_BUFF_START		( TX_BUFF_START	),
		.TX_BUFF_END			( TX_BUFF_END	),
		.TX_BUFF_READY		( TX_BUFF_READY	),
		.TX_BUFF_DATA		( TX_BUFF_DATA	),
		.TX_BUFF_FULL		( TX_BUFF_FULL	),

		// From CPU
		.PAUSE_QUANTA_DATA	( PAUSE_QUANTA_DATA	),
		.PAUSE_SEND_ENABLE	( PAUSE_SEND_ENABLE	),
		.TX_PAUSE_ENABLE		( TX_PAUSE_ENABLE	),

		// Setting
		.RANDOM_TIME_MEET	( 1'b1				),
		.MAC_ADDRESS			( MAC_ADDRESS	),
		.MAX_RETRY			( MAX_RETRY		),
		.GIG_MODE			( GIG_MODE		),
		.FULL_DUPLEX			( FULL_DUPLEX	)
	);


	assign #100		RXD		= TXD;
	assign #100		RX_DV	= TX_EN;
	assign #100		RX_ER	= TX_ER;
	assign #100		CRS		= TX_EN;
	assign 			COL		= 1'b0;

	initial begin
		RST_N			= 0;
		BUFF_CLK	= 0;
		MAC_CLK		= 0;
		repeat (10) @(negedge BUFF_CLK);
		RST_N			= 1;
	end

	always begin
	    #(TIME10N/2) BUFF_CLK <= ~BUFF_CLK;
	end

	always begin
	    #(TIME8N/2) MAC_CLK <= ~MAC_CLK;
	end

	task WRITE;
		input			Start;
		input			End;
		input [31:0]	Data;
		begin
			wait(!TX_BUFF_FULL);

			TX_BUFF_WE		= 1;
			TX_BUFF_START	= Start;
			TX_BUFF_END	= End;
			TX_BUFF_DATA	= Data;
			@(negedge BUFF_CLK);
			TX_BUFF_WE		= 0;
			TX_BUFF_START	= 0;
			TX_BUFF_END	= 0;
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
/*
		PAUSE_QUANTA_DATA	= 16'h0800;
		PAUSE_SEND_ENABLE	= 1;
		TX_PAUSE_ENABLE		= 1;

		repeat (1000) @(negedge BUFF_CLK);

        PAUSE_QUANTA_DATA   = 16'h0800;
        PAUSE_SEND_ENABLE   = 0;
        TX_PAUSE_ENABLE     = 0;
*/
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


endmodule
