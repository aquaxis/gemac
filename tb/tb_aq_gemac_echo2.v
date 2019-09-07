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

module tb_aq_gemac_echo2;

	parameter	TIME10N	= 10000;
	parameter	TIME8N	=  8000;

	reg			RST_N;
	reg			SYS_CLK;

	reg			MAC_CLK;

	reg			MIIM_CLK;

	wire [3:0]	TXD;
	wire		TX_EN;
	wire		TX_ER;
	wire		CRS;
	wire		COL;
	wire [3:0]	RXD;
	wire		RX_DV;
	wire		RX_ER;


   wire         RESET;

   assign RESET = ~RST_N;

   wire         CLK125M_P, CLK125M_N;

   assign CLK125M_P = MAC_CLK;
   assign CLK125M_N = ~MAC_CLK;

   wire         TX_CLK;

   wire [7:0]   LED;

   aq_gemac_echo2
	 u_aq_gemac_echo2
       (
		.RESET				( RESET				),

        .CLK125M_P(CLK125M_P),
        .CLK125M_N(CLK125M_N),

		.EMAC_TX_CLK		( TX_CLK			),
		.EMAC_TXD_O			( TXD				),
		.EMAC_TX_EN			( TX_EN				),
		.EMAC_TX_ER			( TX_ER				),

		.EMAC_RX_CLK		( TX_CLK			),
		.EMAC_RXD_I			( RXD				),
		.EMAC_RX_DV			( RX_DV				),
		.EMAC_RX_ER			( RX_ER				),

		.LED			( LED			),

        .SW_IP_ADDR(1'b1)
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


	initial begin
		$display("========================================");
		$display(" Simulation for GEMAC");
		$display("========================================");
		$display(" - System Reqest");

		wait(RST_N);

		repeat (10) @(negedge SYS_CLK);


		repeat (1000) @(negedge SYS_CLK);

		$display("========================================");
		$display(" Finished Simulation(%d)", $time/1000);
		$display("========================================");

		$finish();
	end

endmodule
