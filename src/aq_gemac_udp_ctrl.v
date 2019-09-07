/*
* PROJECT: AQUAXIS Giga Ethernet MAC
* ----------------------------------------------------------------------
*
* UDP Packet Controler
* File: aq_gemac_udp_ctrl.v
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
* 2007/06/01 H.Ishihara	Create
*/
module aq_gemac_udp_ctrl(
	input			RST_N,
	input			CLK,

	input [47:0]	MY_MAC_ADDRESS,
	input [31:0]	MY_IP_ADDRESS,

	// Send UDP
	input			SEND_REQUEST,
	input [15:0]	SEND_LENGTH,
	output			SEND_BUSY,
	input [47:0]	SEND_MAC_ADDRESS,
	input [31:0]	SEND_IP_ADDRESS,
	input [15:0]	SEND_DST_PORT,
	input [15:0]	SEND_SRC_PORT,
	input			SEND_DATA_VALID,
	output			SEND_DATA_READ,
	input [31:0]	SEND_DATA,

	// Receive UDP
	output			REC_REQUEST,
	output [15:0]	REC_LENGTH,
	output			REC_BUSY,
	input [15:0]	REC_DST_PORT0,
	input [15:0]	REC_DST_PORT1,
	input [15:0]	REC_DST_PORT2,
	input [15:0]	REC_DST_PORT3,
	output [3:0]	REC_DATA_VALID,
	output [47:0]	REC_SRC_MAC,
	output [31:0]	REC_SRC_IP,
	output [15:0]	REC_SRC_PORT,
	input			REC_DATA_READ,
	output [31:0]	REC_DATA,

	// for ETHER-MAC BUFFER
	output			TX_WE,
	output			TX_START,
	output			TX_END,
	input			TX_READY,
	output [31:0]	TX_DATA,
	input			TX_FULL,
	input [9:0]		TX_SPACE,

	output			RX_RE,
	input [31:0]	RX_DATA,
	input			RX_EMPTY,
	input			RX_VALID,
	input [15:0]	RX_LENGTH,
	input [15:0]	RX_STATUS,

	// External TX Buffer Interface
	input			ETX_WE,
	input			ETX_START,
	input			ETX_END,
	output			ETX_READY,
	input [31:0]	ETX_DATA,
	output			ETX_FULL,
	output [9:0]	ETX_SPACE,

	// External RX Buffer Interface
	input			ERX_RE,
	output [31:0]	ERX_DATA,
	output			ERX_EMPTY,
	output			ERX_VALID,
	output [15:0]	ERX_LENGTH,
	output [15:0]	ERX_STATUS

);

	reg [4:0]		TxState;

	parameter S_IDLE	= 5'd0;
	parameter S_WAIT	= 5'd1;
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
	parameter S_END		= 5'd15;

	reg [15:0]	SendLength;
	reg			SendWe, SendStart, SendEnd;
	reg [31:0]	SendData;
	reg [31:0]	UdpSendDelay;
	reg			UdpSendRead;

	// Tx State
	always @(posedge CLK or negedge RST_N) begin
		if(!RST_N) begin
			TxState			<= S_IDLE;
			SendWe			<= 1'b0;
			SendStart		<= 1'b0;
			SendEnd			<= 1'b0;
			SendData		<= 32'd0;
			SendLength		<= 16'd0;
			UdpSendDelay	<= 32'd0;
			UdpSendRead		<= 1'b0;
		end else begin
			case(TxState)
				S_IDLE: begin
					if(SEND_REQUEST) TxState <= S_WAIT;
					SendLength	<= 16'd14 + 16'd20 + 16'd8 + SEND_LENGTH;
					SendWe		<= 1'b0;
					SendStart	<= 1'b0;
					SendEnd		<= 1'b0;
					SendData	<= 32'd0;
					UdpSendRead	<= 1'b0;
				end
				S_WAIT: begin
					if(TX_READY && ({4'd0, TX_SPACE, 2'd0} > SendLength)) TxState <= S_SEND0;
				end
				S_SEND0: begin  // Send Frame Length
					TxState		<= S_SEND1;
					SendWe		<= 1'b1;
					SendStart	<= 1'b1;
					SendData	<= {SendLength, 16'h0000};
					SendLength	<= SendLength -16'd14;
				end
				S_SEND1: begin  // Send Destination MAC Address
					TxState		<= S_SEND2;
					SendWe		<= 1'b1;
					SendStart	<= 1'b0;
					SendData	<= SEND_MAC_ADDRESS[31:0];
				end
				S_SEND2: begin  // Send Source MAC Address, Destination MAC Address
					TxState		<= S_SEND3;
					SendWe		<= 1'b1;
					SendData	<= {MY_MAC_ADDRESS[15:0], SEND_MAC_ADDRESS[47:32]};
				end
				S_SEND3: begin  // Send Source MAC Address
					TxState		<= S_SEND4;
					SendWe		<= 1'b1;
					SendData	<= MY_MAC_ADDRESS[47:16];
				end
				S_SEND4: begin  // Send IP Header(Service Type, Header Length, Version), Ethernet Type
					TxState		<= S_SEND5;
					SendWe		<= 1'b1;
					SendData	<= {16'h0045, 16'h0008};
				end
				S_SEND5: begin  // Send Identification, Total Length
					TxState		<= S_SEND6;
					SendWe		<= 1'b1;
					SendData	<= {16'h0000, SendLength[7:0], SendLength[15:8]};
					SendLength	<= SendLength -16'd20;
				end
				S_SEND6: begin  // Send Protocol, Time to Live, Flagmentation
					TxState		<= S_SEND7;
					SendWe		<= 1'b1;
					SendData	<= {8'h11, 8'hFF, 16'h0000};
				end
				S_SEND7: begin  // Send Source IP Address, CheckSum
					TxState		<= S_SEND8;
					SendWe		<= 1'b1;
					SendData	<= {MY_IP_ADDRESS[15:0], 16'h0000};
				end
				S_SEND8: begin  // Send Destination IP Address, Source IP Address
					TxState		<= S_SEND9;
					SendWe		<= 1'b1;
					SendData	<= {SEND_IP_ADDRESS[15:0], MY_IP_ADDRESS[31:16]};
				end
				S_SEND9: begin  // Send UDP Header(Source Port), Send Destination IP Address
					TxState		<= S_SEND10;
					SendWe		<= 1'b1;
					SendData	<= {SEND_SRC_PORT, SEND_IP_ADDRESS[31:16]};
				end
				S_SEND10: begin  // Send Length, Destination Port
					TxState		<= S_SEND11;
					SendWe		<= 1'b1;
					SendData	<= {SendLength[7:0], SendLength[15:8], SEND_DST_PORT};
					SendLength	<= SendLength -16'd8;
				end
				S_SEND11: begin  // Send Data, CheckSum
					if(SEND_DATA_VALID) begin
						TxState		<= S_SEND12;
						SendWe		<= 1'b1;
						SendData	<= {SEND_DATA[15:0], 16'h0000};
						SendLength	<= SendLength -16'd2;
						UdpSendRead	<= 1'b1;
					end else begin
						SendWe		<= 1'b0;
						UdpSendRead	<= 1'b0;
					end
				end
				S_SEND12: begin
					if(SEND_DATA_VALID) begin
						if(SendLength < 16'd4) begin
							TxState	<= S_END;
							SendEnd	<= 1'b1;
							case(SendLength)
							16'd4: SendData	<= {SEND_DATA[15:0], UdpSendDelay[31:16]};
							16'd3: SendData	<= {8'd0, SEND_DATA[7:0], UdpSendDelay[31:16]};
							16'd2: SendData	<= {16'd0, UdpSendDelay[31:16]};
							16'd1: SendData	<= {24'd0, UdpSendDelay[23:16]};
							endcase
							if(( SendLength == 16'd4 ) && ( SendLength == 16'd3 )) begin
								UdpSendRead	<= 1'b1;
							end else begin
								UdpSendRead	<= 1'b0;
							end
						end else begin
							UdpSendRead	<= 1'b1;
							SendLength	<= SendLength -16'd4;
							SendData	<= {SEND_DATA[15:0], UdpSendDelay[31:16]};
						end
						SendWe	<= 1'b1;
					end else if(SendLength <= 16'd2) begin
						TxState	<= S_END;
						SendEnd	<= 1'b1;
						SendWe	<= 1'b1;
						UdpSendRead	<= 1'b0;
						case(SendLength)
							16'd2: SendData	<= {16'd0, UdpSendDelay[31:16]};
							16'd1: SendData	<= {24'd0, UdpSendDelay[23:16]};
						endcase
					end else begin
						SendWe	<= 1'b0;
						UdpSendRead	<= 1'b0;
					end
				end
				S_END: begin
					TxState		<= S_IDLE;
					SendWe		<= 1'b0;
					SendEnd		<= 1'b0;
					SendData	<= 32'd00000000;
					UdpSendRead	<= 1'b0;
				end
			endcase
			if(SEND_DATA_VALID) begin
				UdpSendDelay <= SEND_DATA;
			end
		end
	end

	// Rx State
	reg [4:0] RxState;

	parameter R_IDLE		= 5'd0;
	parameter R_GET0		= 5'd1;
	parameter R_GET1		= 5'd2;
	parameter R_GET2		= 5'd3;
	parameter R_GET3		= 5'd4;
	parameter R_GET4		= 5'd5;
	parameter R_GET5		= 5'd6;
	parameter R_GET6		= 5'd7;
	parameter R_GET7		= 5'd8;
	parameter R_GET8		= 5'd9;
	parameter R_GET9		= 5'd10;
	parameter R_GET10		= 5'd11;
	parameter R_GET_DATA	= 5'd12;
	parameter R_FINAL		= 5'd13;

	reg [15:0]	RecLength;
	reg [31:0]	UdpRecDelay;
	reg			RxRead;
	reg [47:0]	RecSrcMac;
	reg [31:0]	RecSrcIP;
	reg [15:0]	RecDstPort;
	reg [15:0]	RecSrcPort;
//	reg			UdpRecRead;
//	reg [31:0]	UdpRecData;

	// Rx State
	always @(posedge CLK or negedge RST_N) begin
		if(!RST_N) begin
			RxState		<= R_IDLE;
			RecLength	<= 16'd0;
			RxRead		<= 1'b0;
			RecSrcMac	<= 48'd0;
			RecSrcIP	<= 32'd0;
			RecDstPort	<= 4'd0;
			RecSrcPort	<= 16'd0;
			UdpRecDelay <= 32'd0;
//			UdpRecRead	<= 1'b0;
//			UdpRecData	<= 32'd0;
		end else begin
			case(RxState)
			R_IDLE: begin
				if(RX_VALID & RX_STATUS[12] & RX_STATUS[9] & RX_STATUS[8])	RxState <= R_GET0;
				RxRead	<= 1'b0;
			end
			R_GET0: begin   // Send Destination MAC Address
				RxState	<= R_GET1;
			end
			R_GET1: begin   // Send Source MAC Address, Destination MAC Address
				RxState	<= R_GET2;
				RecSrcMac[15:0]	<= RX_DATA[31:16];
			end
			R_GET2: begin   // Send Source MAC Address
				RxState	<= R_GET3;
				RecSrcMac[47:16]	<= RX_DATA[31:0];
			end
			R_GET3: begin   // Send IP Header(Service Type, Header Length, Version), Ethernet Type
				RxState	<= R_GET4;
			end
			R_GET4: begin   // Send Identification, Total Length
				RxState	<= R_GET5;
			end
			R_GET5: begin   // Send Protocol, Time to Live, Flagmentation
				RxState	<= R_GET6;
			end
			R_GET6: begin   // Send Source IP Address, CheckSum
				RxState	<= R_GET7;
				RecSrcIP[15:0]	<= RX_DATA[31:16];
			end
			R_GET7: begin   // Send Destination IP Address, Source IP Address
				RxState	<= R_GET8;
				RecSrcIP[31:16]	<= RX_DATA[15:0];
			end
			R_GET8: begin   // Send UDP Header(Source Port), Send Destination IP Address
				RxState	<= R_GET9;
				RecSrcPort	<= RX_DATA[31:16];
			end
			R_GET9: begin   // Send Length, Destination Port
				RxState		<= R_GET10;
				RecDstPort	<= RX_DATA[15:0];
				RecLength	<= {RX_DATA[23:16], RX_DATA[31:24]} - 16'd8;
			end
			R_GET10: begin  // Send Data, CheckSum
				RxState   <= R_GET_DATA;
			end
			R_GET_DATA: begin
				if(REC_DATA_READ) begin
					if(RecLength <= 16'd4) begin
						RxState	 <= R_FINAL;
					end
					RecLength   <= RecLength -16'd4;
//					UdpRecRead <= 1'b1;
//					UdpRecData <= {RX_DATA[15:0], UdpRecDelay[31:16]};
				end else begin
//					UdpRecRead <= 1'b0;
//					UdpRecData <= 32'd0;
				end
			end
			R_FINAL: begin
//				UdpRecRead <= 1'b0;
//				UdpRecData <= 32'd0;
				RxState <= R_IDLE;
			end
			default: begin
				RxState <= R_IDLE;
			end
			endcase
			if((RxState == R_GET10) || ((RxState == R_GET_DATA) && (REC_DATA_READ))) begin
				UdpRecDelay <= RX_DATA;
			end
		end
	end

	assign REC_DATA_VALID[0]	= ((RxState == R_GET_DATA) && (RecDstPort == REC_DST_PORT0))?1'b1:1'b0;
	assign REC_DATA_VALID[1]	= ((RxState == R_GET_DATA) && (RecDstPort == REC_DST_PORT1))?1'b1:1'b0;
	assign REC_DATA_VALID[2]	= ((RxState == R_GET_DATA) && (RecDstPort == REC_DST_PORT2))?1'b1:1'b0;
	assign REC_DATA_VALID[3]	= ((RxState == R_GET_DATA) && (RecDstPort == REC_DST_PORT3))?1'b1:1'b0;
	assign REC_SRC_MAC			= RecSrcMac[47:0];
	assign REC_SRC_IP			= RecSrcIP[31:0];
	assign REC_SRC_PORT			= RecSrcPort[15:0];
	assign REC_BUSY				= (RxState != R_IDLE)?1'b1:1'b0;
	assign REC_REQUEST			= (RxState == R_GET10)?1'b1:1'b0;
	assign REC_LENGTH			= RecLength;
	assign REC_DATA				= {RX_DATA[15:0], UdpRecDelay[31:16]};

//	assign SEND_DATA_READ	= (UdpSendRead)?1'b1:1'b0;
	assign SEND_DATA_READ	= (SEND_DATA_VALID & ((TxState == S_SEND11) | (((TxState == S_SEND12) & (SendLength > 16'd2)) )))?1'b1:1'b0;
	assign SEND_BUSY		= (TxState != S_IDLE);

	assign TX_WE		= ETX_WE | SendWe;
	assign TX_START		= ETX_START | SendStart;
	assign TX_END		= ETX_END | SendEnd;
	assign TX_DATA		= (SendWe)?SendData:ETX_DATA;
	assign ETX_FULL		= TX_FULL;
	assign ETX_SPACE	= TX_SPACE;
	assign ETX_READY	= (TxState == S_IDLE)?TX_READY:1'b0;

	assign RX_RE = (RxRead ||
					(RxState == R_GET0) || (RxState == R_GET1) ||
					(RxState == R_GET2) || (RxState == R_GET3) ||
					(RxState == R_GET4) || (RxState == R_GET5) ||
					(RxState == R_GET6) || (RxState == R_GET7) ||
					(RxState == R_GET8) || (RxState == R_GET9) ||
					(RxState == R_GET10) ||
					((RxState == R_GET_DATA) && (REC_DATA_READ))
//					(RxState == R_FINAL)
					)?1'b1:ERX_RE;
	assign ERX_EMPTY	= (RxState == R_IDLE)?RX_EMPTY:1'b1;
	assign ERX_VALID	= (RxState == R_IDLE)?RX_VALID:1'b0;
	assign ERX_DATA		= RX_DATA;
	assign ERX_LENGTH	= RX_LENGTH;
	assign ERX_STATUS	= RX_STATUS;

endmodule
