/*
* PROJECT: AQUAXIS Giga Ethernet MAC
* ----------------------------------------------------------------------
*
* Gigabit MAC
* File: aq_gemac_tX_mac.v
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
* Create 2007/06/01 H.Ishihara
*/
module aq_gemac_tx_mac(
	input			RST_N,
	input			CLK,

	//
	output [7:0]	TX_D,
	output			TX_EN,
	output			TX_ER,
	output			TX_CRS,

	//
	input			TX_REQ,
	// BUFF signals
	output			BUFF_RD,
	input			BUFF_EOP,
	output			BUFF_FINISH,
	output			BUFF_RETRY,
	//BUFF_EMPTY,	   //
	input [7:0]		BUFF_DATA,

	// From CPU
	input [15:0]	PAUSE_QUANTA_DATA,
	input			PAUSE_SEND_ENABLE,

	// From Flow Control
	input			PAUSE_APPLY,
	output			PAUSE_QUANTA_SUB,

	// Control Mode
	input [47:0]	MAC_ADDRESS,
	input			RANDOM_TIME_MEET,
	input [3:0]		MAX_RETRY,
	input			GIG_MODE,		// Giga Mode(1:Giga Mode, 0: 10/100Mbps Mode)
	input			FULL_DUPLEX		// Duplex Mode(1:Full Duplex, 0: Half Duplex)
);

	reg				RunMode;
	reg [7:0]		RegData;

	reg [3:0]		TxState;

	parameter S_DEFER				= 4'd0;
	parameter S_IFG					= 4'd1;
	parameter S_IDLE				= 4'd2;
	parameter S_PAUSE				= 4'd3;
	parameter S_PREAMBLE			= 4'd4;
	parameter S_SFD					= 4'd5;
	parameter S_SEND_PAUSE_FRAME	= 4'd6;
	parameter S_DATA				= 4'd7;
	parameter S_PADDING				= 4'd8;
	parameter S_JAM					= 4'd9;
	parameter S_BACK_OFF			= 4'd10;
	parameter S_FCS					= 4'd11;
	parameter S_BUFF_EMPTY_DROP		= 4'd12;
	parameter S_JAM_DROP			= 4'd13;
	parameter S_SWITCH_NEXT			= 4'd14;

	reg			CrcInit;
	reg			CrcEnable;
	reg			CrcRd;
	reg			BuffRdEnable;

	wire		CrcEnd;
	wire [7:0]	CrcData;

	reg [7:0]	JamCount;
	reg [3:0]	RetryCount;
	reg [5:0]	IfgCount;
	reg [15:0]	DataCount;
	reg [4:0]	PreambleCount;
	reg [7:0]	PauseCount;
	reg			MacAddressInsert;

	wire [7:0]	TxDataTemp;

	reg			TxEnable;
	reg [7:0]	TxData;

	reg			PauseQuantaSub;

	//
	always @(posedge CLK or negedge RST_N) begin
		if(!RST_N)			RunMode <= 1'b0;
		else if(!GIG_MODE)  RunMode <= ~RunMode;
		else				RunMode <= 1'b1;
	end

	always @(posedge CLK or negedge RST_N) begin
		if(!RST_N)	RegData <= 8'd0;
		else		RegData <= BUFF_DATA;
	end

	// State Machine
	always @(posedge CLK or negedge RST_N) begin
		if(!RST_N) begin
			TxState			<= S_IDLE;
			CrcInit			<= 1'b0;
			CrcEnable		<= 1'b0;
			CrcRd			<= 1'b0;
			BuffRdEnable	<= 1'b0;
		end else begin
			if(RunMode) begin
				case(TxState)
					S_DEFER: begin
						if(FULL_DUPLEX || (!FULL_DUPLEX && !TX_CRS))	TxState <= S_IFG;
					end
					S_IFG: begin
						if(!FULL_DUPLEX && TX_CRS)	TxState <= S_DEFER;
						else if((FULL_DUPLEX || (!FULL_DUPLEX && !TX_CRS)) && IfgCount == 11)	TxState <= S_IDLE;
					end
					S_IDLE: begin
						if(!FULL_DUPLEX && TX_CRS)  TxState <= S_DEFER;
						else if(PAUSE_APPLY)		TxState <= S_PAUSE;
						else if(((FULL_DUPLEX || (!FULL_DUPLEX && !TX_CRS)) && TX_REQ) || PAUSE_SEND_ENABLE )	TxState <= S_PREAMBLE;
					end
					S_PAUSE: begin
						if(PauseCount == 64)	TxState <= S_DEFER;
					end
					S_PREAMBLE: begin
						if(!FULL_DUPLEX && TX_CRS)	TxState <= S_JAM;
						else if((FULL_DUPLEX || (!FULL_DUPLEX && !TX_CRS)) && PreambleCount == 6)	TxState <= S_SFD;
						CrcInit <= 1'b1;
					end
					S_SFD: begin
						if(!FULL_DUPLEX && TX_CRS) begin
							TxState		 <= S_JAM;
						end else if(PAUSE_SEND_ENABLE) begin
							TxState		 <= S_SEND_PAUSE_FRAME;
							CrcEnable	   <= 1'b1;
						end else begin
							TxState		 <= S_DATA;
							CrcEnable	   <= 1'b1;
							BuffRdEnable	<= 1'b1;
						end
						CrcInit <= 1'b0;
					end
					S_SEND_PAUSE_FRAME: begin
						if(DataCount == 17)	TxState <= S_PADDING;
					end
					S_DATA: begin
						BuffRdEnable	<= 1'b1;
						if(!FULL_DUPLEX && TX_CRS) begin
							TxState <= S_JAM;
						//end else if(BUFF_EMPTY) begin
						//	TxState <= S_BUFF_EMPTY_DROP;
						end else if(BUFF_EOP && DataCount >= 59) begin
							TxState	 <= S_FCS;
							CrcEnable   <= 1'b0;
							CrcRd	   <= 1'b1;
						end else if(BUFF_EOP) begin
							TxState <= S_PADDING;
						end
					end
					S_PADDING: begin
						BuffRdEnable	<= 1'b0;
						if(!FULL_DUPLEX && TX_CRS) begin
							TxState <= S_JAM;
						end else if(DataCount >= 59) begin
							TxState	  <= S_FCS;
							CrcEnable	<= 1'b0;
							CrcRd		<= 1'b1;
						end
					end
					S_JAM: begin
						BuffRdEnable	<= 1'b0;
						if(RetryCount   <= MAX_RETRY && JamCount == 16)	TxState <= S_BACK_OFF;
						else if(RetryCount > MAX_RETRY)		TxState <= S_JAM_DROP;
					end
					S_BACK_OFF: begin
						BuffRdEnable	<= 1'b0;
						if(RANDOM_TIME_MEET)	TxState <= S_DEFER;
					end
					S_FCS: begin
						BuffRdEnable	<= 1'b0;
						if(!FULL_DUPLEX && TX_CRS) begin
							TxState		<= S_JAM;
							CrcRd	   <= 1'b0;
						end else if(CrcEnd) begin
							TxState		<= S_SWITCH_NEXT;
							CrcRd	   <= 1'b0;
						end
					end
					S_BUFF_EMPTY_DROP: begin
						BuffRdEnable	<= 1'b0;
						if(BUFF_EOP)	TxState <= S_SWITCH_NEXT;
					end
					S_JAM_DROP: begin
						BuffRdEnable	<= 1'b0;
						if(BUFF_EOP)	TxState <= S_SWITCH_NEXT;
					end
					S_SWITCH_NEXT:	TxState <= S_DEFER;
				endcase
			end
		end
	end

	assign BUFF_RD	  = BuffRdEnable & RunMode;
	assign BUFF_RETRY   = TxState == S_JAM;
	assign BUFF_FINISH  = TxState == S_DEFER;

	// Counters
	always @(posedge CLK or negedge RST_N) begin
		if(!RST_N) begin
			JamCount			<= 8'h00;
			RetryCount			<= 4'h0;
			IfgCount			<= 6'd0;
			DataCount			<= 16'd0;
			PreambleCount		<= 5'd0;
			PauseCount			<= 8'd0;
			MacAddressInsert	<= 1'b0;
		end else if(RunMode) begin
			if(TxState == S_JAM)	JamCount <= JamCount + 8'h01;
			else					JamCount <= 8'h00;

			if(TxState == S_JAM && JamCount == 16)		RetryCount <= RetryCount + 4'h1;
			else if(TxState == S_SWITCH_NEXT)			RetryCount <= 4'h0;

			if(TxState == S_IFG)	IfgCount <= IfgCount + 6'd1;
			else					IfgCount <= 6'd0;

			if(TxState == S_DATA || TxState == S_SEND_PAUSE_FRAME || TxState == S_PADDING)	DataCount <= DataCount + 16'd1;
			else						DataCount <= 16'd0;

			if(TxState == S_PREAMBLE)	PreambleCount <= PreambleCount + 5'd1;
			else						PreambleCount <= 5'd0;

			if(TxState == S_PAUSE)		PauseCount <= PauseCount + 8'd1;
			else						PauseCount <= 8'd0;

			if(DataCount == 16'd5)		MacAddressInsert <= 1'b1;
			else if(DataCount == 16'd11)	MacAddressInsert <= 1'b0;
		end
	end

	function [7:0] TxDataTempSel;
		input [3:0]		TxState;
		input [15:0]	DataCount;
		input [7:0]		BUFF_DATA;
		input [7:0]		RegData;
		input [47:0]	MAC_ADDRESS;
		input [15:0]	PAUSE_QUANTA_DATA;
		input [7:0]		CrcData;
	begin
		case(TxState)
			S_PREAMBLE: begin
				TxDataTempSel = 8'h55;
			end
			S_SFD: begin
				TxDataTempSel = 8'hD5;
			end
			S_DATA: begin
				if(MacAddressInsert) begin
					case(DataCount)
						16'd6:  TxDataTempSel = MAC_ADDRESS[ 7: 0];
						16'd7:  TxDataTempSel = MAC_ADDRESS[15: 8];
						16'd8:  TxDataTempSel = MAC_ADDRESS[23:16];
						16'd9:  TxDataTempSel = MAC_ADDRESS[31:24];
						16'd10: TxDataTempSel = MAC_ADDRESS[39:32];
						16'd11: TxDataTempSel = MAC_ADDRESS[47:40];
					endcase
				end else begin
					if(GIG_MODE)		TxDataTempSel = BUFF_DATA;
					else if(RunMode)	TxDataTempSel = RegData;
						 else		   TxDataTempSel = BUFF_DATA;
				end
			end
			S_SEND_PAUSE_FRAME: begin
				if(MacAddressInsert) begin
					case(DataCount)
						16'd6:  TxDataTempSel = MAC_ADDRESS[ 7: 0];
						16'd7:  TxDataTempSel = MAC_ADDRESS[15: 8];
						16'd8:  TxDataTempSel = MAC_ADDRESS[23:16];
						16'd9:  TxDataTempSel = MAC_ADDRESS[31:24];
						16'd10: TxDataTempSel = MAC_ADDRESS[39:32];
						16'd11: TxDataTempSel = MAC_ADDRESS[47:40];
					endcase
				end else begin
					case(DataCount)
						16'd0:   TxDataTempSel = 8'h01;
						16'd1:   TxDataTempSel = 8'h80;
						16'd2:   TxDataTempSel = 8'hC2;
						16'd3:   TxDataTempSel = 8'h00;
						16'd4:   TxDataTempSel = 8'h00;
						16'd5:   TxDataTempSel = 8'h01;
						16'd12:  TxDataTempSel = 8'h88;	// Type
						16'd13:  TxDataTempSel = 8'h08;
						16'd14:  TxDataTempSel = 8'h00;	// OpCore
						16'd15:  TxDataTempSel = 8'h01;
						16'd16:  TxDataTempSel = PAUSE_QUANTA_DATA[7:0];
						16'd17:  TxDataTempSel = PAUSE_QUANTA_DATA[15:8];
						default: TxDataTempSel = 8'h00;
					endcase
				end
			end
			S_PADDING: begin
				TxDataTempSel = 8'h00;
			end
			S_JAM: begin
				TxDataTempSel = 8'h01;
			end
			S_FCS: begin
				TxDataTempSel = CrcData;
			end
			default: begin
				TxDataTempSel = 8'h00;
			end
		endcase
	end
	endfunction
	assign TxDataTemp = TxDataTempSel(TxState, DataCount, BUFF_DATA, RegData, MAC_ADDRESS, PAUSE_QUANTA_DATA, CrcData);

	// Output Data Registers
	always @(posedge CLK or negedge RST_N) begin
		if(!RST_N) begin
			TxEnable	<= 1'b0;
			TxData		<= 8'd00;
		end else begin
			if(TxState == S_DATA || TxState == S_PREAMBLE || TxState == S_SFD || TxState == S_SEND_PAUSE_FRAME || TxState == S_FCS || TxState == S_PADDING || TxState == S_JAM) begin
				TxEnable <= 1'b1;
			end else begin
				TxEnable <= 1'b0;
			end
			if(GIG_MODE)		TxData <= TxDataTemp;
			else if(RunMode)	TxData <= {4'd0,TxDataTemp[7:4]};
			else				TxData <= {4'd0,TxDataTemp[3:0]};
		end
	end

	// Flow Control
	always @(posedge CLK or negedge RST_N) begin
		if(!RST_N)					PauseQuantaSub <= 1'b0;
		else if(PauseCount == 64)   PauseQuantaSub <= 1'b1;
		else						PauseQuantaSub <= 1'b0;
	end

	assign PAUSE_QUANTA_SUB = PauseQuantaSub;

	wire CrcEnableTemp, CrcRdTemp;
	assign CrcEnableTemp = CrcEnable & RunMode;
	assign CrcRdTemp = CrcRd & RunMode;

	// CRC
	aq_gemac_tx_crc u_aq_gemac_tx_crc(
		.RST_N		( RST_N			),
		.CLK		( CLK			),

		.CRC_INIT   ( CrcInit		),
		.CRC_DATA   ( TxDataTemp	),
		.CRC_ENABLE ( CrcEnableTemp	),

		.CRC_RD		( CrcRdTemp		),
		.CRC_OUT	( CrcData		),
		.CRC_END	( CrcEnd		)
	);

	assign TX_D  = TxData;
	assign TX_EN = TxEnable;
	assign TX_ER = 1'b0;
endmodule
