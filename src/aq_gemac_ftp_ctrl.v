/*
* PROJECT: AQUAXIS Giga Ethernet MAC
* ----------------------------------------------------------------------
*
* aq_gemac_ftp_ctrl.v
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
* 2007/01/06 H.Ishihara	Create
* 2011/04/24 H.Ishihara	rename
*/
module aq_gemac_ftp(
    RST,
    CLK,

    FTP_REQUEST,
    FTP_LENGTH,
    FTP_STATUS,

    FTP_DST_MAC_ADDRESS,
    FTP_DST_IP_ADDRESS,
    FTP_DST_PORT,
    FTP_SRC_MAC_ADDRESS,
    FTP_SRC_IP_ADDRESS,
    FTP_SRC_PORT,

    FTP_ROM_ADDRESS,
    FTP_ROM_DATA,

    TX_WE,
    TX_START,
    TX_END,
    TX_READY,
    TX_DATA
);

    input           RST;
    input           CLK;

    input           FTP_REQUEST;
    input [15:0]    FTP_LENGTH;
    output          FTP_STATUS;

    input [47:0]    FTP_DST_MAC_ADDRESS;
    input [31:0]    FTP_DST_IP_ADDRESS;
    input [15:0]    FTP_DST_PORT;
    input [47:0]    FTP_SRC_MAC_ADDRESS;
    input [31:0]    FTP_SRC_IP_ADDRESS;
    input [15:0]    FTP_SRC_PORT;

    output [7:0]    FTP_ROM_ADDRESS;
    input [31:0]    FTP_ROM_DATA;

    output          TX_WE;
    output          TX_START;
    output          TX_END;
    input           TX_READY;
    output [31:0]   TX_DATA;

    reg [4:0]       State;

    parameter S_IDLE    = 5'd0;
    parameter S_WAIT    = 5'd1;
    parameter S_SEND0   = 5'd2;
    parameter S_SEND1   = 5'd3;
    parameter S_SEND2   = 5'd4;
    parameter S_SEND3   = 5'd5;
    parameter S_SEND4   = 5'd6;
    parameter S_SEND5   = 5'd7;
    parameter S_SEND6   = 5'd8;
    parameter S_SEND7   = 5'd9;
    parameter S_SEND8   = 5'd10;
    parameter S_SEND9   = 5'd11;
    parameter S_SEND10  = 5'd12;
    parameter S_SEND11  = 5'd13;
    parameter S_SEND12  = 5'd14;
    parameter S_END     = 5'd15;

    reg [15:0]      SendLength;
    reg             SendWe, SendStart, SendEnd;
    reg [31:0]      SendData;
    reg [7:0]       FtpRomAddress;
    reg [31:0]      FtpDelayData;

    always @(posedge CLK or negedge RST) begin
        if(!RST) begin
            State           <= S_IDLE;
            SendWe          <= 1'b0;
            SendStart       <= 1'b0;
            SendEnd         <= 1'b0;
            SendData        <= 32'd0;
            SendLength      <= 16'd0;
            FtpDelayData    <= 32'd0;
            FtpRomAddress   <= 8'd0;
        end else begin
            case(State)
                S_IDLE: begin
                    if(FTP_REQUEST) State <= S_WAIT;
                    SendLength      <= 16'd14 + 16'd20 + 16'd8 + FTP_LENGTH;
                    FtpRomAddress   <= 8'd0;
                    SendWe          <= 1'b0;
                    SendStart       <= 1'b0;
                    SendEnd         <= 1'b0;
                    SendData        <= 32'd0;
                end
                S_WAIT: begin
                    if(TX_READY) State <= S_SEND0;
                end
                S_SEND0: begin  // Send Frame Length
                    State       <= S_SEND1;
                    SendWe      <= 1'b1;
                    SendStart   <= 1'b1;
                    SendData    <= {SendLength, 16'h0000};
                    SendLength  <= SendLength -16'd14;
                end
                S_SEND1: begin  // Send Destination MAC Address
                    State       <= S_SEND2;
                    SendWe      <= 1'b1;
                    SendStart   <= 1'b0;
                    SendData    <= FTP_DST_MAC_ADDRESS[31:0];
                end
                S_SEND2: begin  // Send Source MAC Address, Destination MAC Address
                    State       <= S_SEND3;
                    SendWe      <= 1'b1;
                    SendData    <= {FTP_SRC_MAC_ADDRESS[15:0], FTP_DST_MAC_ADDRESS[47:32]};
                end
                S_SEND3: begin  // Send Source MAC Address
                    State       <= S_SEND4;
                    SendWe      <= 1'b1;
                    SendData    <= FTP_SRC_MAC_ADDRESS[47:16];
                end
                S_SEND4: begin  // Send IP Header(Service Type, Header Length, Version), Ethernet Type
                    State       <= S_SEND5;
                    SendWe      <= 1'b1;
                    SendData    <= {16'h0045, 16'h0008};
                end
                S_SEND5: begin  // Send Identification, Total Length
                    State       <= S_SEND6;
                    SendWe      <= 1'b1;
                    SendData    <= {16'h0000, SendLength[7:0], SendLength[15:8]};
                    SendLength  <= SendLength -16'd20;
                end
                S_SEND6: begin  // Send Protocol, Time to Live, Flagmentation
                    State       <= S_SEND7;
                    SendWe      <= 1'b1;
                    SendData    <= {8'h11, 8'hFF, 16'h0000};
                end
                S_SEND7: begin  // Send Destination IP Address, CheckSum
                    State       <= S_SEND8;
                    SendWe      <= 1'b1;
                    SendData    <= {FTP_SRC_IP_ADDRESS[15:0], 16'h0000};
                end
                S_SEND8: begin  // Send Source IP Address, Destination IP Address
                    State       <= S_SEND9;
                    SendWe      <= 1'b1;
                    SendData    <= {FTP_DST_IP_ADDRESS[15:0], FTP_SRC_IP_ADDRESS[31:16]};
                end
                S_SEND9: begin  // Send UDP Header(Source Port), Source IP Address
                    State       <= S_SEND10;
                    SendWe      <= 1'b1;
                    SendData    <= {FTP_SRC_PORT, FTP_DST_IP_ADDRESS[31:16]};
                end
                S_SEND10: begin  // Send Length, Destination Port
                    State       <= S_SEND11;
                    SendWe      <= 1'b1;
                    SendData    <= {SendLength[7:0], SendLength[15:8], FTP_DST_PORT};
                    SendLength  <= SendLength -16'd8;
                    FtpRomAddress <= 8'd0;
                end
                S_SEND11: begin  // Send Data, CheckSum
                    State       <= S_SEND12;
                    SendWe      <= 1'b1;
                    SendData    <= {FTP_ROM_DATA[15:0], 16'h0000};
                    FtpRomAddress <= 8'd1;
                    SendLength  <= SendLength -16'd2;
                end
                S_SEND12: begin
                    if(SendLength < 16'd4) begin
                        State   <= S_END;
                        SendEnd <= 1'b1;
                    end else begin
                        SendLength <= SendLength -16'd4;
                    end
                    SendWe      <= 1'b1;
                    SendData    <= {FTP_ROM_DATA[15:0], FtpDelayData[31:16]};
                    FtpRomAddress <= FtpRomAddress +8'd1;
                end
                S_END: begin
                    State       <= S_IDLE;
                    SendWe      <= 1'b0;
                    SendEnd     <= 1'b0;
                    SendData    <= 32'd00000000;
                end
            endcase
            FtpDelayData <= FTP_ROM_DATA;
        end
    end

    assign TX_WE    = SendWe;
    assign TX_START = SendStart;
    assign TX_END   = SendEnd;
    assign TX_DATA  = SendData;

    assign FTP_ROM_ADDRESS = FtpRomAddress;
    assign FTP_STATUS   = (State != S_IDLE);
endmodule
