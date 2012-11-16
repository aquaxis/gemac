/*
* PROJECT: AQUAXIS Giga Ethernet MAC
* ----------------------------------------------------------------------
*
* tb_aq_gemac_l3.v
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
* 2007/01/01 1st release
* 2011/04/24 rename
*/
`timescale 1ps / 1ps

module tb_aq_gemac_l3;

	parameter	TIME10N	= 10000;
	parameter	TIME8N	=  8000;

	reg			RST;

	reg			BUFF_CLK;
	wire			TX_BUFF_WE, TX_BUFF_START, TX_BUFF_END;
	wire		TX_BUFF_READY;
	wire	[31:0]	TX_BUFF_DATA;
	wire		TX_BUFF_FULL;

	wire				RX_BUFF_RE;
	wire			RX_BUFF_EMPTY;
	wire [31:0]		RX_BUFF_DATA;
	wire			RX_BUFF_VALID;
	wire [15:0]			RX_BUFF_LENGTH;
	wire [15:0]			RX_BUFF_STATUS;

	reg			ETX_BUFF_WE, ETX_BUFF_START, ETX_BUFF_END;
	wire		ETX_BUFF_READY;
	reg	[31:0]	ETX_BUFF_DATA;
	wire		ETX_BUFF_FULL;

	reg				ERX_BUFF_RE;
	wire			ERX_BUFF_EMPTY;
	wire [31:0]		ERX_BUFF_DATA;
	wire			ERX_BUFF_VALID;
	wire [15:0]			ERX_BUFF_LENGTH;
	wire [15:0]			ERX_BUFF_STATUS;

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
	reg [31:0]	IP_ADDRESS;
	reg			RANDOM_TIME_MEET;
	reg [3:0]	MAX_RETRY;
	reg			GIG_MODE;
	reg			FULL_DUPLEX;

	aq_gemac u_aq_gemac(
		// System Reset
		.RST					( RST		),

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
		.MAC_ADDRESS		( MAC_ADDRESS	),
		.MAX_RETRY			( MAX_RETRY		),
		.GIG_MODE			( GIG_MODE		),
		.FULL_DUPLEX		( FULL_DUPLEX	)
	);

	aq_gemac_l3_ctrl u_aq_gemac_l3_ctrl(
		.RST				( RST		),
		.CLK				( BUFF_CLK	),

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
		.TX_BUFF_END		( TX_BUFF_END	),
		.TX_BUFF_READY		( TX_BUFF_READY	),
		.TX_BUFF_DATA		( TX_BUFF_DATA	),
		.TX_BUFF_FULL		( TX_BUFF_FULL	),

		// External RX Buffer Interface
		.ERX_BUFF_RE		( ERX_BUFF_RE		),
		.ERX_BUFF_DATA	( ERX_BUFF_DATA		),
		.ERX_BUFF_EMPTY	( ERX_BUFF_EMPTY	),
		.ERX_BUFF_VALID	( ERX_BUFF_VALID	),
		.ERX_BUFF_LENGTH	( ERX_BUFF_LENGTH	),
		.ERX_BUFF_STATUS	( ERX_BUFF_STATUS	),

		// External TX Buffer Interface
		.ETX_BUFF_WE		( ETX_BUFF_WE		),
		.ETX_BUFF_START	( ETX_BUFF_START	),
		.ETX_BUFF_END	( ETX_BUFF_END		),
		.ETX_BUFF_READY	( ETX_BUFF_READY	),
		.ETX_BUFF_DATA	( ETX_BUFF_DATA		),
		.ETX_BUFF_FULL	( ETX_BUFF_FULL		),

		.MAC_ADDRESS		( MAC_ADDRESS		),
		.IP_ADDRESS		( IP_ADDRESS		)
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

			ETX_BUFF_WE		= 1;
			ETX_BUFF_START	= Start;
			ETX_BUFF_END	= End;
			ETX_BUFF_DATA	= Data;
			@(negedge BUFF_CLK);
			ETX_BUFF_WE		= 0;
			ETX_BUFF_START	= 0;
			ETX_BUFF_END	= 0;
			ETX_BUFF_DATA	= 32'd0;
			@(negedge BUFF_CLK);
		end
	endtask

	initial begin
		ETX_BUFF_WE		= 0;
		ETX_BUFF_START	= 0;
		ETX_BUFF_END	= 0;
		ETX_BUFF_DATA	= 32'd0;

		wait(RST);

		repeat (10) @(negedge BUFF_CLK);

		wait(ETX_BUFF_READY);

		// ARP Request
		WRITE(1'b1,1'b0,32'h002A0000);	// 42Byte
		WRITE(1'b0,1'b0,32'hFFFFFFFF);
		WRITE(1'b0,1'b0,32'h1110FFFF);
		WRITE(1'b0,1'b0,32'h15141312);
		WRITE(1'b0,1'b0,32'h01000608);
		WRITE(1'b0,1'b0,32'h04060008);
		WRITE(1'b0,1'b0,32'h11000100);
		WRITE(1'b0,1'b0,32'h15141312);
		WRITE(1'b0,1'b0,32'h1001A8C0);
		WRITE(1'b0,1'b0,32'h00000000);
		WRITE(1'b0,1'b0,32'hA8C00000);
		WRITE(1'b0,1'b1,32'h00000101);

		wait(ETX_BUFF_READY);

		@(negedge BUFF_CLK);

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

		wait(ETX_BUFF_READY);

		@(negedge BUFF_CLK);

		// ARP Request
		WRITE(1'b1,1'b0,32'h002A0000);	// 42Byte
		WRITE(1'b0,1'b0,32'hFFFFFFFF);
		WRITE(1'b0,1'b0,32'h1110FFFF);
		WRITE(1'b0,1'b0,32'h15141312);
		WRITE(1'b0,1'b0,32'h01000608);
		WRITE(1'b0,1'b0,32'h04060008);
		WRITE(1'b0,1'b0,32'h11000100);
		WRITE(1'b0,1'b0,32'h15141312);
		WRITE(1'b0,1'b0,32'h1001A8C0);
		WRITE(1'b0,1'b0,32'h00000000);
		WRITE(1'b0,1'b0,32'hA8C00000);
		WRITE(1'b0,1'b1,32'h00000101);

		repeat (500) @(negedge BUFF_CLK);

		wait(ETX_BUFF_READY);

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

		wait(ETX_BUFF_READY);

		@(negedge BUFF_CLK);

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

		repeat (500) @(negedge BUFF_CLK);

		wait(ETX_BUFF_READY);

		@(negedge BUFF_CLK);

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
		WRITE(1'b0,1'b0,32'h62610006);
		WRITE(1'b0,1'b0,32'h66656463);
		WRITE(1'b0,1'b0,32'h6a696867);
		WRITE(1'b0,1'b0,32'h6e6d6c6b);
		WRITE(1'b0,1'b0,32'h7271706f);
		WRITE(1'b0,1'b0,32'h76757473);
		WRITE(1'b0,1'b0,32'h63626177);
		WRITE(1'b0,1'b0,32'h67666564);
		WRITE(1'b0,1'b1,32'h00006968);

		@(negedge BUFF_CLK);

		PAUSE_QUANTA_DATA	= 16'h0800;
		PAUSE_SEND_ENABLE	= 0;
		TX_PAUSE_ENABLE		= 0;

		repeat (100) @(negedge BUFF_CLK);

		$finish();
	end

	initial begin
		MAC_ADDRESS			= 48'h151413121110;
		IP_ADDRESS			= 32'h0101A8C0;
		GIG_MODE			= 1;
		FULL_DUPLEX			= 1;
		PAUSE_QUANTA_DATA	= 16'h0000;
		PAUSE_SEND_ENABLE	= 0;
		TX_PAUSE_ENABLE		= 0;
		MAX_RETRY			= 4'd8;
		ERX_BUFF_RE			= 0;
		RANDOM_TIME_MEET	= 1;
	end

	initial begin
		wait(ERX_BUFF_VALID);
		@(negedge BUFF_CLK);

		repeat (100) @(negedge BUFF_CLK);

		//$finish();
	end

endmodule
