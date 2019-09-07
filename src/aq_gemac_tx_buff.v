/*
* PROJECT: AQUAXIS Giga Ethernet MAC
* ----------------------------------------------------------------------
*
* Gigabit MAC
* File: aq_gemac_tx_buff.v
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
*/
module aq_gemac_tx_buff(
	input			RST_N,

	//
	input			BUFF_CLK,
	input			BUFF_WE,
	input			BUFF_START,
	input		 	BUFF_END,
	output			BUFF_READY,
	input [31:0]	BUFF_DATA,
	output			BUFF_FULL,
	output [9:0]	BUFF_SPACE,

	//
	input			MAC_CLK,
	output			MAC_REQ,
	input			MAC_RE,
	output			MAC_EOP,
	input			MAC_FINISH,
	input			MAC_RETRY,
	output [7:0]	MAC_DATA
);
	parameter EMAC_TX_DEPTH = 10;

	reg [15:0]	MemoryH[2**EMAC_TX_DEPTH-1:0];
	reg [15:0]	MemoryL[2**EMAC_TX_DEPTH-1:0];
	reg			MemoryE[2**EMAC_TX_DEPTH-1:0];

	reg [2:0]	WriteState;

	parameter S_INIT	  = 3'd0;
	parameter S_IDLE	  = 3'd1;
	parameter S_DATA	  = 3'd2;
	parameter S_CHECKSUM1 = 3'd3;
	parameter S_CHECKSUM2 = 3'd4;
	parameter S_CHECKSUM3 = 3'd5;
	parameter S_CHECKSUM4 = 3'd6;
	parameter S_FINISH	= 3'd7;

	reg [32:0]	WriteData;
	reg [31:0]	WriteFiRST_NData;
	reg			WriteEnableH, WriteEnableL;
	reg [15:0]	WriteWord;
	reg [EMAC_TX_DEPTH-1:0]		WriteAddress, WriteStartAddress, WriteNextAddress, WriteIPAddress, WriteProtocolAddress, WriteRdAdrs, WriteRdAdrsNew, WriteRdAdrsDl;
	reg			WriteIP, WriteICMP, WriteTCP, WriteUDP;
