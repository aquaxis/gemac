/*
* PROJECT: AQUAXIS Giga Ethernet MAC
* ----------------------------------------------------------------------
*
* aq_gemac_gmii_buff.v
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
* 2011/04/24 rename
*/
//`define XILINX

module aq_gemac_gmii_buff(
	input			rst_b,

	input			tx_clk,
	input [7:0]		bgmii_txd,
	input			bgmii_txe,
	input			bgmii_txer,
	output [7:0]	bgmii_rxd,
	output 			bgmii_rxe,
	output			bgmii_rxer,
	output			bgmii_cos,
	output			bgmii_crs,

	input			rx_clk,
	output [7:0]	gmii_txd,
	output			gmii_txe,
	output			gmii_txer,
	input [7:0]		gmii_rxd,
	input			gmii_rxe,
	input			gmii_rxer,
	input			gmii_col,
	input			gmii_crs,
	output			gmii_gtk_clk
);
	parameter GTK_DELAY = 25; // 2.000ns
	parameter TX_DELAY  = 0;
//	parameter RX_DELAY  = 39; // RX_CLK Delay = 3.106ns
	parameter RX_DELAY  = 52; // RX_CLK Delay = 3.323ns(52 x 78 = 4.056ns)

`ifdef XILINX
	// Tx
	// TxはGMII(1Gbps)の場合、GTK_CLKに同期してTXDを出力し、MII(10/100Mbps)の
	// 場合、TX_CKに同期してTXDを出力します。
	// GTK_CLKはFPGAからの出力に対して、TX_CKはFPGAの入力です。
	// この回路の入力になっているtx_clkはこの回路の上位層で下記のように
	// クロックセレクトしてください。
	// assign tx_clk = (GMII_MODE)?CLK125MHz:TX_CK;
	// なお、MII(10/100Mbps)でデータが正常に送信できない場合、上記セレクタの
	// TX_CKを遅延させてください。
	FDC u_txe( .C(tx_clk), .D(bgmii_txe   ), .Q(gmii_txe   ), .CLR(~rst_b));
	FDC u_txer(.C(tx_clk), .D(bgmii_txer  ), .Q(gmii_txer  ), .CLR(~rst_b));

	FDC u_txd0(.C(tx_clk), .D(bgmii_txd[0]), .Q(gmii_txd[0]), .CLR(~rst_b));
	FDC u_txd1(.C(tx_clk), .D(bgmii_txd[1]), .Q(gmii_txd[1]), .CLR(~rst_b));
	FDC u_txd2(.C(tx_clk), .D(bgmii_txd[2]), .Q(gmii_txd[2]), .CLR(~rst_b));
	FDC u_txd3(.C(tx_clk), .D(bgmii_txd[3]), .Q(gmii_txd[3]), .CLR(~rst_b));
	FDC u_txd4(.C(tx_clk), .D(bgmii_txd[4]), .Q(gmii_txd[4]), .CLR(~rst_b));
	FDC u_txd5(.C(tx_clk), .D(bgmii_txd[5]), .Q(gmii_txd[5]), .CLR(~rst_b));
	FDC u_txd6(.C(tx_clk), .D(bgmii_txd[6]), .Q(gmii_txd[6]), .CLR(~rst_b));
	FDC u_txd7(.C(tx_clk), .D(bgmii_txd[7]), .Q(gmii_txd[7]), .CLR(~rst_b));

	// GTK_CLK
	// GTK_CLKはTXDの立ち上がりに対して、2ns遅延させて出力します。
	// PHYによっては、遅延量は2nsではなく、2.5nsの場合があります。
	// その場合、GTK_DELAYを調整することにより対処してください。
	// 遅延値はの値は78ps x GTL_DELAYで決定してください。
	wire	tx_clk_oddr;
	ODDR u_tx_gtk_clk_oddr (
		.D1 ( 1'b1		  ),
		.D2 ( 1'b0		  ),
		.R  ( ~rst_b		),
		.S  ( 1'b0		  ),
		.C  ( tx_clk		),
		.CE ( 1'b1		  ),
		.Q  ( tx_clk_oddr   )
	);

	IODELAY #(
		.DELAY_SRC			  ( "O"	   ),
		.HIGH_PERFORMANCE_MODE  ( "TRUE"	),
		.IDELAY_TYPE			( "FIXED"   ),
		.IDELAY_VALUE		   ( 0		 ),
		.ODELAY_VALUE		   ( GTK_DELAY ),
		.REFCLK_FREQUENCY	   ( 200.0	 ),
		.SIGNAL_PATTERN		 ( "DATA"	)
	) u_IODELAY_txd0(
		.C	  ( 1'b0		  ),
		.CE	 ( 1'b0		  ),
		.INC	( 1'b0		  ),
		.DATAIN ( 1'b0		  ),
		.DATAOUT( gmii_gtk_clk  ),
		.IDATAIN( 1'b0		  ),
		.ODATAIN( tx_clk_oddr   ),
		.RST	( ~rst_b		),
		.T	  ( 1'b1		  )
	);

	// Rx
	// Rxの信号はRX_CKの入力パッドから、RXDの最初のFFまでの遅延量をFPGA Editorで算出し、
	// その遅延量分、RXDの入力パッドからRXDの最初のFFの入力を遅延させてください。
	// RX_CKの入力パッドの位置によって異なりますがたいてい、2〜3nsぐらいは
	// 遅延させなければいけません。
	wire		gmii_rxe_id, gmii_er_id;
	wire [7:0]  gmii_rxd_id;

	IODELAY #(
		.DELAY_SRC			  ( "I"	   ),
		.HIGH_PERFORMANCE_MODE  ( "TRUE"	),
		.IDELAY_TYPE			( "FIXED"   ),
		.IDELAY_VALUE		   ( RX_DELAY  ),
		.ODELAY_VALUE		   ( 0		 ),
		.REFCLK_FREQUENCY	   ( 200.0	 ),
		.SIGNAL_PATTERN		 ( "DATA"	)
	) u_IODELAY_rxe(
		.C	  ( 1'b0		  ),
		.CE	 ( 1'b0		  ),
		.INC	( 1'b0		  ),
		.DATAIN ( 1'b0		  ),
		.DATAOUT( gmii_rxe_id   ),
		.IDATAIN( gmii_rxe	  ),
		.ODATAIN( 1'b0		  ),
		.RST	( ~rst_b		),
		.T	  ( 1'b0		  )
	);

	IODELAY #(
		.DELAY_SRC			  ( "I"	   ),
		.HIGH_PERFORMANCE_MODE  ( "TRUE"	),
		.IDELAY_TYPE			( "FIXED"   ),
		.IDELAY_VALUE		   ( RX_DELAY  ),
		.ODELAY_VALUE		   ( 0		 ),
		.REFCLK_FREQUENCY	   ( 200.0	 ),
		.SIGNAL_PATTERN		 ( "DATA"	)
	) u_IODELAY_rxer(
		.C	  ( 1'b0		  ),
		.CE	 ( 1'b0		  ),
		.INC	( 1'b0		  ),
		.DATAIN ( 1'b0		  ),
		.DATAOUT( gmii_rxer_id  ),
		.IDATAIN( gmii_rxer	 ),
		.ODATAIN( 1'b0		  ),
		.RST	( ~rst_b		),
		.T	  ( 1'b0		  )
	);

	IODELAY #(
		.DELAY_SRC			  ( "I"	   ),
		.HIGH_PERFORMANCE_MODE  ( "TRUE"	),
		.IDELAY_TYPE			( "FIXED"   ),
		.IDELAY_VALUE		   ( RX_DELAY  ),
		.ODELAY_VALUE		   ( 0		 ),
		.REFCLK_FREQUENCY	   ( 200.0	 ),
		.SIGNAL_PATTERN		 ( "DATA"	)
	) u_IODELAY_rxd0(
		.C	  ( 1'b0			  ),
		.CE	 ( 1'b0			  ),
		.INC	( 1'b0			  ),
		.DATAIN ( 1'b0			  ),
		.DATAOUT( gmii_rxd_id[0]	),
		.IDATAIN( gmii_rxd[0]	   ),
		.ODATAIN( 1'b0			  ),
		.RST	( ~rst_b			),
		.T	  ( 1'b0			  )
	);

	IODELAY #(
		.DELAY_SRC			  ( "I"	   ),
		.HIGH_PERFORMANCE_MODE  ( "TRUE"	),
		.IDELAY_TYPE			( "FIXED"   ),
		.IDELAY_VALUE		   ( RX_DELAY  ),
		.ODELAY_VALUE		   ( 0		 ),
		.REFCLK_FREQUENCY	   ( 200.0	 ),
		.SIGNAL_PATTERN		 ( "DATA"	)
	) u_IODELAY_rxd1(
		.C	  ( 1'b0			  ),
		.CE	 ( 1'b0			  ),
		.INC	( 1'b0			  ),
		.DATAIN ( 1'b0			  ),
		.DATAOUT( gmii_rxd_id[1]	),
		.IDATAIN( gmii_rxd[1]	   ),
		.ODATAIN( 1'b0			  ),
		.RST	( ~rst_b			),
		.T	  ( 1'b0			  )
	);

	IODELAY #(
		.DELAY_SRC			  ( "I"	   ),
		.HIGH_PERFORMANCE_MODE  ( "TRUE"	),
		.IDELAY_TYPE			( "FIXED"   ),
		.IDELAY_VALUE		   ( RX_DELAY  ),
		.ODELAY_VALUE		   ( 0		 ),
		.REFCLK_FREQUENCY	   ( 200.0	 ),
		.SIGNAL_PATTERN		 ( "DATA"	)
	) u_IODELAY_rxd2(
		.C	  ( 1'b0			  ),
		.CE	 ( 1'b0			  ),
		.INC	( 1'b0			  ),
		.DATAIN ( 1'b0			  ),
		.DATAOUT( gmii_rxd_id[2]	),
		.IDATAIN( gmii_rxd[2]	   ),
		.ODATAIN( 1'b0			  ),
		.RST	( ~rst_b			),
		.T	  ( 1'b0			  )
	);

	IODELAY #(
		.DELAY_SRC			  ( "I"	   ),
		.HIGH_PERFORMANCE_MODE  ( "TRUE"	),
		.IDELAY_TYPE			( "FIXED"   ),
		.IDELAY_VALUE		   ( RX_DELAY  ),
		.ODELAY_VALUE		   ( 0		 ),
		.REFCLK_FREQUENCY	   ( 200.0	 ),
		.SIGNAL_PATTERN		 ( "DATA"	)
	) u_IODELAY_rxd3(
		.C	  ( 1'b0			  ),
		.CE	 ( 1'b0			  ),
		.INC	( 1'b0			  ),
		.DATAIN ( 1'b0			  ),
		.DATAOUT( gmii_rxd_id[3]	),
		.IDATAIN( gmii_rxd[3]	   ),
		.ODATAIN( 1'b0			  ),
		.RST	( ~rst_b			),
		.T	  ( 1'b0			  )
	);

	IODELAY #(
		.DELAY_SRC			  ( "I"	   ),
		.HIGH_PERFORMANCE_MODE  ( "TRUE"	),
		.IDELAY_TYPE			( "FIXED"   ),
		.IDELAY_VALUE		   ( RX_DELAY  ),
		.ODELAY_VALUE		   ( 0		 ),
		.REFCLK_FREQUENCY	   ( 200.0	 ),
		.SIGNAL_PATTERN		 ( "DATA"	)
	) u_IODELAY_rxd4(
		.C	  ( 1'b0			  ),
		.CE	 ( 1'b0			  ),
		.INC	( 1'b0			  ),
		.DATAIN ( 1'b0			  ),
		.DATAOUT( gmii_rxd_id[4]	),
		.IDATAIN( gmii_rxd[4]	   ),
		.ODATAIN( 1'b0			  ),
		.RST	( ~rst_b			),
		.T	  ( 1'b0			  )
	);

	IODELAY #(
		.DELAY_SRC			  ( "I"	   ),
		.HIGH_PERFORMANCE_MODE  ( "TRUE"	),
		.IDELAY_TYPE			( "FIXED"   ),
		.IDELAY_VALUE		   ( RX_DELAY  ),
		.ODELAY_VALUE		   ( 0		 ),
		.REFCLK_FREQUENCY	   ( 200.0	 ),
		.SIGNAL_PATTERN		 ( "DATA"	)
	) u_IODELAY_rxd5(
		.C	  ( 1'b0			  ),
		.CE	 ( 1'b0			  ),
		.INC	( 1'b0			  ),
		.DATAIN ( 1'b0			  ),
		.DATAOUT( gmii_rxd_id[5]	),
		.IDATAIN( gmii_rxd[5]	   ),
		.ODATAIN( 1'b0			  ),
		.RST	( ~rst_b			),
		.T	  ( 1'b0			  )
	);

	IODELAY #(
		.DELAY_SRC			  ( "I"	   ),
		.HIGH_PERFORMANCE_MODE  ( "TRUE"	),
		.IDELAY_TYPE			( "FIXED"   ),
		.IDELAY_VALUE		   ( RX_DELAY  ),
		.ODELAY_VALUE		   ( 0		 ),
		.REFCLK_FREQUENCY	   ( 200.0	 ),
		.SIGNAL_PATTERN		 ( "DATA"	)
	) u_IODELAY_rxd6(
		.C	  ( 1'b0			  ),
		.CE	 ( 1'b0			  ),
		.INC	( 1'b0			  ),
		.DATAIN ( 1'b0			  ),
		.DATAOUT( gmii_rxd_id[6]	),
		.IDATAIN( gmii_rxd[6]	   ),
		.ODATAIN( 1'b0			  ),
		.RST	( ~rst_b			),
		.T	  ( 1'b0			  )
	);

	IODELAY #(
		.DELAY_SRC			  ( "I"	   ),
		.HIGH_PERFORMANCE_MODE  ( "TRUE"	),
		.IDELAY_TYPE			( "FIXED"   ),
		.IDELAY_VALUE		   ( RX_DELAY  ),
		.ODELAY_VALUE		   ( 0		 ),
		.REFCLK_FREQUENCY	   ( 200.0	 ),
		.SIGNAL_PATTERN		 ( "DATA"	)
	) u_IODELAY_rxd7(
		.C	  ( 1'b0			  ),
		.CE	 ( 1'b0			  ),
		.INC	( 1'b0			  ),
		.DATAIN ( 1'b0			  ),
		.DATAOUT( gmii_rxd_id[7]	),
		.IDATAIN( gmii_rxd[7]	   ),
		.ODATAIN( 1'b0			  ),
		.RST	( ~rst_b			),
		.T	  ( 1'b0			  )
	);

	FDC u_rxe( .C(rx_clk), .D(gmii_rxe_id   ), .Q(bgmii_rxe   ), .CLR(~rst_b));
	FDC u_rxer(.C(rx_clk), .D(gmii_rxer_id  ), .Q(bgmii_rxer  ), .CLR(~rst_b));

	FDC u_rxd0(.C(rx_clk), .D(gmii_rxd_id[0]), .Q(bgmii_rxd[0]), .CLR(~rst_b));
	FDC u_rxd1(.C(rx_clk), .D(gmii_rxd_id[1]), .Q(bgmii_rxd[1]), .CLR(~rst_b));
	FDC u_rxd2(.C(rx_clk), .D(gmii_rxd_id[2]), .Q(bgmii_rxd[2]), .CLR(~rst_b));
	FDC u_rxd3(.C(rx_clk), .D(gmii_rxd_id[3]), .Q(bgmii_rxd[3]), .CLR(~rst_b));
	FDC u_rxd4(.C(rx_clk), .D(gmii_rxd_id[4]), .Q(bgmii_rxd[4]), .CLR(~rst_b));
	FDC u_rxd5(.C(rx_clk), .D(gmii_rxd_id[5]), .Q(bgmii_rxd[5]), .CLR(~rst_b));
	FDC u_rxd6(.C(rx_clk), .D(gmii_rxd_id[6]), .Q(bgmii_rxd[6]), .CLR(~rst_b));
	FDC u_rxd7(.C(rx_clk), .D(gmii_rxd_id[7]), .Q(bgmii_rxd[7]), .CLR(~rst_b));

	wire		gmii_col_id, gmii_crs_id;
	IODELAY #(
		.DELAY_SRC			  ( "I"	   ),
		.HIGH_PERFORMANCE_MODE  ( "TRUE"	),
		.IDELAY_TYPE			( "FIXED"   ),
		.IDELAY_VALUE		   ( TX_DELAY  ),
		.ODELAY_VALUE		   ( 0		 ),
		.REFCLK_FREQUENCY	   ( 200.0	 ),
		.SIGNAL_PATTERN		 ( "DATA"	)
	) u_IODELAY_col(
		.C		( 1'b0		  ),
		.CE		( 1'b0		  ),
		.INC	( 1'b0		  ),
		.DATAIN ( 1'b0		  ),
		.DATAOUT( gmii_col_id   ),
		.IDATAIN( gmii_col	  ),
		.ODATAIN( 1'b0		  ),
		.RST	( ~rst_b		),
		.T		( 1'b0		  )
	);

	IODELAY #(
		.DELAY_SRC			  ( "I"	   ),
		.HIGH_PERFORMANCE_MODE  ( "TRUE"	),
		.IDELAY_TYPE			( "FIXED"   ),
		.IDELAY_VALUE		   ( TX_DELAY  ),
		.ODELAY_VALUE		   ( 0		 ),
		.REFCLK_FREQUENCY	   ( 200.0	 ),
		.SIGNAL_PATTERN		 ( "DATA"	)
	) u_IODELAY_crs(
		.C		( 1'b0		  ),
		.CE		( 1'b0		  ),
		.INC	( 1'b0		  ),
		.DATAIN	( 1'b0		  ),
		.DATAOUT( gmii_crs_id   ),
		.IDATAIN( gmii_crs	  ),
		.ODATAIN( 1'b0		  ),
		.RST	( ~rst_b		),
		.T		( 1'b0		  )
	);

	FDC u_col( .C(tx_clk), .D(gmii_col_id ), .Q(bgmii_col   ), .CLR(~rst_b));
	FDC u_crs( .C(tx_clk), .D(gmii_crs_id ), .Q(bgmii_crs   ), .CLR(~rst_b));

`else
	reg			gmii_txe_b, gmii_txer_b;
	reg [7:0]	gmii_txd_b;
	reg			bgmii_rxe_b, bgmii_rxer_b;
	reg [7:0]	bgmii_rxd_b;
	reg			bgmii_col_b, bgmii_crs_b;

	// TX Data
	always @(negedge tx_clk or negedge rst_b) begin
		if(!rst_b) begin
			gmii_txe_b	<= 1'b0;
			gmii_txer_b	<= 1'b0;
			gmii_txd_b	<= 8'd0;
			bgmii_col_b	<= 1'b0;
			bgmii_crs_b	<= 1'b0;
		end else begin
			gmii_txe_b	<= bgmii_txe;
			gmii_txer_b	<= bgmii_txer;
			gmii_txd_b	<= bgmii_txd;
			bgmii_col_b	<= gmii_col;
			bgmii_crs_b	<= gmii_crs;
		end
	end
	assign gmii_gtk_clk = tx_clk;
	assign gmii_txe		= gmii_txe_b;
	assign gmii_txer	= gmii_txer_b;
	assign gmii_txd		= gmii_txd_b;
	assign bgmii_col	= bgmii_col_b;
	assign bgmii_crs	= bgmii_crs_b;

	// Rx
	always @(negedge rx_clk or negedge rst_b) begin
		if(!rst_b) begin
			bgmii_rxe_b		<= 1'b0;
			bgmii_rxer_b	<= 1'b0;
			bgmii_rxd_b		<= 8'd0;
		end else begin
			bgmii_rxe_b		<= gmii_rxe;
			bgmii_rxer_b	<= gmii_rxer;
			bgmii_rxd_b		<= gmii_rxd;
		end
	end
	assign bgmii_rxe	= bgmii_rxe_b;
	assign bgmii_rxer	= bgmii_rxer_b;
	assign bgmii_rxd	= bgmii_rxd_b;
`endif
endmodule
