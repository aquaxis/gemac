/*
* PROJECT: AQUAXIS Giga Ethernet MAC
* ----------------------------------------------------------------------
*
* Gigabit MAC
* File: aq_cemac_l3_ctrl.v
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
* 2007/01/01	H.Ishihara	1st release
* 2011/04/24	H.Ishihara	rename
*/
module aq_gemac_l3_ctrl(
	input			RST_N,
	input			CLK,

	// RX Buffer Interface
	output			RX_BUFF_RE,			// RX Buffer Read Enable
	input [31:0]	RX_BUFF_DATA,		// RX Buffer Data
	input			RX_BUFF_EMPTY,		// RX Buffer Empty(1: Empty, 0: No Empty)
	input			RX_BUFF_VALID,		// RX Buffer Valid
	input [15:0]	RX_BUFF_LENGTH,		// RX Buffer Length
	input [15:0]	RX_BUFF_STATUS,		// RX Buffer Status

	// TX Buffer Interface
	output			TX_BUFF_WE,			// TX Buffer Write Enable
	output			TX_BUFF_START,		// TX Buffer Data Start
	output			TX_BUFF_END,		// TX Buffer Data End
	input			TX_BUFF_READY,		// TX Buffer Ready
	output [31:0]	TX_BUFF_DATA,		// TX Buffer Data
	input			TX_BUFF_FULL,		// TX Buffer Full
	input [9:0]		TX_BUFF_SPACE,		// TX Buffer Space

	// External RX Buffer Interface
	input			ERX_BUFF_RE,		// RX Buffer Read Enable
	output [31:0]	ERX_BUFF_DATA,		// RX Buffer Data
	output			ERX_BUFF_EMPTY,		// RX Buffer Empty(1: Empty, 0: No Empty)
	output			ERX_BUFF_VALID,		// RX Buffer Valid
	output [15:0]	ERX_BUFF_LENGTH,	// RX Buffer Length
	output [15:0]	ERX_BUFF_STATUS,	// RX Buffer Status

	// External TX Buffer Interface
	input			ETX_BUFF_WE,		// TX Buffer Write Enable
	input			ETX_BUFF_START,		// TX Buffer Data Start
	input			ETX_BUFF_END,		// TX Buffer Data End
	output			ETX_BUFF_READY,		// TX Buffer Ready
	input [31:0]	ETX_BUFF_DATA,		// TX Buffer Data
	output			ETX_BUFF_FULL,		// TX Buffer Full
	output [9:0]	ETX_BUFF_SPACE,		// TX Buffer Space

	input [47:0]	MAC_ADDRESS,		// My Mac Address
	input [31:0]	IP_ADDRESS,			// My IP Address

	output			ARPC_ENABLE,		// ARP Cache Request Enable
	input			ARPC_REQUEST,		// ARP Cache Request
	output			ARPC_VALID,			// ARP Cache Valid
	input [31:0]	ARPC_IP_ADDRESS,	// ARP Cache IP Address
	output [47:0]	ARPC_MAC_ADDRESS,   // ARP Cache Mac Address

	output [15:0]	STATUS
);

	wire		ExtensionPickup;

	reg [1:0]	RxState;

	parameter S_RX_IDLE = 2'b00;
	parameter S_RX_ARP  = 2'b01;
	parameter S_RX_ICMP = 2'b10;
	parameter S_RX_ARPC = 2'b11;

	// ARP
	reg [4:0]	ArpState;

	parameter S_ARP_IDLE		= 5'd0;
	parameter S_ARP_MAC1		= 5'd1;
	parameter S_ARP_MAC2		= 5'd2;
	parameter S_ARP_MAC3		= 5'd3;
	parameter S_ARP_TYPE		= 5'd4;
	parameter S_ARP_PROTOCOL	= 5'd5;
	parameter S_ARP_OPERATION   = 5'd6;
	parameter S_ARP_DATA1		= 5'd7;
	parameter S_ARP_DATA2		= 5'd8;
	parameter S_ARP_DATA3		= 5'd9;
	parameter S_ARP_DATA4		= 5'd10;
	parameter S_ARP_DATA5		= 5'd11;
	parameter S_ARP_CHECK		= 5'd12;
	parameter S_ARP_REPLY_WAIT  = 5'd13;
	parameter S_ARP_REPLY0		= 5'd14;
	parameter S_ARP_REPLY1		= 5'd15;
	parameter S_ARP_REPLY2		= 5'd16;
	parameter S_ARP_REPLY3		= 5'd17;
	parameter S_ARP_REPLY4		= 5'd18;
	parameter S_ARP_REPLY5		= 5'd19;
	parameter S_ARP_REPLY6		= 5'd20;
	parameter S_ARP_REPLY7		= 5'd21;
	parameter S_ARP_REPLY8		= 5'd22;
	parameter S_ARP_REPLY9		= 5'd23;
	parameter S_ARP_REPLY10		= 5'd24;
	parameter S_ARP_REPLY11		= 5'd25;
	parameter S_ARP_REPLY12		= 5'd26;
	parameter S_ARP_EMPTY_READ	= 5'd27;
	parameter S_ARP_END			= 5'd28;
	parameter S_ARP_CACHE0		= 5'd29;

	reg			ArpRead;
	reg [15:0]	ArpLength;
	reg [1:0]	ArpOpcode;
	reg [47:0]	ArpSrcMac;
	reg [47:0]	ArpDataSrcMac, ArpDataDstMac;
	reg [31:0]	ArpDataSrcIP, ArpDataDstIP;
	reg			ArpTxWe, ArpTxStart, ArpTxEnd;
	reg [31:0]	ArpTxData;

	// ARP Cache
	reg [4:0]	ArpCacheState;

	parameter S_ARPC_IDLE		= 5'd0;
	parameter S_ARPC_WAIT		= 5'd13;
	parameter S_ARPC_CACHE0		= 5'd14;
	parameter S_ARPC_CACHE1		= 5'd15;
	parameter S_ARPC_CACHE2		= 5'd16;
	parameter S_ARPC_CACHE3		= 5'd17;
	parameter S_ARPC_CACHE4		= 5'd18;
	parameter S_ARPC_CACHE5		= 5'd19;
	parameter S_ARPC_CACHE6		= 5'd20;
	parameter S_ARPC_CACHE7		= 5'd21;
	parameter S_ARPC_CACHE8		= 5'd22;
	parameter S_ARPC_CACHE9		= 5'd23;
	parameter S_ARPC_CACHE10	= 5'd24;
	parameter S_ARPC_CACHE11	= 5'd25;
	parameter S_ARPC_CACHE12	= 5'd26;
	parameter S_ARPC_END		= 5'd28;

	reg			ArpCacheTxWe, ArpCacheTxStart, ArpCacheTxEnd;
	reg [31:0]	ArpCacheTxData;
	reg			ArpCacheValid;
	reg [47:0]	ArpCacheMacAddress;

	// ICMP
	reg [4:0]	IcmpState;

	parameter S_ICMP_IDLE		= 5'd0;
	parameter S_ICMP_MAC1		= 5'd1;
	parameter S_ICMP_MAC2		= 5'd2;
	parameter S_ICMP_MAC3		= 5'd3;
	parameter S_ICMP_HEADER1	= 5'd4;
	parameter S_ICMP_HEADER2	= 5'd5;
	parameter S_ICMP_HEADER3	= 5'd6;
	parameter S_ICMP_IP1		= 5'd7;
	parameter S_ICMP_IP2		= 5'd8;
	parameter S_ICMP_IP3		= 5'd9;
	parameter S_ICMP_REPLY_WAIT	= 5'd10;
	parameter S_ICMP_REPLY0		= 5'd11;
	parameter S_ICMP_REPLY1		= 5'd12;
	parameter S_ICMP_REPLY2		= 5'd13;
	parameter S_ICMP_REPLY3		= 5'd14;
	parameter S_ICMP_REPLY4		= 5'd15;
	parameter S_ICMP_REPLY5		= 5'd16;
	parameter S_ICMP_REPLY6		= 5'd17;
	parameter S_ICMP_REPLY7		= 5'd18;
	parameter S_ICMP_REPLY8		= 5'd19;
	parameter S_ICMP_REPLY9		= 5'd20;
	parameter S_ICMP_REPLY10	= 5'd21;
	parameter S_ICMP_REPLY11	= 5'd22;
	parameter S_ICMP_REPLY12	= 5'd23;
	parameter S_ICMP_EMPTY_READ	= 5'd24;
	parameter S_ICMP_END		= 5'd25;

	reg			IcmpRead;
	reg [15:0]	IcmpLength;
	reg [1:0]	IcmpByte;
	reg [47:0]	IcmpSrcMac;
	reg [31:0]	IcmpDataSrcIP, IcmpDataDstIP;
	reg			IcmpTxWe, IcmpTxStart, IcmpTxEnd;
	reg [31:0]	IcmpTxData;

	// Status
	// TCPCheckSumOKReg[4], ICMPCheckSumOKReg[4], IPCheckSumOK, TypeUDP, TypeTCP, TypeICMP, TypeARP, TypeIPv4
	// 3'd0, TooShort, TooLong,  ErroRST_NatusDrop, ErroRST_NatusCrc, ErroRST_NatusValid

	assign ExtensionPickup = (RX_BUFF_VALID == 1'b1) & (RX_BUFF_STATUS[2:0] == 3'd0) &
							 ((RX_BUFF_STATUS[8] == 1'b1 & RX_BUFF_STATUS[10] == 1'b1) |
							 (RX_BUFF_STATUS[9] == 1'd1));

	always @(posedge CLK or negedge RST_N) begin
		if(!RST_N) begin
			RxState	<= S_RX_IDLE;
		end else begin
			case(RxState)
				S_RX_IDLE: begin
					if(ARPC_REQUEST) begin
						RxState	<= S_RX_ARPC;
					end else if(ExtensionPickup) begin
						if(RX_BUFF_STATUS[9] == 1'b1)	RxState <= S_RX_ARP;
						else							RxState <= S_RX_ICMP;
					end
				end
				S_RX_ARP: begin
					if(ArpState == S_ARP_END)		RxState <= S_RX_IDLE;
				end
				S_RX_ICMP: begin
					if(IcmpState == S_ICMP_END)		RxState <= S_RX_IDLE;
				end
				S_RX_ARPC: begin
					if(ArpCacheState == S_ARPC_END)	RxState <= S_RX_IDLE;
				end
			endcase
		end
	end

	// ARP Control State
	always @(posedge CLK or negedge RST_N) begin
		if(!RST_N) begin
			ArpState			<= S_ARP_IDLE;
			ArpLength			<= 16'd0;
			ArpOpcode			<= 2'd0;
			ArpRead				<= 1'b0;
			ArpTxWe				<= 1'b0;
			ArpTxStart			<= 1'b0;
			ArpTxEnd			<= 1'b0;
			ArpTxData			<= 32'd0;
			ArpCacheMacAddress	<= 48'd0;
		end else begin
			case(ArpState)
				S_ARP_IDLE: begin
					if(RxState == S_RX_ARP & !RX_BUFF_EMPTY) begin
						ArpState	<= S_ARP_MAC1;
						ArpLength	<= RX_BUFF_LENGTH -4;
						ArpRead		<= 1'b1;
					end
					ArpTxWe		<= 1'b0;
					ArpTxStart	<= 1'b0;
					ArpTxEnd	<= 1'b0;
					ArpTxData	<= 32'd0;
				end
				S_ARP_MAC1: begin
					if(!RX_BUFF_EMPTY) begin
						ArpState	<= S_ARP_MAC2;
						ArpRead		<= 1'b1;
						ArpLength	<= ArpLength -4;
					end else begin
						ArpState	<= S_ARP_END;
						ArpRead		<= 1'b0;
					end
				end
				S_ARP_MAC2: begin
					if(!RX_BUFF_EMPTY) begin
						ArpState	<= S_ARP_MAC3;
						ArpRead		<= 1'b1;
						ArpLength	<= ArpLength -4;
					end else begin
						ArpState	<= S_ARP_END;
						ArpRead		<= 1'b0;
					end
					ArpSrcMac[15:0]	<= RX_BUFF_DATA[31:16];	// Get Source Mac Address
				end
				S_ARP_MAC3: begin
					if(!RX_BUFF_EMPTY) begin
						ArpState	<= S_ARP_TYPE;
						ArpRead		<= 1'b1;
						ArpLength	<= ArpLength -4;
					end else begin
						ArpState	<= S_ARP_END;
						ArpRead		<= 1'b0;
					end
					ArpSrcMac[47:16]	<= RX_BUFF_DATA[31:0];	// Get Source Mac Address
				end
				S_ARP_TYPE: begin
					if(!RX_BUFF_EMPTY) begin
						if(RX_BUFF_DATA[31:16] == 16'h0100)	ArpState <= S_ARP_PROTOCOL;
						else								ArpState <= S_ARP_EMPTY_READ;
						ArpRead		<= 1'b1;
						ArpLength	<= ArpLength -4;
					end else begin
						ArpState	<= S_ARP_END;
						ArpRead		<= 1'b0;
					end
				end
				S_ARP_PROTOCOL: begin
					if(!RX_BUFF_EMPTY) begin
						if(RX_BUFF_DATA[15:0] == 16'h0008)	ArpState <= S_ARP_OPERATION;
						else								ArpState <= S_ARP_EMPTY_READ;
						ArpRead		<= 1'b1;
						ArpLength	<= ArpLength -4;
					end else begin
						ArpState	<= S_ARP_END;
						ArpRead		<= 1'b0;
					end
				end
				S_ARP_OPERATION: begin
					if(!RX_BUFF_EMPTY) begin
						if(RX_BUFF_DATA[15:0] == 16'h0100)		  ArpOpcode <= 2'b10;
						else if(RX_BUFF_DATA[15:0] == 16'h0200)	 ArpOpcode <= 2'b11;
						else										  ArpOpcode <= 2'b00;
						ArpState	<= S_ARP_DATA1;
						ArpRead		<= 1'b1;
						ArpLength	<= ArpLength -4;
					end else begin
						ArpState	<= S_ARP_END;
						ArpRead		<= 1'b0;
					end
					ArpDataSrcMac[15:0] <= RX_BUFF_DATA[31:16];
				end
				S_ARP_DATA1: begin
					if(!RX_BUFF_EMPTY) begin
						ArpState	<= S_ARP_DATA2;
						ArpRead		<= 1'b1;
						ArpLength	<= ArpLength -4;
					end else begin
						ArpState <= S_ARP_END;
						ArpRead		<= 1'b0;
					end
					ArpDataSrcMac[47:16] <= RX_BUFF_DATA;
				end
				S_ARP_DATA2: begin
					if(!RX_BUFF_EMPTY) begin
						ArpState	<= S_ARP_DATA3;
						ArpRead		<= 1'b1;
						ArpLength	<= ArpLength -4;
					end else begin
						ArpState	<= S_ARP_END;
						ArpRead		<= 1'b0;
					end
					ArpDataSrcIP	<= RX_BUFF_DATA;
				end
				S_ARP_DATA3: begin
					if(!RX_BUFF_EMPTY) begin
						ArpState	<= S_ARP_DATA4;
						ArpRead		<= 1'b1;
						ArpLength	<= ArpLength -4;
					end else begin
						ArpState	<= S_ARP_END;
						ArpRead		<= 1'b0;
					end
					ArpDataDstMac[31:0] <= RX_BUFF_DATA;
				end
				S_ARP_DATA4: begin
					if(!RX_BUFF_EMPTY) begin
						ArpState	<= S_ARP_DATA5;
						ArpRead		<= 1'b1;
						ArpLength	<= ArpLength -4;
					end else begin
						ArpState	<= S_ARP_END;
						ArpRead		<= 1'b0;
					end
					ArpDataDstMac[47:32]	<= RX_BUFF_DATA[15:0];
					ArpDataDstIP[15:0]		<= RX_BUFF_DATA[31:16];
				end
				S_ARP_DATA5: begin
					if(!RX_BUFF_EMPTY) begin
						ArpState	<= S_ARP_CHECK;
						ArpRead		<= 1'b1;
						ArpLength	<= ArpLength -4;
					end else begin
						ArpState	<= S_ARP_END;
						ArpRead		<= 1'b0;
					end
					ArpDataDstIP[31:16]	<= RX_BUFF_DATA[15:0];
				end
				S_ARP_CHECK: begin
					ArpRead <= 1'b0;
					if((ArpDataDstIP == IP_ADDRESS)) begin
					   if(ArpOpcode == 2'b10) begin
							ArpState	<= S_ARP_REPLY_WAIT;
					   end else if(ArpOpcode == 2'b11) begin
						ArpState	<= S_ARP_CACHE0;
					   end else begin
						ArpState	<= S_ARP_EMPTY_READ;
					   end
					end else begin
						ArpState	<= S_ARP_EMPTY_READ;
					end
				end
				S_ARP_REPLY_WAIT: begin
					if(TX_BUFF_READY) begin
						ArpState	<= S_ARP_REPLY0;
					end
				end
				S_ARP_REPLY0: begin
					if(!TX_BUFF_FULL) begin
						ArpState	<= S_ARP_REPLY1;
						ArpTxWe		<= 1'b1;
						ArpTxStart	<= 1'b1;
						ArpTxEnd	<= 1'b0;
						ArpTxData	<= 32'h002A0000;
					end else begin
						ArpTxWe		<= 1'b0;
						ArpTxStart	<= 1'b0;
						ArpTxEnd	<= 1'b0;
					end
				end
				S_ARP_REPLY1: begin
					if(!TX_BUFF_FULL) begin
						ArpState	<= S_ARP_REPLY2;
						ArpTxWe		<= 1'b1;
						ArpTxStart	<= 1'b0;
						ArpTxEnd	<= 1'b0;
						ArpTxData	<= ArpSrcMac[31:0];
					end else begin
						ArpTxWe		<= 1'b0;
						ArpTxStart	<= 1'b0;
						ArpTxEnd	<= 1'b0;
					end
				end
				S_ARP_REPLY2: begin
					if(!TX_BUFF_FULL) begin
						ArpState	<= S_ARP_REPLY3;
						ArpTxWe		<= 1'b1;
						ArpTxStart	<= 1'b0;
						ArpTxEnd	<= 1'b0;
						ArpTxData	<= {MAC_ADDRESS[15:0], ArpSrcMac[47:32]};
					end else begin
						ArpTxWe		<= 1'b0;
						ArpTxStart	<= 1'b0;
						ArpTxEnd	<= 1'b0;
					end
				end
				S_ARP_REPLY3: begin
					if(!TX_BUFF_FULL) begin
						ArpState	<= S_ARP_REPLY4;
						ArpTxWe		<= 1'b1;
						ArpTxStart	<= 1'b0;
						ArpTxEnd	<= 1'b0;
						ArpTxData	<= MAC_ADDRESS[47:16];
					end else begin
						ArpTxWe		<= 1'b0;
						ArpTxStart	<= 1'b0;
						ArpTxEnd	<= 1'b0;
					end
				end
				S_ARP_REPLY4: begin
					if(!TX_BUFF_FULL) begin
						ArpState	<= S_ARP_REPLY5;
						ArpTxWe		<= 1'b1;
						ArpTxStart	<= 1'b0;
						ArpTxEnd	<= 1'b0;
						ArpTxData	<= 32'h01000608;	// Hardware Type(16) & Ethernet Type(16)
					end else begin
						ArpTxWe		<= 1'b0;
						ArpTxStart	<= 1'b0;
						ArpTxEnd	<= 1'b0;
					end
				end
				S_ARP_REPLY5: begin
					if(!TX_BUFF_FULL) begin
						ArpState	<= S_ARP_REPLY6;
						ArpTxWe		<= 1'b1;
						ArpTxStart	<= 1'b0;
						ArpTxEnd	<= 1'b0;
						ArpTxData	<= 32'h04060008;	// Plen(8), Hlen(8), Protocol(16)
					end else begin
						ArpTxWe		<= 1'b0;
						ArpTxStart	<= 1'b0;
						ArpTxEnd	<= 1'b0;
					end
				end
				S_ARP_REPLY6: begin
					if(!TX_BUFF_FULL) begin
						ArpState	<= S_ARP_REPLY7;
						ArpTxWe		<= 1'b1;
						ArpTxStart	<= 1'b0;
						ArpTxEnd	<= 1'b0;
						//ArpTxData <= {ArpDataDstMac[15:0], 16'h0200};	// Opcode
						ArpTxData	<= {MAC_ADDRESS[15:0], 16'h0200};	// Opcode
					end else begin
						ArpTxWe		<= 1'b0;
						ArpTxStart	<= 1'b0;
						ArpTxEnd	<= 1'b0;
					end
				end
				S_ARP_REPLY7: begin
					if(!TX_BUFF_FULL) begin
						ArpState	<= S_ARP_REPLY8;
						ArpTxWe		<= 1'b1;
						ArpTxStart	<= 1'b0;
						ArpTxEnd	<= 1'b0;
						//ArpTxData <= ArpDataDstMac[47:16];
						ArpTxData	<= MAC_ADDRESS[47:16];
					end else begin
						ArpTxWe		<= 1'b0;
						ArpTxStart	<= 1'b0;
						ArpTxEnd	<= 1'b0;
					end
				end
				S_ARP_REPLY8: begin
					if(!TX_BUFF_FULL) begin
						ArpState	<= S_ARP_REPLY9;
						ArpTxWe		<= 1'b1;
						ArpTxStart	<= 1'b0;
						ArpTxEnd	<= 1'b0;
						ArpTxData	<= ArpDataDstIP;
					end else begin
						ArpTxWe		<= 1'b0;
						ArpTxStart	<= 1'b0;
						ArpTxEnd	<= 1'b0;
					end
				end
				S_ARP_REPLY9: begin
					if(!TX_BUFF_FULL) begin
						ArpState	<= S_ARP_REPLY10;
						ArpTxWe		<= 1'b1;
						ArpTxStart	<= 1'b0;
						ArpTxEnd	<= 1'b0;
						ArpTxData	<= ArpDataSrcMac[31:0];
					end else begin
						ArpTxWe		<= 1'b0;
						ArpTxStart	<= 1'b0;
						ArpTxEnd	<= 1'b0;
					end
				end
				S_ARP_REPLY10: begin
					if(!TX_BUFF_FULL) begin
						ArpState	<= S_ARP_REPLY11;
						ArpTxWe		<= 1'b1;
						ArpTxStart	<= 1'b0;
						ArpTxEnd	<= 1'b0;
						ArpTxData	<= {ArpDataSrcIP[15:0], ArpDataSrcMac[47:32]};
					end else begin
						ArpTxWe		<= 1'b0;
						ArpTxStart	<= 1'b0;
						ArpTxEnd	<= 1'b0;
					end
				end
				S_ARP_REPLY11: begin
					if(!TX_BUFF_FULL) begin
						ArpState	<= S_ARP_EMPTY_READ;
						ArpTxWe		<= 1'b1;
						ArpTxStart	<= 1'b0;
						ArpTxEnd	<= 1'b1;
						ArpTxData	<= {16'h0000, ArpDataSrcIP[31:16]};
					end else begin
						ArpTxWe		<= 1'b0;
						ArpTxStart	<= 1'b0;
						ArpTxEnd	<= 1'b0;
					end
				end
				S_ARP_CACHE0: begin
						ArpState			<= S_ARP_EMPTY_READ;
						ArpCacheMacAddress	<= ArpDataSrcMac;
				end
				S_ARP_EMPTY_READ: begin
					ArpRead	<= 1'b1;
					if(RX_BUFF_LENGTH <= 4) begin
						ArpState	<= S_ARP_END;
					end
/*
					if(ArpLength >0 & ArpLength[15] == 1'b0) begin
						ArpRead <= 1'b1;
						ArpLength <= ArpLength -4;
					end else begin
						ArpState <= S_ARP_LAST;
						ArpRead <= 1'b0;
					end
*/
					ArpTxWe		<= 1'b0;
					ArpTxStart	<= 1'b0;
					ArpTxEnd	<= 1'b0;
					ArpTxData	<= 32'd0;
				end
				S_ARP_END: begin
					ArpState	<= S_ARP_IDLE;
					ArpRead		<= 1'b0;
					ArpTxWe		<= 1'b0;
					ArpTxStart	<= 1'b0;
					ArpTxEnd	<= 1'b0;
					ArpTxData	<= 32'd0;
				end
			endcase
		end
	end

	// ARP Cache Control State
	always @(posedge CLK or negedge RST_N) begin
		if(!RST_N) begin
			ArpCacheState		<= S_ARPC_IDLE;
			ArpCacheTxWe		<= 1'b0;
			ArpCacheTxStart		<= 1'b0;
			ArpCacheTxEnd		<= 1'b0;
			ArpCacheTxData		<= 32'd0;
		end else begin
			case(ArpCacheState)
				S_ARPC_IDLE: begin
					if(RxState == S_RX_ARPC) begin
						ArpCacheState	<= S_ARPC_WAIT;
					end
					ArpCacheTxWe	<= 1'b0;
					ArpCacheTxStart	<= 1'b0;
					ArpCacheTxEnd	<= 1'b0;
					ArpCacheTxData	<= 32'd0;
				end
				S_ARPC_WAIT: begin
					if(TX_BUFF_READY) begin
						ArpCacheState <= S_ARPC_CACHE0;
					end
				end
				S_ARPC_CACHE0: begin
					if(!TX_BUFF_FULL) begin
						ArpCacheState	<= S_ARPC_CACHE1;
						ArpCacheTxWe	<= 1'b1;
						ArpCacheTxStart	<= 1'b1;
						ArpCacheTxEnd	<= 1'b0;
						ArpCacheTxData	<= 32'h002A0000;
					end else begin
						ArpCacheTxWe	<= 1'b0;
						ArpCacheTxStart	<= 1'b0;
						ArpCacheTxEnd	<= 1'b0;
					end
				end
				S_ARPC_CACHE1: begin
					if(!TX_BUFF_FULL) begin
						ArpCacheState	<= S_ARPC_CACHE2;
						ArpCacheTxWe	<= 1'b1;
						ArpCacheTxStart	<= 1'b0;
						ArpCacheTxEnd	<= 1'b0;
						ArpCacheTxData	<= 32'hFFFF_FFFF; // Dst Address = Broadcast
					end else begin
						ArpCacheTxWe	<= 1'b0;
						ArpCacheTxStart	<= 1'b0;
						ArpCacheTxEnd	<= 1'b0;
					end
				end
				S_ARPC_CACHE2: begin
					if(!TX_BUFF_FULL) begin
						ArpCacheState	<= S_ARPC_CACHE3;
						ArpCacheTxWe	<= 1'b1;
						ArpCacheTxStart	<= 1'b0;
						ArpCacheTxEnd	<= 1'b0;
						ArpCacheTxData	<= {MAC_ADDRESS[15:0], 16'hFFFF}; // Dst Address = Broadcast
					end else begin
						ArpCacheTxWe	<= 1'b0;
						ArpCacheTxStart	<= 1'b0;
						ArpCacheTxEnd	<= 1'b0;
					end
				end
				S_ARPC_CACHE3: begin
					if(!TX_BUFF_FULL) begin
						ArpCacheState	<= S_ARPC_CACHE4;
						ArpCacheTxWe	<= 1'b1;
						ArpCacheTxStart	<= 1'b0;
						ArpCacheTxEnd	<= 1'b0;
						ArpCacheTxData	<= MAC_ADDRESS[47:16];
					end else begin
						ArpCacheTxWe	<= 1'b0;
						ArpCacheTxStart	<= 1'b0;
						ArpCacheTxEnd	<= 1'b0;
					end
				end
				S_ARPC_CACHE4: begin
					if(!TX_BUFF_FULL) begin
						ArpCacheState	<= S_ARPC_CACHE5;
						ArpCacheTxWe	<= 1'b1;
						ArpCacheTxStart	<= 1'b0;
						ArpCacheTxEnd	<= 1'b0;
						ArpCacheTxData	<= 32'h01000608;  // Hardware Type(16) & Ethernet Type(16)
					end else begin
						ArpCacheTxWe	<= 1'b0;
						ArpCacheTxStart	<= 1'b0;
						ArpCacheTxEnd	<= 1'b0;
					end
				end
				S_ARPC_CACHE5: begin
					if(!TX_BUFF_FULL) begin
						ArpCacheState	<= S_ARPC_CACHE6;
						ArpCacheTxWe	<= 1'b1;
						ArpCacheTxStart	<= 1'b0;
						ArpCacheTxEnd	<= 1'b0;
						ArpCacheTxData	<= 32'h04060008;  // Plen(8), Hlen(8), Protocol(16)
					end else begin
						ArpCacheTxWe	<= 1'b0;
						ArpCacheTxStart	<= 1'b0;
						ArpCacheTxEnd	<= 1'b0;
					end
				end
				S_ARPC_CACHE6: begin
					if(!TX_BUFF_FULL) begin
						ArpCacheState	<= S_ARPC_CACHE7;
						ArpCacheTxWe	<= 1'b1;
						ArpCacheTxStart	<= 1'b0;
						ArpCacheTxEnd	<= 1'b0;
						ArpCacheTxData	<= {MAC_ADDRESS[15:0], 16'h0100};   // Dst Mac Address = None Mac Address, Opcode(ARP Request = 0x0100)
					end else begin
						ArpCacheTxWe	<= 1'b0;
						ArpCacheTxStart	<= 1'b0;
						ArpCacheTxEnd	<= 1'b0;
					end
				end
				S_ARPC_CACHE7: begin
					if(!TX_BUFF_FULL) begin
						ArpCacheState	<= S_ARPC_CACHE8;
						ArpCacheTxWe	<= 1'b1;
						ArpCacheTxStart	<= 1'b0;
						ArpCacheTxEnd	<= 1'b0;
						ArpCacheTxData	<= MAC_ADDRESS[47:16]; // Dst Mac Address = None Mac Address
					end else begin
						ArpCacheTxWe	<= 1'b0;
						ArpCacheTxStart	<= 1'b0;
						ArpCacheTxEnd	<= 1'b0;
					end
				end
				S_ARPC_CACHE8: begin
					if(!TX_BUFF_FULL) begin
						ArpCacheState	<= S_ARPC_CACHE9;
						ArpCacheTxWe	<= 1'b1;
						ArpCacheTxStart	<= 1'b0;
						ArpCacheTxEnd	<= 1'b0;
						ArpCacheTxData	<= IP_ADDRESS;   // Dst IP Address
					end else begin
						ArpCacheTxWe	<= 1'b0;
						ArpCacheTxStart	<= 1'b0;
						ArpCacheTxEnd	<= 1'b0;
					end
				end
				S_ARPC_CACHE9: begin
					if(!TX_BUFF_FULL) begin
						ArpCacheState	<= S_ARPC_CACHE10;
						ArpCacheTxWe	<= 1'b1;
						ArpCacheTxStart	<= 1'b0;
						ArpCacheTxEnd	<= 1'b0;
						ArpCacheTxData	<= 32'h0000_0000;
					end else begin
						ArpCacheTxWe	<= 1'b0;
						ArpCacheTxStart	<= 1'b0;
						ArpCacheTxEnd	<= 1'b0;
					end
				end
				S_ARPC_CACHE10: begin
					if(!TX_BUFF_FULL) begin
						ArpCacheState	<= S_ARPC_CACHE11;
						ArpCacheTxWe	<= 1'b1;
						ArpCacheTxStart	<= 1'b0;
						ArpCacheTxEnd	<= 1'b0;
						ArpCacheTxData	<= {ARPC_IP_ADDRESS[15:0], 16'h0000};
					end else begin
						ArpCacheTxWe	<= 1'b0;
						ArpCacheTxStart	<= 1'b0;
						ArpCacheTxEnd	<= 1'b0;
					end
				end
				S_ARPC_CACHE11: begin
					if(!TX_BUFF_FULL) begin
						ArpCacheState	<= S_ARPC_END;
						ArpCacheTxWe	<= 1'b1;
						ArpCacheTxStart	<= 1'b0;
						ArpCacheTxEnd	<= 1'b1;
						ArpCacheTxData	<= {16'h0000, ARPC_IP_ADDRESS[31:16]};
					end else begin
						ArpCacheTxWe	<= 1'b0;
						ArpCacheTxStart	<= 1'b0;
						ArpCacheTxEnd	<= 1'b0;
					end
				end
				S_ARPC_END: begin
					ArpCacheState	<= S_ARP_IDLE;
					ArpCacheTxWe	<= 1'b0;
					ArpCacheTxStart	<= 1'b0;
					ArpCacheTxEnd	<= 1'b0;
					ArpCacheTxData	<= 32'd0;
				end
			endcase
		end
	end

	always @(posedge CLK or negedge RST_N) begin
		if(!RST_N) begin
			ArpCacheValid <= 1'b0;
		end else begin
			if(ArpCacheState == S_ARPC_WAIT)	ArpCacheValid <= 1'b0;
			else if(ArpState == S_ARP_CACHE0)	ArpCacheValid <= 1'b1;
		end
	end

	// ICMP
	always @(posedge CLK or negedge RST_N) begin
		if(!RST_N) begin
			IcmpState	<= S_ICMP_IDLE;
			IcmpLength	<= 16'd0;
			IcmpRead	<= 1'b0;
			IcmpTxWe	<= 1'b0;
			IcmpTxStart	<= 1'b0;
			IcmpTxEnd	<= 1'b0;
			IcmpTxData	<= 32'd0;
			IcmpByte	<= 2'd0;
		end else begin
			case(IcmpState)
				S_ICMP_IDLE: begin
					if(RxState == S_RX_ICMP & !RX_BUFF_EMPTY) begin
						IcmpState	<= S_ICMP_MAC1;
						IcmpLength	<= RX_BUFF_LENGTH -4;
						IcmpRead	<= 1'b1;
					end
					IcmpTxWe	<= 1'b0;
					IcmpTxStart	<= 1'b0;
					IcmpTxEnd	<= 1'b0;
					IcmpTxData	<= 32'd0;
				end
				S_ICMP_MAC1: begin
					if(!RX_BUFF_EMPTY) begin
						IcmpState	<= S_ICMP_MAC2;
						IcmpRead	<= 1'b1;
						IcmpLength	<= IcmpLength -4;
						IcmpByte	<= IcmpLength[1:0];
					end else begin
						IcmpState	<= S_ICMP_END;
						IcmpRead	<= 1'b0;
					end
				end
				S_ICMP_MAC2: begin
					if(!RX_BUFF_EMPTY) begin
						IcmpState	<= S_ICMP_MAC3;
						IcmpRead	<= 1'b1;
						IcmpLength	<= IcmpLength -4;
					end else begin
						IcmpState	<= S_ICMP_END;
						IcmpRead	<= 1'b0;
					end
					IcmpSrcMac[15:0]	<= RX_BUFF_DATA[31:16];	// Get Source Mac Address
				end
				S_ICMP_MAC3: begin
					if(!RX_BUFF_EMPTY) begin
						IcmpState	<= S_ICMP_HEADER1;
						IcmpRead	<= 1'b1;
						IcmpLength	<= IcmpLength -4;
					end else begin
						IcmpState	<= S_ICMP_END;
						IcmpRead	<= 1'b0;
					end
					IcmpSrcMac[47:16]	<= RX_BUFF_DATA[31:0];	// Get Source Mac Address
				end
				S_ICMP_HEADER1: begin
					if(!RX_BUFF_EMPTY)	IcmpState <= S_ICMP_HEADER2;
					else begin
						IcmpState	<= S_ICMP_END;
						IcmpRead	<= 1'b0;
					end
				end
				S_ICMP_HEADER2: begin
					if(!RX_BUFF_EMPTY)	IcmpState <= S_ICMP_HEADER3;
					else begin
						IcmpState	<= S_ICMP_END;
						IcmpRead	<= 1'b0;
					end
					IcmpLength	<= {RX_BUFF_DATA[7:0], RX_BUFF_DATA[15:8]};
				end
				S_ICMP_HEADER3: begin
					if(!RX_BUFF_EMPTY)	IcmpState <= S_ICMP_IP1;
					else begin
						IcmpState	<= S_ICMP_END;
						IcmpRead	<= 1'b0;
					end
					IcmpLength	<= IcmpLength + 14;
				end
				S_ICMP_IP1: begin
					if(!RX_BUFF_EMPTY) begin
						IcmpState	<= S_ICMP_IP2;
						IcmpRead	<= 1'b1;
					end else begin
						IcmpState	<= S_ICMP_END;
						IcmpRead	<= 1'b0;
					end
					IcmpDataSrcIP[15:0]	<= RX_BUFF_DATA[31:16];
				end
				S_ICMP_IP2: begin
					if(!RX_BUFF_EMPTY) begin
						IcmpState	<= S_ICMP_IP3;
						IcmpRead	<= 1'b1;
					end else begin
						IcmpState	<= S_ICMP_END;
						IcmpRead	<= 1'b0;
					end
					IcmpDataSrcIP[31:16]	<= RX_BUFF_DATA[15:0];
					IcmpDataDstIP[15:0]		<= RX_BUFF_DATA[31:16];
				end
				S_ICMP_IP3: begin
					if(!RX_BUFF_EMPTY) begin
						if(RX_BUFF_DATA[31:16] == 16'h0008)	IcmpState <= S_ICMP_REPLY_WAIT;
						else								IcmpState <= S_ICMP_EMPTY_READ;
						IcmpRead	<= 1'b0;
					end else begin
						IcmpState	<= S_ICMP_END;
						IcmpRead	<= 1'b0;
					end
					IcmpDataDstIP[31:16]	<= RX_BUFF_DATA[15:0];
				end
				S_ICMP_REPLY_WAIT: begin
					if(TX_BUFF_READY) begin
						IcmpState	<= S_ICMP_REPLY0;
					end
					IcmpRead	<= 1'b0;
				end
				S_ICMP_REPLY0: begin
					if(!TX_BUFF_FULL) begin
						IcmpState	<= S_ICMP_REPLY1;
						IcmpTxWe	<= 1'b1;
						IcmpTxStart	<= 1'b1;
						IcmpTxEnd	<= 1'b0;
						IcmpTxData	<= {IcmpLength, 16'h0000};
					end else begin
						IcmpTxWe	<= 1'b0;
						IcmpTxStart	<= 1'b0;
						IcmpTxEnd	<= 1'b0;
					end
					IcmpLength	<= IcmpLength -14;
				end
				S_ICMP_REPLY1: begin
					if(!TX_BUFF_FULL) begin
						IcmpState	<= S_ICMP_REPLY2;
						IcmpTxWe	<= 1'b1;
						IcmpTxStart	<= 1'b0;
						IcmpTxEnd	<= 1'b0;
						IcmpTxData	<= IcmpSrcMac[31:0];
					end else begin
						IcmpTxWe	<= 1'b0;
						IcmpTxStart	<= 1'b0;
						IcmpTxEnd	<= 1'b0;
					end
				end
				S_ICMP_REPLY2: begin
					if(!TX_BUFF_FULL) begin
						IcmpState	<= S_ICMP_REPLY3;
						IcmpTxWe	<= 1'b1;
						IcmpTxStart	<= 1'b0;
						IcmpTxEnd	<= 1'b0;
						IcmpTxData	<= {MAC_ADDRESS[15:0], IcmpSrcMac[47:32]};
					end else begin
						IcmpTxWe	<= 1'b0;
						IcmpTxStart	<= 1'b0;
						IcmpTxEnd	<= 1'b0;
					end
				end
				S_ICMP_REPLY3: begin
					if(!TX_BUFF_FULL) begin
						IcmpState	<= S_ICMP_REPLY4;
						IcmpTxWe	<= 1'b1;
						IcmpTxStart	<= 1'b0;
						IcmpTxEnd	<= 1'b0;
						IcmpTxData	<= MAC_ADDRESS[47:16];
					end else begin
						IcmpTxWe	<= 1'b0;
						IcmpTxStart	<= 1'b0;
						IcmpTxEnd	<= 1'b0;
					end
				end
				S_ICMP_REPLY4: begin
					if(!TX_BUFF_FULL) begin
						IcmpState	<= S_ICMP_REPLY5;
						IcmpTxWe	<= 1'b1;
						IcmpTxStart	<= 1'b0;
						IcmpTxEnd	<= 1'b0;
						IcmpTxData	<= 32'h00450008;
					end else begin
						IcmpTxWe	<= 1'b0;
						IcmpTxStart	<= 1'b0;
						IcmpTxEnd	<= 1'b0;
					end
				end
				S_ICMP_REPLY5: begin
					if(!TX_BUFF_FULL) begin
						IcmpState	<= S_ICMP_REPLY6;
						IcmpTxWe	<= 1'b1;
						IcmpTxStart	<= 1'b0;
						IcmpTxEnd	<= 1'b0;
						IcmpTxData	<= {16'h0000, IcmpLength[7:0], IcmpLength[15:8]};
					end else begin
						IcmpTxWe	<= 1'b0;
						IcmpTxStart	<= 1'b0;
						IcmpTxEnd	<= 1'b0;
					end
				end
				S_ICMP_REPLY6: begin
					if(!TX_BUFF_FULL) begin
						IcmpState	<= S_ICMP_REPLY7;
						IcmpTxWe	<= 1'b1;
						IcmpTxStart	<= 1'b0;
						IcmpTxEnd	<= 1'b0;
						IcmpTxData	<= 32'h01800000;
					end else begin
						IcmpTxWe	<= 1'b0;
						IcmpTxStart	<= 1'b0;
						IcmpTxEnd	<= 1'b0;
					end
					IcmpLength	<= IcmpLength -28;
				end
				S_ICMP_REPLY7: begin
					if(!TX_BUFF_FULL) begin
						IcmpState	<= S_ICMP_REPLY8;
						IcmpTxWe	<= 1'b1;
						IcmpTxStart	<= 1'b0;
						IcmpTxEnd	<= 1'b0;
						IcmpTxData	<= {IP_ADDRESS[15:0], 16'h0000};
					end else begin
						IcmpTxWe	<= 1'b0;
						IcmpTxStart	<= 1'b0;
						IcmpTxEnd	<= 1'b0;
					end
				end
				S_ICMP_REPLY8: begin
					if(!TX_BUFF_FULL) begin
						IcmpState	<= S_ICMP_REPLY9;
						IcmpTxWe	<= 1'b1;
						IcmpTxStart	<= 1'b0;
						IcmpTxEnd	<= 1'b0;
						IcmpTxData	<= {IcmpDataSrcIP[15:0], IP_ADDRESS[31:16]};
					end else begin
						IcmpTxWe	<= 1'b0;
						IcmpTxStart	<= 1'b0;
						IcmpTxEnd	<= 1'b0;
					end
				end
				S_ICMP_REPLY9: begin
					if(!TX_BUFF_FULL) begin
						IcmpState	<= S_ICMP_REPLY10;
						IcmpTxWe	<= 1'b1;
						IcmpTxStart	<= 1'b0;
						IcmpTxEnd	<= 1'b0;
						IcmpRead	<= 1'b1;
						IcmpTxData	<= {16'h0000, IcmpDataSrcIP[31:16]};
					end else begin
						IcmpTxWe	<= 1'b0;
						IcmpTxStart	<= 1'b0;
						IcmpTxEnd	<= 1'b0;
					end
				end
				S_ICMP_REPLY10: begin
					if(!TX_BUFF_FULL) begin
						IcmpState	<= S_ICMP_REPLY11;
						IcmpTxWe	<= 1'b1;
						IcmpTxStart	<= 1'b0;
						IcmpTxEnd	<= 1'b0;
						IcmpTxData	<= {RX_BUFF_DATA[31:16], 16'h0000};
					end else begin
						IcmpTxWe	<= 1'b0;
						IcmpTxStart	<= 1'b0;
						IcmpTxEnd	<= 1'b0;
					end
				end
				S_ICMP_REPLY11: begin
					if(IcmpLength > 0 & IcmpLength[15] == 1'b0) begin
						IcmpTxWe	<= 1'b1;
						IcmpTxStart	<= 1'b0;
						IcmpTxEnd	<= 1'b0;
						IcmpTxData	<= RX_BUFF_DATA;
					end else begin
						IcmpState	<= S_ICMP_REPLY12;
						IcmpTxWe	<= 1'b1;
						IcmpTxStart	<= 1'b0;
						IcmpTxEnd	<= 1'b1;
						case(IcmpByte)
							2'b00: IcmpTxData <= RX_BUFF_DATA;
							2'b01: IcmpTxData <= {8'h00, RX_BUFF_DATA[23:0]};
							2'b10: IcmpTxData <= {16'h0000, RX_BUFF_DATA[15:0]};
							2'b11: IcmpTxData <= {24'h000000, RX_BUFF_DATA[7:0]};
						endcase
					end
					IcmpLength	<= IcmpLength -4;
				end
				S_ICMP_REPLY12: begin
//					IcmpState <= S_ICMP_END;
					IcmpState	<= S_ICMP_EMPTY_READ;
					IcmpTxWe	<= 1'b0;
					IcmpTxStart	<= 1'b0;
					IcmpTxEnd	<= 1'b0;
				end
				S_ICMP_EMPTY_READ: begin
					IcmpRead	<= 1'b1;
					if(RX_BUFF_LENGTH <= 4) begin
						IcmpState	<= S_ICMP_END;
					end
/*
					if(IcmpLength > 0 & IcmpLength[15] == 1'b0) begin
						IcmpRead <= 1'b1;
						IcmpLength <= IcmpLength - 16'd4;
					end else begin
						IcmpState <= S_ICMP_END;
						IcmpRead <= 1'b0;
					end
*/
					IcmpTxWe	<= 1'b0;
					IcmpTxStart	<= 1'b0;
					IcmpTxEnd	<= 1'b0;
					IcmpTxData	<= 32'd0;
				end
				S_ICMP_END: begin
					IcmpState	<= S_ICMP_IDLE;
					IcmpRead	<= 1'b0;
					IcmpTxWe	<= 1'b0;
					IcmpTxStart	<= 1'b0;
					IcmpTxEnd	<= 1'b0;
					IcmpTxData	<= 32'd0;
				end
			endcase
		end
	end

	reg [1:0]	last_seq;
	reg [4:0]	last_arp;
	always @(posedge CLK or negedge RST_N) begin
		if(!RST_N) begin
			last_seq <= 2'd0;
			last_arp <= 5'd0;
		end else begin
			if(RxState != S_RX_IDLE) begin
				last_seq <= RxState;
			end
			if(!((ArpState == S_ARP_IDLE) || ((ArpState == S_ARP_END)))) begin
				last_arp <= ArpState;
			end
		end
	end

	assign TX_BUFF_WE		= ETX_BUFF_WE | ArpTxWe | IcmpTxWe | ArpCacheTxWe;
	assign TX_BUFF_START	= ETX_BUFF_START | ArpTxStart | IcmpTxStart | ArpCacheTxStart;
	assign TX_BUFF_END		= ETX_BUFF_END | ArpTxEnd | IcmpTxEnd | ArpCacheTxEnd;
	assign TX_BUFF_DATA		= (ArpTxWe | IcmpTxWe | ArpCacheTxWe)?(ArpTxData | IcmpTxData | ArpCacheTxData):ETX_BUFF_DATA;
	assign ETX_BUFF_FULL	= TX_BUFF_FULL;
	assign ETX_BUFF_SPACE	= TX_BUFF_SPACE;
	assign ETX_BUFF_READY	= ((RxState == S_RX_IDLE) && (!ExtensionPickup))?TX_BUFF_READY:1'b0;

	assign RX_BUFF_RE		= ERX_BUFF_RE | ArpRead | IcmpRead;
//	assign ERX_BUFF_EMPTY	= RX_BUFF_EMPTY;
	assign ERX_BUFF_EMPTY	= ((RxState == S_RX_IDLE) && !ExtensionPickup)?RX_BUFF_EMPTY:1'b1;
	assign ERX_BUFF_VALID	= ((RxState == S_RX_IDLE) && !ExtensionPickup)?RX_BUFF_VALID:1'b0;
	assign ERX_BUFF_DATA	= RX_BUFF_DATA;
	assign ERX_BUFF_LENGTH  = RX_BUFF_LENGTH;
	assign ERX_BUFF_STATUS  = RX_BUFF_STATUS;

	assign ARPC_ENABLE		= (RxState == S_RX_IDLE);
	assign ARPC_MAC_ADDRESS	= ArpCacheMacAddress;
	assign ARPC_VALID		= ArpCacheValid;

	assign STATUS[15:11]	= 5'd0;
	assign STATUS[10:6]		= last_arp;
	assign STATUS[5:4]		= last_seq;
	assign STATUS[3]		= (IcmpState		!= S_ICMP_IDLE);
	assign STATUS[2]		= (ArpCacheState	!= S_ARPC_IDLE);
	assign STATUS[1]		= (ArpState			!= S_ARP_IDLE);
	assign STATUS[0]		= (RxState			!= S_RX_IDLE);

endmodule