//	reg		 WriteARP;
	reg			WriteFull;
	reg [31:0]	CheckSumIP;
	reg [31:0]	CheckSumIPH;
	reg [31:0]	CheckSumIPL;
	reg [31:0]	CheckSumTCPH;
	reg [31:0]	CheckSumTCPL;
	reg [31:0]	CheckSumProtocol;
	reg			NotIpCheckSum;

	reg [32:0]	ReadData;

	reg [1:0]	ReadState;

	parameter RS_IDLE = 2'd0;
	parameter RS_INIT = 2'd2;
	parameter RS_DATA = 2'd3;

	reg			TxReq;
	reg [1:0]	ReadCount;
	reg [EMAC_TX_DEPTH-1:0]	ReadAddress, ReadWrAdrsDl, ReadWrAdrs, ReadWrAdrsNew, ReadStartAddress, ReadWaitAddress;
	reg			ReadEmpty;
	reg [15:0]	ReadLength;

	// State Machine
	always @(posedge BUFF_CLK or negedge RST_N) begin
		if(!RST_N) begin
			WriteState <= S_INIT;
		end else begin
			if(!WriteFull) begin
				case(WriteState)
					S_INIT: begin
						WriteState <= S_IDLE;
					end
					S_IDLE: begin
						if(BUFF_WE && BUFF_START) begin
							WriteState <= S_DATA;
						end
					end
					S_DATA: begin
						if(BUFF_WE && BUFF_END) begin
							if(WriteIP) WriteState <= S_CHECKSUM1;
							else		WriteState <= S_FINISH;
						end
					end
					S_CHECKSUM1: begin
						if(NotIpCheckSum)   WriteState <= S_FINISH;
						else				WriteState <= S_CHECKSUM2;
					end
					S_CHECKSUM2: begin
						WriteState <= S_CHECKSUM3;
					end
					S_CHECKSUM3: begin
						WriteState <= S_CHECKSUM4;
					end
					S_CHECKSUM4: begin
						WriteState <= S_FINISH;
					end
					S_FINISH: begin
						WriteState <= S_INIT;
					end
				endcase
			end
		end
	end

	always @(posedge BUFF_CLK or negedge RST_N) begin
		if(!RST_N) begin
			WriteData				<= 33'd0;
			WriteFiRST_NData		<= 32'd0;
			WriteEnableH			<= 1'b0;
			WriteEnableL			<= 1'b0;
			WriteWord				<= 16'd0;
			WriteAddress			<= {EMAC_TX_DEPTH{1'b0}};
			WriteStartAddress		<= {EMAC_TX_DEPTH{1'b0}};
			WriteNextAddress		<= {EMAC_TX_DEPTH{1'b0}};
			WriteIPAddress			<= {EMAC_TX_DEPTH{1'b0}};
			WriteProtocolAddress	<= {EMAC_TX_DEPTH{1'b0}};
			WriteIP					<= 1'b0;
//			WriteARP				<= 1'b0;
			WriteICMP				<= 1'b0;
			WriteTCP				<= 1'b0;
			WriteUDP				<= 1'b0;
			WriteRdAdrsDl			<= {EMAC_TX_DEPTH{1'b0}};
			WriteRdAdrs				<= {EMAC_TX_DEPTH{1'b0}};
			WriteFull				<= 1'b0;
			CheckSumIP				<= 32'd0;
			CheckSumIPH				<= 32'd0;
			CheckSumIPL				<= 32'd0;
			CheckSumTCPH			<= 32'd0;
			CheckSumTCPL			<= 32'd0;
			CheckSumProtocol		<= 32'd0;
			NotIpCheckSum			<= 1'b0;
		end else begin
			case(WriteState)
				S_INIT: begin
					WriteData <= 33'd0;
				end
				S_IDLE, S_DATA: begin
					WriteData <= {1'b0, BUFF_DATA};
				end
				S_CHECKSUM3: begin
					WriteData <= {1'b0, CheckSumIP[15:0], CheckSumIP[15:0]};
				end
				S_CHECKSUM4: begin
					WriteData <= {1'b0, CheckSumProtocol[15:0], CheckSumProtocol[15:0]};
				end
				S_FINISH: begin
					WriteData <= {1'b1, WriteFiRST_NData};
				end
			endcase

			if(!WriteFull && WriteState == S_IDLE && BUFF_WE)	WriteFiRST_NData <= BUFF_DATA;

			if(!WriteFull && ((BUFF_WE && WriteState == S_DATA ) || (WriteState == S_CHECKSUM4 && WriteTCP) || WriteState == S_FINISH || WriteState == S_INIT))	WriteEnableH <= 1'b1;
			else																			WriteEnableH <= 1'b0;

			if(!WriteFull && ((BUFF_WE && WriteState == S_DATA ) || WriteState == S_CHECKSUM3 || (WriteState == S_CHECKSUM4 && (WriteICMP || WriteUDP)) || WriteState == S_FINISH || WriteState == S_INIT))	WriteEnableL <= 1'b1;
			else																			WriteEnableL <= 1'b0;

			if(WriteState == S_IDLE)								WriteWord <= 0;
			else if(!WriteFull && BUFF_WE && WriteState == S_DATA)	WriteWord <= WriteWord + 1;

			if(!WriteFull && BUFF_WE && WriteState == S_DATA)   WriteAddress <= WriteAddress + 1;
			else if(WriteState == S_CHECKSUM3)				  WriteAddress <= WriteIPAddress;
			else if(WriteState == S_CHECKSUM4)				  WriteAddress <= WriteProtocolAddress;
			else if(WriteState == S_FINISH)					 WriteAddress <= WriteStartAddress;
			else if(WriteState == S_INIT)					   WriteAddress <= WriteNextAddress;

			if(!WriteFull && WriteState == S_IDLE && BUFF_WE)					   WriteStartAddress <= WriteAddress;
			if(WriteState == S_CHECKSUM1 || (!WriteIP && WriteState == S_FINISH))   WriteNextAddress <= WriteAddress + 1;

			if(!WriteFull && BUFF_WE && WriteState == S_DATA && WriteWord == 16'd7) WriteIPAddress <= WriteAddress;
			if(!WriteFull && BUFF_WE && WriteState == S_DATA) begin
				if(WriteICMP && WriteWord == 16'd10)		WriteProtocolAddress <= WriteAddress;
				else if(WriteTCP && WriteWord == 16'd13)	WriteProtocolAddress <= WriteAddress;
				else if(WriteUDP && WriteWord == 16'd11)	WriteProtocolAddress <= WriteAddress;
			end

			// Detect Protocol
			if(WriteState == S_IDLE) begin
				WriteIP	 <= 1'b0;
//				WriteARP	<= 1'b0;
				WriteICMP   <= 1'b0;
				WriteTCP	<= 1'b0;
				WriteUDP	<= 1'b0;
			end else if(!WriteFull && BUFF_WE && WriteState == S_DATA) begin
				case(WriteWord)
					16'd3: begin
						if(BUFF_DATA[23:0] == 24'h450008) begin
							WriteIP <= 1'b1;
						end
					end
					16'd5: begin
						if(WriteIP) begin
							case(BUFF_DATA[31:24])
								8'h01: begin
									WriteICMP <= 1'b1;
								end
								8'h06: begin
									WriteTCP <= 1'b1;
								end
								8'h11: begin
									WriteUDP <= 1'b1;
								end
							endcase
						end
					end
				endcase
			end

			if(!WriteFull && BUFF_WE && WriteState == S_DATA) begin
				if(WriteWord == 16'd0) NotIpCheckSum <= 1'b0;
				if(WriteWord == 16'd5 & (BUFF_DATA[13] || (BUFF_DATA[12:0] != 13'd0)))	NotIpCheckSum <= 1'b1;
			end

			// CheckSum(IP+ICMP)
			if(WriteState == S_CHECKSUM1) begin
				CheckSumIP[31:0] <= {16'd0, CheckSumIP[31:16]} + {16'd0, CheckSumIP[15:0]};
			end else if(WriteState == S_CHECKSUM2) begin
				CheckSumIP[15:0] <= ~(CheckSumIP[31:16] + CheckSumIP[15:0]);
			end else if(!WriteFull && BUFF_WE && WriteState == S_DATA) begin
				case(WriteWord)
					16'd0,16'd1,16'd2: begin
						// No Operation
					end
					16'd3: begin
						CheckSumIPH <= {16'h0000,BUFF_DATA[31:16]};
						CheckSumIPL <= 32'd0;
					end
					16'd4,16'd5,16'd6,16'd7: begin
						CheckSumIPH <= CheckSumIPH + {16'h0000,BUFF_DATA[31:16]};
						CheckSumIPL <= CheckSumIPL + {16'h0000,BUFF_DATA[15: 0]};
					end
					16'd8: begin
						CheckSumIP <= CheckSumIPH;
						CheckSumIPH <= {16'h0000,BUFF_DATA[31:16]};
						CheckSumIPL <= CheckSumIPL + {16'h0000,BUFF_DATA[15: 0]};
					end
					16'd9: begin
						CheckSumIP <= CheckSumIP + CheckSumIPL;
						CheckSumIPH <= CheckSumIPH + {16'h0000,BUFF_DATA[31:16]};
						CheckSumIPL <= {16'h0000,BUFF_DATA[15:0]};
					end
					default: begin
						CheckSumIPH <= CheckSumIPH + {16'h0000,BUFF_DATA[31:16]};
						CheckSumIPL <= CheckSumIPL + {16'h0000,BUFF_DATA[15: 0]};
					end
				endcase
			end

			// ChechSum(TCP/UDP)
			if(!WriteFull && BUFF_WE && WriteState == S_DATA) begin
				case(WriteWord)
					16'd0,16'd1,16'd2,16'd3: begin
						// No Operation
					end
					16'd4: begin
						CheckSumTCPH <= 32'd0;
						CheckSumTCPL <= {16'h0000,BUFF_DATA[7:0],BUFF_DATA[15:8]} - 32'd20;
					end
					16'd5: begin
						CheckSumTCPL <= {16'h0000,CheckSumTCPL[7:0],CheckSumTCPL[15:8]};
					end
					16'd6: begin
						CheckSumTCPH <= CheckSumTCPH + {16'h0000,BUFF_DATA[31:16]};
						if(WriteTCP)	CheckSumTCPL <= CheckSumTCPL + 32'h00000600;
						else			CheckSumTCPL <= CheckSumTCPL + 32'h00001100;
					end
					default: begin
						CheckSumTCPH <= CheckSumTCPH + {16'h0000,BUFF_DATA[31:16]};
						CheckSumTCPL <= CheckSumTCPL + {16'h0000,BUFF_DATA[15: 0]};
					end
				endcase
			end

			case(WriteState)
				S_CHECKSUM1: begin
					if(WriteICMP)   CheckSumProtocol <= CheckSumIPH + CheckSumIPL;
					else			CheckSumProtocol <= CheckSumTCPH + CheckSumTCPL;
				end
				S_CHECKSUM2: begin
					CheckSumProtocol[31:0] <= {16'd0, CheckSumProtocol[31:16]} + {16'd0, CheckSumProtocol[15:0]};
				end
				S_CHECKSUM3: begin
					CheckSumProtocol[15:0] <= ~(CheckSumProtocol[31:16] + CheckSumProtocol[15:0]);
				end
			endcase

			WriteRdAdrsDl   <= ReadWaitAddress -1;
			WriteRdAdrs	 <= WriteRdAdrsDl;
			WriteRdAdrsNew  <= WriteRdAdrs;
			if(WriteAddress == WriteRdAdrs && BUFF_WE)  WriteFull <= 1'b1;
			else if(WriteRdAdrsNew != WriteRdAdrs)	  WriteFull <= 1'b0;
		end
	end

	assign BUFF_FULL	= WriteFull;
	assign BUFF_READY	= WriteState == S_IDLE;
	assign BUFF_SPACE	= (!WriteFull)?(WriteRdAdrs - WriteAddress):10'd0;

	always @(posedge BUFF_CLK) begin
		if(WriteEnableH)					MemoryH[WriteAddress] <= WriteData[31:16];
		if(WriteEnableL)					MemoryL[WriteAddress] <= WriteData[15: 0];
		if(WriteEnableH && WriteEnableL)	MemoryE[WriteAddress] <= WriteData[32];
	end

	always @(posedge MAC_CLK) begin
		ReadData[32] <= MemoryE[ReadAddress];
		ReadData[31:16] <= MemoryH[ReadAddress];
		ReadData[15:0]  <= MemoryL[ReadAddress];
	end

	always @(posedge MAC_CLK or negedge RST_N) begin
		if(!RST_N) begin
			ReadState <= RS_IDLE;
		end else begin
			case(ReadState)
				RS_IDLE: begin
					if(ReadData[32] & !ReadEmpty) ReadState <= RS_INIT;
				end
				RS_INIT: begin
					ReadState <= RS_DATA;
				end
				RS_DATA: begin
					if(MAC_FINISH || MAC_RETRY)	ReadState <= RS_IDLE;
				end
			endcase
		end
	end

	always @(posedge MAC_CLK or negedge RST_N) begin
		if(!RST_N) begin
			TxReq				<= 1'b0;
			ReadCount			<= 2'd0;
			ReadAddress			<= {EMAC_TX_DEPTH{1'b0}};
			ReadWrAdrsDl		<= {EMAC_TX_DEPTH{1'b0}};
			ReadWrAdrs			<= {EMAC_TX_DEPTH{1'b0}};
			ReadStartAddress	<= {EMAC_TX_DEPTH{1'b0}};
			ReadWaitAddress		<= {EMAC_TX_DEPTH{1'b0}};
			ReadEmpty			<= 1'b1;
			ReadLength			<= 16'd0;
		end else begin
			if(MAC_FINISH)					TxReq <= 1'b0;
			else if(ReadState == RS_INIT)	TxReq <= 1'b1;

			if(MAC_FINISH || ReadState == RS_INIT)	ReadCount <= 0;
			else if(MAC_RE)							ReadCount <= ReadCount +1;

			if(ReadState == RS_INIT)	ReadLength <= ReadData[31:16];
			else if(MAC_RE)				ReadLength <= ReadLength - 1;

			if(ReadState == RS_INIT || (MAC_FINISH && ReadCount == 2'd2) || (MAC_RE && ReadCount == 2'd2))		ReadAddress <= ReadAddress + 1;
			else if(MAC_RETRY)																					ReadAddress <= ReadStartAddress;

			if(ReadState == RS_INIT) ReadStartAddress <= ReadAddress;
			if(ReadState == RS_IDLE) ReadWaitAddress <= ReadAddress;

			ReadWrAdrsDl	<= WriteAddress -1;
			ReadWrAdrs		<= ReadWrAdrsDl;
			ReadWrAdrsNew	<= ReadWrAdrs;
			if(ReadAddress == ReadWrAdrs && MAC_RE)	ReadEmpty <= 1'b1;
			else if(ReadWrAdrs != ReadWrAdrsNew)	ReadEmpty <= 1'b0;
		end
	end

	assign MAC_REQ  = TxReq;
	assign MAC_DATA = (ReadCount == 2'd0)?ReadData[ 7: 0]:8'd0 ||
					  (ReadCount == 2'd1)?ReadData[15: 8]:8'd0 ||
					  (ReadCount == 2'd2)?ReadData[23:16]:8'd0 ||
					  (ReadCount == 2'd3)?ReadData[31:24]:8'd0;
	//assign MAC_EMPTY	= ReadEmpty;
	assign MAC_EOP  = ReadLength == 1;
endmodule

