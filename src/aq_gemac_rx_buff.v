/*
* PROJECT: AQUAXIS Giga Ethernet MAC
* ----------------------------------------------------------------------
*
* Gigabit MAC for Receive
* File: aq_gemac_rx_buff.v
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
* 2007/01/06 H.Ishihara	Create
* 2007/08/22 H.Ishihara	Modify Full & Empty
* 2011/04/24 H.Ishihara	rename
*/
module aq_gemac_rx_buff(
	input			RST_N,

	//
	input			MAC_CLK,
	input			MAC_WE,
	input			MAC_START,
	input			MAC_END,
	input [15:0]	MAC_STATUS,
	input [7:0]		MAC_DATA,
	output			MAC_FULL,

	//
	input			BUFF_CLK,
	input			BUFF_RE,
	output			BUFF_EMPTY,
	output [31:0]	BUFF_DATA,

	//
	output			FRAME_VALID,
	output [15:0]	FRAME_LENGTH,
	output [15:0]	FRAME_STATUS
);
	parameter EMAC_RX_DEPTH = 10;

	reg [32:0]	Memory	[0:2**EMAC_RX_DEPTH-1];

	reg [1:0]	WriteState;

	parameter S_INIT	= 2'd0;
	parameter S_IDLE	= 2'd1;
	parameter S_DATA	= 2'd2;
	parameter S_END		= 2'd3;

	reg [1:0]	WriteCount;
	reg [EMAC_RX_DEPTH-1:0]		WriteAddress, WriteStartAddress, WriteNextAddress;
	reg [32:0]	WriteData;
	reg			WriteEnable;
	reg [15:0]	WriteLength;
	reg [EMAC_RX_DEPTH-1:0]		WriteRdAdrsDl;
	reg [EMAC_RX_DEPTH-1:0]		WriteRdAdrs, WriteRdAdrsNew;
	reg			WriteFull;

	reg [2:0]	ReadState;

	parameter RS_IDLE  = 3'd0;
	parameter RS_INIT1 = 3'd1;
	parameter RS_INIT2 = 3'd2;
	parameter RS_INIT3 = 3'd3;
	parameter RS_DATA  = 3'd4;

	reg [32:0]	ReadData;
	reg			ReadValid;
	reg [15:0]	ReadLength;
	reg [15:0]	ReadStatus;
	reg [EMAC_RX_DEPTH-1:0]	 ReadAddress;
	reg [EMAC_RX_DEPTH-1:0]	 ReadWrAdrsDl;
	reg [EMAC_RX_DEPTH-1:0]	 ReadWrAdrs;
	reg [EMAC_RX_DEPTH-1:0]	 ReadWrAdrsNew;
	reg			ReadEmpty;
	reg [31:0]	OutData;
	reg			ReadDelay;
	reg			WriteEnableReq;
	reg			ReadWrEnableDl, ReadWrEnable;

	// Write side control
	always @(posedge MAC_CLK or negedge RST_N) begin
		if(!RST_N) begin
			WriteState <= S_INIT;
		end else begin
			if(!WriteFull) begin
				case(WriteState)
					S_INIT: begin
						WriteState <= S_IDLE;
					end
					S_IDLE: begin
						if(MAC_WE && MAC_START) begin
							WriteState <= S_DATA;
						end
					end
					S_DATA: begin
						if(MAC_END) begin
							WriteState <= S_END;
						end
					end
					S_END: begin
						WriteState <= S_INIT;
					end
				endcase
			end
		end
	end

	always @(posedge MAC_CLK or negedge RST_N) begin
		if(!RST_N) begin
			WriteCount			<= 2'd0;
			WriteAddress		<= 0;
			WriteStartAddress	<= 0;
			WriteNextAddress	<= 0;
			WriteData			<= 32'd0;
			WriteEnable			<= 1'b0;
			WriteLength			<= 16'd0;
			WriteRdAdrsDl		<= 0;
			WriteRdAdrs			<= 0;
			WriteFull			<= 1'b0;
			WriteEnableReq		<= 1'b0;
		end else begin
			if(!WriteFull && MAC_WE) begin
				if(WriteState == S_END)				 WriteCount <= 2'd0;
				if(WriteState == S_IDLE && MAC_START)   WriteCount <= 2'd1;
				else									WriteCount <= WriteCount + 2'd1;
			end

			if(!WriteFull && MAC_WE && WriteState == S_IDLE) begin
				WriteStartAddress <= WriteAddress;
			end

			case(WriteState)
				S_IDLE: begin
					WriteData[ 7: 0] <= MAC_DATA;
				end
				S_DATA: begin
					case(WriteCount)
						2'd0: WriteData[ 7: 0] <= MAC_DATA;
						2'd1: WriteData[15: 8] <= MAC_DATA;
						2'd2: WriteData[23:16] <= MAC_DATA;
						2'd3: WriteData[31:24] <= MAC_DATA;
					endcase
					WriteData[32] <= 1'b0;
				end
				S_END: begin
					WriteData[15: 0] <= MAC_STATUS;
					WriteData[31:16] <= WriteLength - 16'd3;
					WriteData[32] <= 1'b1;
				end
				S_INIT: begin
					WriteData <= 33'd0;
				end
			endcase

			if(!WriteFull && MAC_WE && ((WriteState == S_DATA && WriteCount == 2'd3) || (WriteState == S_END) || WriteState == S_INIT))		WriteEnable <= 1'b1;
			else																													WriteEnable <= 1'b0;

			if(!WriteFull && MAC_WE && WriteState == S_DATA && WriteCount == 2'd3)  WriteAddress <= WriteAddress + 1;
			else if(WriteState == S_END)											WriteAddress <= WriteStartAddress;
			else if(WriteState == S_INIT)										   WriteAddress <= WriteNextAddress;

			if(WriteState == S_END)	WriteNextAddress <= WriteAddress +1;

			// Length Counter
			if(WriteState == S_IDLE)		WriteLength <= 16'd1;
			else if(!WriteFull && MAC_WE)   WriteLength <= WriteLength + 16'd1;

			WriteRdAdrsDl   <= ReadAddress -1;
			WriteRdAdrs	 <= WriteRdAdrsDl;
			WriteRdAdrsNew  <= WriteRdAdrs;
			if(WriteAddress == WriteRdAdrs && WriteCount == 2'd3 && MAC_WE) WriteFull <= 1'b1;
			else if(WriteRdAdrsNew != WriteRdAdrs)						  WriteFull <= 1'b0;

			if(ReadWrEnable)				WriteEnableReq <= 1'b0;
			else if(WriteState == S_END)	WriteEnableReq <= 1'b1;
		end
	end

	assign MAC_FULL = WriteFull;

	// Memory
	always @(posedge MAC_CLK) begin
		if(WriteEnable) Memory[WriteAddress] <= WriteData;
	end

	always @(posedge BUFF_CLK) begin
		ReadData <= Memory[ReadAddress];
	end

	always @(posedge BUFF_CLK or negedge RST_N) begin
		if(!RST_N) begin
			ReadState <= RS_IDLE;
		end else begin
			case(ReadState)
				RS_IDLE: begin
					if(ReadData[32] & !ReadEmpty) ReadState <= RS_INIT1;
				end
				RS_INIT1: begin
					ReadState <= RS_INIT2;
				end
				RS_INIT2: begin
					ReadState <= RS_INIT3;
				end
				RS_INIT3: begin
					ReadState <= RS_DATA;
				end
				RS_DATA: begin
					if(ReadLength <= 8 && BUFF_RE) ReadState <= RS_IDLE;
				end
			endcase
		end
	end

	// Read side control
	always @(posedge BUFF_CLK or negedge RST_N) begin
		if(!RST_N) begin
			ReadValid		<= 1'b0;
			ReadLength		<= 16'd0;
			ReadStatus		<= 16'd0;
			ReadAddress		<= 0;
			ReadWrAdrsDl	<= 0;
			ReadWrAdrs		<= 0;
			ReadWrAdrsNew	<= 0;
			ReadEmpty		<= 1'b1;
			ReadDelay		<= 1'b0;
			OutData			<= 32'd0;
			ReadWrEnableDl	<= 1'b0;
			ReadWrEnable	<= 1'b0;
		end else begin
			if(ReadState == RS_INIT3) begin
				ReadValid	<= 1'b1;
			end else if(ReadState == RS_DATA && BUFF_RE) begin
				ReadValid	<= 1'b0;
			end
			if(ReadState == RS_INIT1) begin
				ReadLength	<= ReadData[31:16];
				ReadStatus	<= ReadData[15: 0];
			end else if(ReadState == RS_DATA && BUFF_RE) begin
				ReadLength	<= ReadLength -4;
			end

			if((ReadLength >= 4 && BUFF_RE && ReadState == RS_DATA) || ReadState == RS_INIT1 || ReadState == RS_INIT2)		ReadAddress <= ReadAddress + 1;

			if(ReadState == RS_INIT3 || (BUFF_RE && ReadState == RS_DATA) || (!BUFF_RE && ReadDelay))	OutData <= ReadData[31:0];
			ReadDelay		<= BUFF_RE;

			ReadWrEnableDl	<= WriteEnableReq;
			ReadWrEnable	<= ReadWrEnableDl;

			ReadWrAdrsDl	<= WriteAddress -1;
			ReadWrAdrs		<= ReadWrAdrsDl;
			ReadWrAdrsNew	<= ReadWrAdrs;
			if(ReadAddress == ReadWrAdrs && BUFF_RE)	ReadEmpty <= 1'b1;
//			else if(ReadWrAdrs != ReadWrAdrsNew)		ReadEmpty <= 1'b0;
			else if(!ReadWrEnableDl && ReadWrEnable)	ReadEmpty <= 1'b0;
		end
	end

	assign FRAME_VALID	= ReadValid;
	assign FRAME_LENGTH	= ReadLength;
	assign FRAME_STATUS	= ReadStatus;

	assign BUFF_EMPTY	= ReadEmpty;
	assign BUFF_DATA	= (ReadDelay)?ReadData[31:0]:OutData;

endmodule
