/*
* PROJECT: AQUAXIS Giga Ethernet MAC
* ----------------------------------------------------------------------
*
* IP/TCP/UDP/ARP/ICMP Offload Engine
* File: aq_gemac_rx_decode.v
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
* 2007/06/01	H.Ishihara	Create
* 2012/05/29	H.Ishihara	change license, GPLv3 -> MIT
*							STATUS - change bit width 16bit -> 32bit
*
* Status
*  [31:24]	Port7-0
*  [12]		MyIPAddress
*  [11]		MyMacAddress
*  [10]		TCPCheckSumOk
*  [9]		ICMPCheckSumOk
*  [8]		IPCheckSumOk
*  [5]		UDP
*  [4]		TCP
*  [3]		ICMP
*  [2]		ARP
*  [1]		IPv6
*  [0]		IPv4
*
*/
module aq_gemac_rx_decode(
	input			RST_N,
	input			CLK,

	input			BUFF_WE,
	input			BUFF_START,
	input			BUFF_END,
	input [7:0]		BUFF_DATA,

	input [47:0]	MAC_ADDRESS,
	input [31:0]	IP_ADDRESS,
	input [15:0]	PORT0,
	input [15:0]	PORT1,
	input [15:0]	PORT2,
	input [15:0]	PORT3,

	output [15:0]	STATUS
);

	reg [1:0]	State;
	parameter S_IDLE	= 2'd0;
	parameter S_DATA	= 2'd1;

	reg [12:0]	Length;

	reg [7:0]	BuffDelay;
	reg			TypeIPv4, TypeARP, TypeIPv6, TypeICMP, TypeTCP, TypeUDP, MyMac, MyIP;
	reg [3:0]	Port;

	reg	[31:0]	IPCheckSum, TCPCheckSum, ICMPCheckSum;

	reg [16:0]	IPCheckSumTemp, TCPCheckSumTemp, ICMPCheckSumTemp;
	wire [15:0]	IPCheckSumLast, TCPCheckSumLast, ICMPCheckSumLast;

	wire		IPCheckSumOK, TCPCheckSumOK, ICMPCheckSumOK;

	// Length Count
	always @(posedge CLK or negedge RST_N) begin
		if(!RST_N) begin
			State			<= S_IDLE;
			Length[12:0]	<= 13'd0;
		end else begin
			case(State)
				S_IDLE: begin
					if(BUFF_WE && BUFF_START)	begin
						State			<= S_DATA;
						Length[12:0]	<= 13'd1;
					end
				end
				S_DATA: begin
					if(BUFF_WE) begin
						if(BUFF_END) begin
							State			<= S_IDLE;
							Length[12:0]	<= 13'd0;
						end else begin
							Length[12:0]	<= Length[12:0] +13'd1;
						end
					end
				end
			endcase
		end
	end

	// Check Frame Type
	always @(posedge CLK or negedge RST_N) begin
		if(!RST_N) begin
			BuffDelay[7:0]	<= 8'd0;
			TypeIPv4		<= 1'b0;
			TypeARP			<= 1'b0;
			TypeIPv6		<= 1'b0;
			TypeICMP		<= 1'b0;
			TypeTCP			<= 1'b0;
			TypeUDP			<= 1'b0;
			MyMac			<= 1'b0;
			MyIP			<= 1'b0;
			Port[3:0]		<= 4'd0;
		end else begin
			if(BUFF_WE) BuffDelay[7:0] <= BUFF_DATA[7:0];

			// Check Type
			if(State == S_DATA) begin
				if(BUFF_WE) begin
					case(Length[12:0])
						// MAC Address
						13'd1: begin
							if((BuffDelay[7:0] == MAC_ADDRESS[7:0]) && (BUFF_DATA[7:0] == MAC_ADDRESS[15:8]))	MyMac <= 1'b1;
						end
						13'd2: begin
							if(BUFF_DATA[7:0] != MAC_ADDRESS[23:16])	MyMac <= 1'b0;
						end
						13'd3: begin
							if(BUFF_DATA[7:0] != MAC_ADDRESS[31:24])	MyMac <= 1'b0;
						end
						13'd4: begin
							if(BUFF_DATA[7:0] != MAC_ADDRESS[39:32])	MyMac <= 1'b0;
						end
						13'd5: begin
							if(BUFF_DATA[7:0] != MAC_ADDRESS[47:40])	MyMac <= 1'b0;
						end
						// Packet Type
						13'd13: begin
							if((BuffDelay[7:0] == 8'h08) && (BUFF_DATA[7:0] == 8'h00))		TypeIPv4 <= 1'b1;
							else if((BuffDelay[7:0] == 8'h08) && (BUFF_DATA[7:0] == 8'h06))	TypeARP  <= 1'b1;
							else if((BuffDelay[7:0] == 8'h86) && (BUFF_DATA[7:0] == 8'hDD))	TypeIPv6 <= 1'b1;
						end
						// Payload Type
						13'd23: begin
							if(TypeIPv4) begin
								if(BUFF_DATA[7:0] == 8'h01)	TypeICMP <= 1'b1;
								if(BUFF_DATA[7:0] == 8'h06)	TypeTCP  <= 1'b1;
								if(BUFF_DATA[7:0] == 8'h11)	TypeUDP  <= 1'b1;
							end
						end
						// IP Address
						13'd30: begin
							if(TypeIPv4) begin
								if(BUFF_DATA[7:0] == IP_ADDRESS[7:0])	MyIP <= 1'b1;
							end
						end
						13'd31: begin
							if(TypeIPv4) begin
								if(BUFF_DATA[7:0] != IP_ADDRESS[15:8])	MyIP <= 1'b0;
							end
						end
						13'd32: begin
							if(TypeIPv4) begin
								if(BUFF_DATA[7:0] != IP_ADDRESS[23:16])	MyIP <= 1'b0;
							end
						end
						13'd33: begin
							if(TypeIPv4) begin
								if(BUFF_DATA[7:0] != IP_ADDRESS[31:24])	MyIP <= 1'b0;
							end
						end
						// PORT
						13'd35: begin
							if(TypeTCP | TypeUDP) begin
								if((BuffDelay[7:0] == PORT0[15:8]) && (BUFF_DATA[7:0] == PORT0[7:0]))	Port[0] <= 1'b1;
								if((BuffDelay[7:0] == PORT1[15:8]) && (BUFF_DATA[7:0] == PORT1[7:0]))	Port[1] <= 1'b1;
								if((BuffDelay[7:0] == PORT2[15:8]) && (BUFF_DATA[7:0] == PORT2[7:0]))	Port[2] <= 1'b1;
								if((BuffDelay[7:0] == PORT3[15:8]) && (BUFF_DATA[7:0] == PORT3[7:0]))	Port[3] <= 1'b1;
							end
						end
					endcase
				end
			end else begin
				MyMac		<= 1'b0;
				MyIP		<= 1'b0;
				TypeIPv4	<= 1'b0;
				TypeARP		<= 1'b0;
				TypeIPv6	<= 1'b0;
				TypeICMP	<= 1'b0;
				TypeTCP		<= 1'b0;
				TypeUDP		<= 1'b0;
				Port[3:0]	<= 4'd0;
			end

			// IP CheckSum
			if(State == S_DATA) begin
				if(BUFF_WE) begin
					case(Length[12:0])
						13'd15: IPCheckSum[31:0]	<= IPCheckSum[31:0] + {16'd0, BuffDelay[7:0], BUFF_DATA[7:0]};
						13'd17: IPCheckSum[31:0]	<= IPCheckSum[31:0] + {16'd0, BuffDelay[7:0], BUFF_DATA[7:0]};
						13'd19: IPCheckSum[31:0]	<= IPCheckSum[31:0] + {16'd0, BuffDelay[7:0], BUFF_DATA[7:0]};
						13'd21: IPCheckSum[31:0]	<= IPCheckSum[31:0] + {16'd0, BuffDelay[7:0], BUFF_DATA[7:0]};
						13'd23: IPCheckSum[31:0]	<= IPCheckSum[31:0] + {16'd0, BuffDelay[7:0], BUFF_DATA[7:0]};
						13'd25: IPCheckSum[31:0]	<= IPCheckSum[31:0] + {16'd0, BuffDelay[7:0], BUFF_DATA[7:0]};
						13'd27: IPCheckSum[31:0]	<= IPCheckSum[31:0] + {16'd0, BuffDelay[7:0], BUFF_DATA[7:0]};
						13'd29: IPCheckSum[31:0]	<= IPCheckSum[31:0] + {16'd0, BuffDelay[7:0], BUFF_DATA[7:0]};
						13'd31: IPCheckSum[31:0]	<= IPCheckSum[31:0] + {16'd0, BuffDelay[7:0], BUFF_DATA[7:0]};
						13'd33: IPCheckSum[31:0]	<= IPCheckSum[31:0] + {16'd0, BuffDelay[7:0], BUFF_DATA[7:0]};
					endcase
				end
			end else begin
				IPCheckSum[31:0]	<= 32'd0;
			end

			// ICMP CheckSum
			if(State == S_DATA) begin
				if(BUFF_WE) begin
					if((Length[12:0] > 13'd34) && (Length[0] == 1'b1)) begin
						ICMPCheckSum[31:0]	<= ICMPCheckSum[31:0] + {16'd0, BuffDelay[7:0], BUFF_DATA[7:0]};
					end
				end
			end else begin
				ICMPCheckSum[31:0]	<= 32'd0;
			end

			// TCP/UDP CheckSum
			if(State == S_DATA) begin
				if(BUFF_WE) begin
					if(Length[12:0] == 13'd17) begin
						TCPCheckSum[31:0]	<= TCPCheckSum[31:0] + {16'd0, BuffDelay[7:0], BUFF_DATA[7:0]};
					end else if(Length[12:0] == 13'd18) begin
						TCPCheckSum[31:0]	<= TCPCheckSum[31:0] - 32'd20;
					end else if(Length[12:0] == 13'd25) begin
						if(TypeTCP) TCPCheckSum[31:0]	<= TCPCheckSum[31:0] + 32'h00000006;
						if(TypeUDP)	TCPCheckSum[31:0]	<= TCPCheckSum[31:0] + 32'h00000011;
					end else if((Length[12:0] > 13'd26) && (Length[0] == 1'b1)) begin
						TCPCheckSum[31:0]	<= TCPCheckSum[31:0] + {16'd0, BuffDelay[7:0], BUFF_DATA[7:0]};
					end
				end
			end else begin
				TCPCheckSum[31:0]	<= 32'd0;
			end
		end
	end

	assign IPCheckSumLast[15:0]		= {15'd0, IPCheckSumTemp[16]  } + IPCheckSumTemp[15:0];
	assign ICMPCheckSumLast[15:0]	= {15'd0, ICMPCheckSumTemp[16]} + ICMPCheckSumTemp[15:0];
	assign TCPCheckSumLast[15:0]	= {15'd0, TCPCheckSumTemp[16] } + TCPCheckSumTemp[15:0];

	assign IPCheckSumOK		= (IPCheckSumLast[15:0]		== 16'hFFFF);
	assign ICMPCheckSumOK	= (ICMPCheckSumLast[15:0]	== 16'hFFFF);
	assign TCPCheckSumOK	= (TCPCheckSumLast[15:0]	== 16'hFFFF);

	reg [4:0] ICMPCheckSumOKReg;
	reg [4:0] TCPCheckSumOKReg;
	always @(posedge CLK or negedge RST_N) begin
		if(!RST_N) begin
			ICMPCheckSumOKReg[4:0]	<= 5'd0;
			TCPCheckSumOKReg[4:0]	<= 5'd0;
			IPCheckSumTemp[16:0]	<= 17'd0;
			ICMPCheckSumTemp[16:0]	<= 17'd0;
			TCPCheckSumTemp[16:0]	<= 17'd0;
		end else begin
			IPCheckSumTemp[16:0]	<= {1'b1, IPCheckSum[31:16]  } + {1'b1, IPCheckSum[15:0]  };
			ICMPCheckSumTemp[16:0]	<= {1'b1, ICMPCheckSum[31:16]} + {1'b1, ICMPCheckSum[15:0]};
			TCPCheckSumTemp[16:0]	<= {1'b1, TCPCheckSum[31:16] } + {1'b1, TCPCheckSum[15:0] };

			if(BUFF_WE) begin
				ICMPCheckSumOKReg[0]	<= ICMPCheckSumOK;
				ICMPCheckSumOKReg[1]	<= ICMPCheckSumOKReg[0];
				ICMPCheckSumOKReg[2]	<= ICMPCheckSumOKReg[1];
				ICMPCheckSumOKReg[3]	<= ICMPCheckSumOKReg[2];
				ICMPCheckSumOKReg[4]	<= ICMPCheckSumOKReg[3];
				TCPCheckSumOKReg[0]		<= TCPCheckSumOK;
				TCPCheckSumOKReg[1]		<= TCPCheckSumOKReg[0];
				TCPCheckSumOKReg[2]		<= TCPCheckSumOKReg[1];
				TCPCheckSumOKReg[3]		<= TCPCheckSumOKReg[2];
				TCPCheckSumOKReg[4]		<= TCPCheckSumOKReg[3];
			end
		end
	end

	assign STATUS[15:0] =	{
							Port[3:0], 2'd0, MyIP, MyMac,
							TCPCheckSumOKReg[3], ICMPCheckSumOKReg[3], IPCheckSumOK, TypeUDP, TypeTCP, TypeICMP, TypeARP, TypeIPv4
							};
endmodule

