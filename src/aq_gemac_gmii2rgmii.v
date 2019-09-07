/*
* PROJECT: AQUAXIS Giga Ethernet MAC
* ----------------------------------------------------------------------
*
* aq_gemac_gmii2rgmii.v
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
* 2007/01/06 H.Ishihara	1st release
* 2011/04/24 H.Ishihara	rename
*/
module aq_gemac_gmii2rgmii(
    rst_b,

    tx_clk,
    gmii_txd,
    gmii_txe,
    gmii_txer,
    gmii_rxd,
    gmii_rxe,
    gmii_rxer,

    rx_clk,
    rgmii_txd,
    rgmii_txe,
    rgmii_rxd,
    rgmii_rxe,
    rgmii_tck
);
    input           rst_b;

    input           tx_clk;
    input [7:0]     gmii_txd;
    input           gmii_txe;
    input           gmii_txer;
    output [7:0]    gmii_rxd;
    output          gmii_rxe;
    output          gmii_rxer;

    input           rx_clk;
    output [3:0]    rgmii_txd;
    output          rgmii_txe;
    input [3:0]     rgmii_rxd;
    input           rgmii_rxe;
    output          rgmii_tck;

`ifdef XILINX

    wire [3:0]  d_rgmii_txd;
    wire        d_rgmii_txe;

    ODDR u_txe (
        .D1             ( gmii_txe      ),
        .D2             ( gmii_txe      ),
        .R              ( ~rst_b        ),
        .S              ( 1'b0          ),
        .C              ( tx_clk        ),
        .CE             ( 1'b1          ),
        .Q              ( rgmii_txe   )
    );

    ODDR u_txd3 (
        .D1             ( gmii_txd[7]   ),
        .D2             ( gmii_txd[3]   ),
        .R              ( ~rst_b        ),
        .S              ( 1'b0          ),
        .C              ( tx_clk        ),
        .CE             ( 1'b1          ),
        .Q              ( rgmii_txd[3]  )
    );

    ODDR u_txd2 (
        .D1             ( gmii_txd[6]   ),
        .D2             ( gmii_txd[2]   ),
        .R              ( ~rst_b        ),
        .S              ( 1'b0          ),
        .C              ( tx_clk        ),
        .CE             ( 1'b1          ),
        .Q              ( rgmii_txd[2]  )
    );

    ODDR u_txd1 (
        .D1             ( gmii_txd[5]   ),
        .D2             ( gmii_txd[1]   ),
        .R              ( ~rst_b        ),
        .S              ( 1'b0          ),
        .C              ( tx_clk        ),
        .CE             ( 1'b1          ),
        .Q              ( rgmii_txd[1]  )
    );

    ODDR u_txd0 (
        .D1             ( gmii_txd[4]   ),
        .D2             ( gmii_txd[0]   ),
        .R              ( ~rst_b        ),
        .S              ( 1'b0          ),
        .C              ( tx_clk        ),
        .CE             ( 1'b1          ),
        .Q              ( rgmii_txd[0]  )
    );

    wire tx_clk_oddr;
    ODDR u_ckb (
        .D1             ( 1'b0          ),
        .D2             ( 1'b1          ),
        .R              ( ~RST_B        ),
        .S              ( 1'b0          ),
        .C              ( ge_tx_clk     ),
        .CE             ( 1'b1          ),
        .Q              ( tx_clk_oddr   )
    );

    IODELAY #(
        .DELAY_SRC              ( "O"       ),
        .HIGH_PERFORMANCE_MODE  ( "TRUE"    ),
        .IDELAY_TYPE            ( "FIXED"   ),
        .IDELAY_VALUE           ( 0         ),
        .ODELAY_VALUE           ( 25        ),
        .REFCLK_FREQUENCY       ( 200.0     ),
        .SIGNAL_PATTERN         ( "DATA"    )
    ) u_IODELAY_ckb(
        .C      ( 1'b0          ),
        .CE     ( 1'b0          ),
        .INC    ( 1'b0          ),
        .DATAIN ( 1'b0          ),
        .DATAOUT( rgmii_tck     ),
        .IDATAIN( 1'b0          ),
        .ODATAIN( tx_clk_oddr   ),
        .RST    ( ~RST_B        ),
        .T      ( 1'b1          )
    );
/*
    IODELAY #(
        .DELAY_SRC              ( "O"       ),
        .HIGH_PERFORMANCE_MODE  ( "TRUE"    ),
        .IDELAY_TYPE            ( "FIXED"   ),
        .IDELAY_VALUE           ( 0         ),
        .ODELAY_VALUE           ( 10        ),
        .REFCLK_FREQUENCY       ( 200.0     ),
        .SIGNAL_PATTERN         ( "DATA"    )
    ) u_IODELAY_txd0(
        .C      ( 1'b0          ),
        .CE     ( 1'b0          ),
        .INC    ( 1'b0          ),
        .DATAIN ( 1'b0          ),
        .DATAOUT( rgmii_txd[0]  ),
        .IDATAIN( 1'b0          ),
        .ODATAIN( d_rgmii_txd[0]),
        .RST    ( ~rst_b        ),
        .T      ( 1'b1          )
    );

    IODELAY #(
        .DELAY_SRC              ( "O"       ),
        .HIGH_PERFORMANCE_MODE  ( "TRUE"    ),
        .IDELAY_TYPE            ( "FIXED"   ),
        .IDELAY_VALUE           ( 0         ),
        .ODELAY_VALUE           ( 10        ),
        .REFCLK_FREQUENCY       ( 200.0     ),
        .SIGNAL_PATTERN         ( "DATA"    )
    ) u_IODELAY_txd1(
        .C      ( 1'b0          ),
        .CE     ( 1'b0          ),
        .INC    ( 1'b0          ),
        .DATAIN ( 1'b0          ),
        .DATAOUT( rgmii_txd[1]  ),
        .IDATAIN( 1'b0          ),
        .ODATAIN( d_rgmii_txd[1]),
        .RST    ( ~rst_b        ),
        .T      ( 1'b1          )
    );

    IODELAY #(
        .DELAY_SRC              ( "O"       ),
        .HIGH_PERFORMANCE_MODE  ( "TRUE"    ),
        .IDELAY_TYPE            ( "FIXED"   ),
        .IDELAY_VALUE           ( 0         ),
        .ODELAY_VALUE           ( 10        ),
        .REFCLK_FREQUENCY       ( 200.0     ),
        .SIGNAL_PATTERN         ( "DATA"    )
    ) u_IODELAY_txd2(
        .C      ( 1'b0          ),
        .CE     ( 1'b0          ),
        .INC    ( 1'b0          ),
        .DATAIN ( 1'b0          ),
        .DATAOUT( rgmii_txd[2]  ),
        .IDATAIN( 1'b0          ),
        .ODATAIN( d_rgmii_txd[2]),
        .RST    ( ~rst_b        ),
        .T      ( 1'b1          )
    );

    IODELAY #(
        .DELAY_SRC              ( "O"       ),
        .HIGH_PERFORMANCE_MODE  ( "TRUE"    ),
        .IDELAY_TYPE            ( "FIXED"   ),
        .IDELAY_VALUE           ( 0         ),
        .ODELAY_VALUE           ( 10        ),
        .REFCLK_FREQUENCY       ( 200.0     ),
        .SIGNAL_PATTERN         ( "DATA"    )
    ) u_IODELAY_txd3(
        .C      ( 1'b0          ),
        .CE     ( 1'b0          ),
        .INC    ( 1'b0          ),
        .DATAIN ( 1'b0          ),
        .DATAOUT( rgmii_txd[3]  ),
        .IDATAIN( 1'b0          ),
        .ODATAIN( d_rgmii_txd[3]),
        .RST    ( ~rst_b        ),
        .T      ( 1'b1          )
    );

    IODELAY #(
        .DELAY_SRC              ( "O"       ),
        .HIGH_PERFORMANCE_MODE  ( "TRUE"    ),
        .IDELAY_TYPE            ( "FIXED"   ),
        .IDELAY_VALUE           ( 0         ),
        .ODELAY_VALUE           ( 10        ),
        .REFCLK_FREQUENCY       ( 200.0     ),
        .SIGNAL_PATTERN         ( "DATA"    )
    ) u_IODELAY_txe(
        .C      ( 1'b0          ),
        .CE     ( 1'b0          ),
        .INC    ( 1'b0          ),
        .DATAIN ( 1'b0          ),
        .DATAOUT( rgmii_txe     ),
        .IDATAIN( 1'b0          ),
        .ODATAIN( d_rgmii_txe   ),
        .RST    ( ~rst_b        ),
        .T      ( 1'b1          )
    );
*/
    // Rx

    wire        id_rgmii_rxe;
    wire [3:0]  id_rgmii_rxd;
    wire        d_gmii_rxe;
    wire        d_gmii_rxer;
    wire [7:0]  d_gmii_rxd;
    reg         gmii_rxe;
    reg         gmii_rxer;
    reg [7:0]   gmii_rxd;

    IODELAY #(
        .DELAY_SRC              ( "I"       ),
        .HIGH_PERFORMANCE_MODE  ( "TRUE"    ),
        .IDELAY_TYPE            ( "FIXED"   ),
        .IDELAY_VALUE           ( 6         ),
        .ODELAY_VALUE           ( 0        ),
        .REFCLK_FREQUENCY       ( 200.0     ),
        .SIGNAL_PATTERN         ( "DATA"    )
    ) u_IODELAY_rxe(
        .C      ( 1'b0          ),
        .CE     ( 1'b0          ),
        .INC    ( 1'b0          ),
        .DATAIN ( 1'b0          ),
        .DATAOUT( id_rgmii_rxe   ),
        .IDATAIN( rgmii_rxe     ),
        .ODATAIN( 1'b0          ),
        .RST    ( ~rst_b        ),
        .T      ( 1'b0          )
    );

    IODELAY #(
        .DELAY_SRC              ( "I"       ),
        .HIGH_PERFORMANCE_MODE  ( "TRUE"    ),
        .IDELAY_TYPE            ( "FIXED"   ),
        .IDELAY_VALUE           ( 6         ),
        .ODELAY_VALUE           ( 0        ),
        .REFCLK_FREQUENCY       ( 200.0     ),
        .SIGNAL_PATTERN         ( "DATA"    )
    ) u_IODELAY_rxd3(
        .C      ( 1'b0          ),
        .CE     ( 1'b0          ),
        .INC    ( 1'b0          ),
        .DATAIN ( 1'b0          ),
        .DATAOUT( id_rgmii_rxd[3]),
        .IDATAIN( rgmii_rxd[3]  ),
        .ODATAIN( 1'b0          ),
        .RST    ( ~rst_b        ),
        .T      ( 1'b0          )
    );

    IODELAY #(
        .DELAY_SRC              ( "I"       ),
        .HIGH_PERFORMANCE_MODE  ( "TRUE"    ),
        .IDELAY_TYPE            ( "FIXED"   ),
        .IDELAY_VALUE           ( 6         ),
        .ODELAY_VALUE           ( 0        ),
        .REFCLK_FREQUENCY       ( 200.0     ),
        .SIGNAL_PATTERN         ( "DATA"    )
    ) u_IODELAY_rxd2(
        .C      ( 1'b0          ),
        .CE     ( 1'b0          ),
        .INC    ( 1'b0          ),
        .DATAIN ( 1'b0          ),
        .DATAOUT( id_rgmii_rxd[2]),
        .IDATAIN( rgmii_rxd[2]  ),
        .ODATAIN( 1'b0          ),
        .RST    ( ~rst_b        ),
        .T      ( 1'b0          )
    );

    IODELAY #(
        .DELAY_SRC              ( "I"       ),
        .HIGH_PERFORMANCE_MODE  ( "TRUE"    ),
        .IDELAY_TYPE            ( "FIXED"   ),
        .IDELAY_VALUE           ( 6         ),
        .ODELAY_VALUE           ( 0        ),
        .REFCLK_FREQUENCY       ( 200.0     ),
        .SIGNAL_PATTERN         ( "DATA"    )
    ) u_IODELAY_rxd1(
        .C      ( 1'b0          ),
        .CE     ( 1'b0          ),
        .INC    ( 1'b0          ),
        .DATAIN ( 1'b0          ),
        .DATAOUT( id_rgmii_rxd[1]),
        .IDATAIN( rgmii_rxd[1]  ),
        .ODATAIN( 1'b0          ),
        .RST    ( ~rst_b        ),
        .T      ( 1'b0          )
    );

    IODELAY #(
        .DELAY_SRC              ( "I"       ),
        .HIGH_PERFORMANCE_MODE  ( "TRUE"    ),
        .IDELAY_TYPE            ( "FIXED"   ),
        .IDELAY_VALUE           ( 6         ),
        .ODELAY_VALUE           ( 0        ),
        .REFCLK_FREQUENCY       ( 200.0     ),
        .SIGNAL_PATTERN         ( "DATA"    )
    ) u_IODELAY_rxd0(
        .C      ( 1'b0          ),
        .CE     ( 1'b0          ),
        .INC    ( 1'b0          ),
        .DATAIN ( 1'b0          ),
        .DATAOUT( id_rgmii_rxd[0]),
        .IDATAIN( rgmii_rxd[0]  ),
        .ODATAIN( 1'b0          ),
        .RST    ( ~rst_b        ),
        .T      ( 1'b0          )
    );


    IDDR u_rxd3 (
        .D      ( id_rgmii_rxd[3]  ),
        .R      ( ~rst_b        ),
        .S      ( 1'b0		    ),
        .C      ( rx_clk        ),
        .CE     ( 1'b1          ),
        .Q1     ( d_gmii_rxd[3]   ),
        .Q2     ( d_gmii_rxd[7]   )
    );

    IDDR u_rxd2 (
        .D      ( id_rgmii_rxd[2]  ),
        .R      ( ~rst_b        ),
        .S      ( 1'b0		    ),
        .C      ( rx_clk        ),
        .CE     ( 1'b1          ),
        .Q1     ( d_gmii_rxd[2]   ),
        .Q2     ( d_gmii_rxd[6]   )
    );

    IDDR u_rxd1 (
        .D      ( id_rgmii_rxd[1]  ),
        .R      ( ~rst_b        ),
        .S      ( 1'b0		    ),
        .C      ( rx_clk        ),
        .CE     ( 1'b1          ),
        .Q1     ( d_gmii_rxd[1]   ),
        .Q2     ( d_gmii_rxd[5]   )
    );

    IDDR u_rxd0 (
        .D      ( id_rgmii_rxd[0]  ),
        .R      ( ~rst_b        ),
        .S      ( 1'b0		    ),
        .C      ( rx_clk        ),
        .CE     ( 1'b1          ),
        .Q1     ( d_gmii_rxd[0]   ),
        .Q2     ( d_gmii_rxd[4]   )
    );

    IDDR u_rxc (
        .D      ( id_rgmii_rxe     ),
        .R      ( ~rst_b        ),
        .S      ( 1'b0		    ),
        .C      ( rx_clk        ),
        .CE     ( 1'b1          ),
        .Q1     ( d_gmii_rxe   ),
        .Q2     ( d_gmii_rxer    )
    );

/*
    reg         d_gmii_rxe;
    reg [7:0]   d_gmii_rxd;
    reg         gmii_rxe;
    reg         gmii_rxer;
    reg [7:0]   gmii_rxd;

    always @(posedge rx_clk or negedge rst_b) begin
        if(!rst_b) begin
            d_gmii_rxe  <= 1'b0;
        end else begin
            d_gmii_rxe  <= rgmii_rxe;
        end
    end

    always @(negedge rx_clk or negedge rst_b) begin
        if(!rst_b) begin
            d_gmii_rxd[3:0]   <= 4'd0;
        end else begin
            d_gmii_rxd[3:0]   <= rgmii_rxd;
        end
    end

    always @(posedge rx_clk or negedge rst_b) begin
        if(!rst_b) begin
            d_gmii_rxd[7:4]   <= 4'd0;
        end else begin
            d_gmii_rxd[7:4]   <= rgmii_rxd;
        end
    end

    always @(negedge rx_clk or negedge rst_b) begin
        if(!rst_b) begin
            gmii_rxe   <= 1'b0;
            gmii_rxer  <= 1'b0;
        end else begin
            gmii_rxe   <= d_gmii_rxe;
            gmii_rxer  <= ~d_gmii_rxe;
        end
    end

    always @(negedge rx_clk or negedge rst_b) begin
        if(!rst_b) begin
            gmii_rxd    <= 8'd0;
        end else begin
            gmii_rxd    <= d_gmii_rxd;
        end
    end
*/
    always @(posedge rx_clk or negedge rst_b) begin
        if(!rst_b) begin
            gmii_rxe   <= 1'b0;
            gmii_rxer  <= 1'b0;
            gmii_rxd     <= 8'd0;
        end else begin
            gmii_rxe   <= d_gmii_rxe;
            gmii_rxer  <= ~d_gmii_rxe;
            gmii_rxd    <= d_gmii_rxd;
        end
    end

`else
    reg [7:0]       tx_data;
    reg             tx_ena_r;
    reg             tx_ena_f;

    // TX Data
    always @(negedge tx_clk or negedge rst_b) begin
        if(!rst_b) begin
            tx_data[3:0] <= 4'd0;
            tx_ena_r     <= 1'b0;
        end else begin
            tx_data[3:0] <= gmii_txd[3:0];
            tx_ena_r     <= gmii_txe;
        end
    end

    always @(posedge tx_clk or negedge rst_b) begin
        if(!rst_b) begin
            tx_data[7:4] <= 4'd0;
            tx_ena_f     <= 1'b0;
        end else begin
            tx_data[7:4] <= gmii_txd[7:4];
            tx_ena_f     <= gmii_txe & ~gmii_txer;
        end
    end

    assign rgmii_txd[3:0] = (tx_clk)?tx_data[7:4]:tx_data[3:0];
    assign rgmii_txe      = (tx_clk)?tx_ena_f:tx_ena_r;

    reg [7:0] gmii_rxd;
    reg       gmii_rxe;
    reg       gmii_rxer;

    // RX Data(Posedge)
    always @(posedge rx_clk or negedge rst_b) begin
        if(!rst_b) begin
            gmii_rxd[3:0] <= 4'd0;
            gmii_rxe      <= 1'b0;
        end else begin
            gmii_rxd[3:0] <= rgmii_rxd[3:0];
            gmii_rxe      <= rgmii_rxe;
        end
    end
    // RX Data(negedge)
    always @(negedge rx_clk or negedge rst_b) begin
        if(!rst_b) begin
            gmii_rxd[7:4] <= 4'd0;
        end else begin
            gmii_rxd[7:4] <= rgmii_rxd[3:0];
            gmii_rxer     <= ~rgmii_rxe;
        end
    end
`endif
endmodule
