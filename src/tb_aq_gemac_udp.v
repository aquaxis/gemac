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
* 1.02 2007/08/22 remove pause test
* 2011/04/24 rename
*/
`timescale 1ps / 1ps

module tb_aq_gemac_udp;

	parameter	TIME10N	= 10000;
	parameter	TIME8N	=  8000;

	reg			RST;

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

module aq_gemac_udp(
    RST_N,

    CLK100M,

    EMAC_CLK125M, // Clock 125MHz

    EMAC_GTX_CLK, // Tx Clock(Out) for 1000 Mode
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

    EMAC_INT,     // Interrupt
    EMAC_RST,

    MIIM_MDC,     // MIIM Clock
    MIIM_MDIO,    // MIIM I/O

        .UDP_PEER_MAC_ADDRESS   ( peer_mac_address      ),
        .UDP_PEER_IP_ADDRESS    ( DEFAULT_PEER_IP_ADRS       ),
        .UDP_MY_MAC_ADDRESS     ( DEFAULT_MY_MAC_ADRS        ),
        .UDP_MY_IP_ADDRESS      ( DEFAULT_MY_IP_ADRS         ),

        // Send UDP
        .UDP_SEND_REQUEST       ( udp_send_request      ),
        .UDP_SEND_LENGTH        ( {4'd0, udp_send_length}       ),
        .UDP_SEND_BUSY          ( udp_send_busy         ),
        .UDP_SEND_DSTPORT       ( DEFAULT_MY_SEND_PORT  ),
        .UDP_SEND_SRCPORT       ( udp_send_srcport      ),
        .UDP_SEND_DATA_VALID    ( udp_send_data_valid   ),
        .UDP_SEND_DATA_READ     ( udp_send_data_read    ),
        .UDP_SEND_DATA          ( udp_send_data         ),

        // Receive UDP
        .UDP_REC_REQUEST        ( udp_rec_request       ),
        .UDP_REC_LENGTH         ( udp_rec_length        ),
        .UDP_REC_BUSY           ( udp_rec_busy          ),
        .UDP_REC_DSTPORT0       ( DEFAULT_MY_REC0_PORT  ),
        .UDP_REC_DSTPORT1       ( DEFAULT_MY_REC1_PORT  ),
        .UDP_REC_DATA_VALID0    ( udp_rec_data_valid0   ),
        .UDP_REC_DATA_VALID1    ( udp_rec_data_valid1   ),
        .UDP_REC_DATA_READ      ( udp_rec_data_read     ),
        .UDP_REC_DATA           ( udp_rec_data          ),


);


	assign #100		RXD		= TXD;
	assign #100		RX_DV	= TX_EN;
	assign #100		RX_ER	= TX_ER;
	assign #100		CRS		= TX_EN;
	assign 			COL		= 1'b0;

	initial begin
		RST			= 0;
		BUFF_CLK	= 0;
		MAC_CLK		= 0;
		repeat (10) @(negedge BUFF_CLK);
		RST			= 1;
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

		wait(RST);

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
