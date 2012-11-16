/*
* PROJECT: AQUAXIS Giga Ethernet MAC
* ----------------------------------------------------------------------
*
* Rx MAC
* File: aq_gemac_rx_mac.v
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
* 2007/08/22	H.Ishihara	Modify Full & Empty
*							Pause receive
* 2012/05/29	H.Ishihara	change license, GPLv3 -> MIT
*							STATUS - change bit width 16bit -> 32bit
*/
module aq_gemac_rx_mac(
	input		RST_N,			// Reset(Active Low)
	input		CLK,			// Clock(125MHz/GMII or 25MHz/MII)

	//
	input [7:0]	RX_D,			// Rx Data	   from GMII or MII Interface
	input		RX_DV,			// Rx Data Valid from GMII or MII Interface
	input		RX_ER,			// Rx Error	  from GMII or MII Interface

	//
	output			BUFF_WE,		// BUFF Write Enable
	output			BUFF_START,		//
	output			BUFF_END,		//
	output [15:0]	BUFF_STATUS,	//
	output [7:0]	BUFF_DATA,		// BUFF Data
	input			BUFF_FULL,		// BUFF Full

	//
	output			PAUSE_QUANTA_VALID,
	output [15:0]	PAUSE_QUANTA,
	input			PAUSE_QUANTA_COMPLETE,

	// Control Mode
	input			GIG_MODE,		// Giga Mode(1:Giga Mode, 0: 10/100Mbps Mode)

	input [47:0]	MAC_ADDRESS,
	input [31:0]	IP_ADDRESS,

	input [15:0]	PORT0,
	input [15:0]	PORT1,
	input [15:0]	PORT2,
	input [15:0]	PORT3
);

	parameter RX_MIN_LENGTH = 16'd52;
	parameter RX_MAX_LENGTH = 16'd1518;

	reg [7:0]	RxD, RxDl;
	reg			RxDV, RxEr, Mode;

	wire		CrcError;

	reg [3:0]	RxState;
	parameter S_IDLE				= 4'd0;
	parameter S_PREAMBLE			= 4'd1;
	parameter S_SFD					= 4'd2;
	parameter S_DATA				= 4'd3;
	parameter S_CHECK_CRC			= 4'd4;
	parameter S_DROP				= 4'd5;
	parameter S_BUFF_FULL_DROP		= 4'd6;
	parameter S_OK_END				= 4'd7;
	parameter S_ERR_END				= 4'd8;
	parameter S_CRC_ERR_END			= 4'd9;
	parameter S_BUFF_FULL_ERR_END	= 4'd10;
	parameter S_IFG					= 4'd11;

	reg			BuffWriteEnable;
	reg			BUFFWriteStart;
	reg			BUFFWriteEnd;
	reg			ErrorStatusCrc;
	reg			ErrorStatusDrop;
	reg			ErrorStatusValid;
	reg			CrcInit;

	reg			TooShort;
	reg			TooLong;
	reg [5:0]	IfgCount;
	reg [15:0]	DataCount;

	reg [2:0]	PauseState;
	parameter PS_IDLE		= 3'd0;
	parameter PS_PRE_SYNC	= 3'd1;
	parameter PS_QUANTA_HI	= 3'd2;
	parameter PS_QUANTA_LO	= 3'd3;
	parameter PS_SYN		= 3'd4;

	reg			PauseValid;
	reg [15:0]	PauseQuanta;

	// Delay Signals
	always @(posedge CLK or negedge RST_N) begin
		if(!RST_N) begin
			RxD		<= 8'd0;
			RxDV	<= 1'b0;
			RxEr	<= 1'b0;
			RxDl	<= 8'd0;
			Mode	<= 1'b0;
		end else begin
			if(!GIG_MODE) begin
				RxD[7:4]	<= RX_D[3:0];
				RxD[3:0]	<= RxD[7:4];
			end else begin
				RxD			<= RX_D;
			end
			RxDV	<= RX_DV;
			RxEr	<= RX_ER;
			RxDl	<= RxD;
			if(GIG_MODE) begin
				Mode <= 1'b0;
			end else begin
				if(!Mode)	Mode <= RX_DV;
				else		Mode <= 1'b0;
			end
		end
	end

	// State Machine
	always @(posedge CLK or negedge RST_N) begin
		if(!RST_N) begin
			RxState				<= S_IDLE;
			BuffWriteEnable		<= 1'b0;
			BUFFWriteStart		<= 1'b0;
			BUFFWriteEnd		<= 1'b0;
			ErrorStatusCrc	<= 1'b0;
			ErrorStatusDrop	<= 1'b0;
			ErrorStatusValid	<= 1'b0;
			CrcInit				<= 1'b0;
		end else begin
			if(!Mode) begin
				case(RxState)
					S_IDLE: begin
						if(RxDV && RxD == 8'h55) begin
							RxState			<= S_PREAMBLE;
						end
						BuffWriteEnable		<= 1'b0;
						BUFFWriteStart		<= 1'b0;
						BUFFWriteEnd		<= 1'b0;
						ErrorStatusCrc	<= 1'b0;
						ErrorStatusDrop	<= 1'b0;
						ErrorStatusValid	<= 1'b0;
					end
					S_PREAMBLE: begin
						if(!RxDV) begin
							RxState			<= S_ERR_END;
						end else if(RxEr) begin
							RxState			<= S_DROP;
						end else if(RxD == 8'hd5) begin
							RxState			<= S_SFD;
						end else if(RxD != 8'h55) begin
							RxState			<= S_DROP;
						end
						CrcInit				<= 1'b1;
					end
					S_SFD: begin
						if(!RxDV) begin
							RxState			<= S_ERR_END;
						end else if(RxEr) begin
							RxState			<= S_DROP;
						end else begin
							RxState			<= S_DATA;
							BuffWriteEnable	<= 1'b1;
							BUFFWriteStart	<= 1'b1;
						end
						CrcInit				<= 1'b0;
					end
					S_DATA: begin
						BUFFWriteStart		<= 1'b0;
						BuffWriteEnable		<= 1'b1;
						if(!RxDV && !TooShort && !TooLong) begin
							RxState			<= S_CHECK_CRC;
						end else if(!RxDV && ( TooShort || TooLong )) begin
							RxState			<= S_ERR_END;
						end else if(BUFF_FULL) begin
							RxState			<= S_BUFF_FULL_DROP;
						//end else if(RxEr || RxAddressCheckError || Too_Long || BroadcastDrop) begin
						end else if(RxEr || TooLong) begin
							RxState			<= S_DROP;
						end
					end
					S_CHECK_CRC: begin
						BuffWriteEnable		<= 1'b1;
						if(CrcError) begin
							RxState			<= S_CRC_ERR_END;
							ErrorStatusCrc	<= 1'b1;
						end else begin
							RxState			<= S_OK_END;
						end
					end
					S_DROP: begin
						BuffWriteEnable		<= 1'b0;
						if(!RxDV) begin
							RxState			<= S_ERR_END;
						end
						ErrorStatusDrop	<= 1'b1;
					end
					S_BUFF_FULL_DROP: begin
						BuffWriteEnable		<= 1'b0;
						if(!RxDV) begin
							RxState			<= S_BUFF_FULL_ERR_END;
						end
						ErrorStatusDrop	<= 1'b1;
					end
					S_OK_END: begin
						RxState				<= S_IFG;
						BUFFWriteEnd		<= 1'b1;
					end
					S_ERR_END: begin
						BuffWriteEnable		<= 1'b0;
						RxState				<= S_IFG;
						BUFFWriteEnd		<= 1'b1;
						ErrorStatusValid	<= 1'b1;
					end
					S_CRC_ERR_END: begin
						RxState				<= S_IFG;
						BUFFWriteEnd		<= 1'b1;
						ErrorStatusValid	<= 1'b1;
					end
					S_BUFF_FULL_ERR_END: begin
						RxState				<= S_IFG;
						BUFFWriteEnd		<= 1'b1;
						ErrorStatusValid	<= 1'b1;
					end
					S_IFG: begin
						// InterFrameGap Normal = 12Byte
						BUFFWriteEnd	<= 1'b0;
						BUFFWriteEnd	<= 1'b0;
						if(IfgCount == 9) begin
							RxState		<= S_IDLE;
						end
					end
				endcase
			end else begin
				BuffWriteEnable		<= 1'b0;
				BUFFWriteStart		<= 1'b0;
				BUFFWriteEnd		<= 1'b0;
				ErrorStatusCrc	<= 1'b0;
				ErrorStatusDrop	<= 1'b0;
				ErrorStatusValid	<= 1'b0;
			end
		end
	end

	// Counters
	always @(posedge CLK or negedge RST_N) begin
		if(!RST_N) begin
			IfgCount	<= 6'd0;
			DataCount	<= 16'd0;
			TooShort	<= 1'b0;
			TooLong		<= 1'b0;
		end else begin
			if(!Mode) begin
				if(RxState == S_IFG)	IfgCount <= IfgCount +6'd1;
				else					IfgCount <= 6'd0;

				if(RxState == S_DATA)	DataCount <= DataCount + 16'd1;
				else					DataCount <= 16'd0;

				if(RxState == S_DATA && DataCount >= RX_MIN_LENGTH)	TooShort <= 1'b0;
				else if(RxState == S_IDLE)							TooShort <= 1'b1;

				if(RxState == S_DATA && DataCount > RX_MAX_LENGTH)	TooLong <= 1'b1;
				else if(RxState == S_IDLE)							TooLong <= 1'b0;
			end
		end
	end

	// Flow control signals
	always @(posedge CLK or negedge RST_N) begin
		if(!RST_N) begin
			PauseState	<= PS_IDLE;
			PauseQuanta	<= 16'd0;
		end else begin
			//if(!Mode) begin
				case(PauseState)
					PS_IDLE: begin
						if(RxState == S_SFD)	PauseState <= PS_PRE_SYNC;
					end
					PS_PRE_SYNC: begin
						case(DataCount)
							16'd1:	if(RxDl != 8'h01)	PauseState <= PS_IDLE;
							16'd2:	if(RxDl != 8'h80)	PauseState <= PS_IDLE;
							16'd3:	if(RxDl != 8'hC2)	PauseState <= PS_IDLE;
							16'd4:	if(RxDl != 8'h00)	PauseState <= PS_IDLE;
							16'd5:	if(RxDl != 8'h00)	PauseState <= PS_IDLE;
							16'd6:	if(RxDl != 8'h01)	PauseState <= PS_IDLE;
							16'd13:	if(RxDl != 8'h88)	PauseState <= PS_IDLE;
							16'd14:	if(RxDl != 8'h08)	PauseState <= PS_IDLE;
							16'd15:	if(RxDl != 8'h00)	PauseState <= PS_IDLE;
							16'd16:	if(RxDl != 8'h01)	PauseState <= PS_QUANTA_HI;
						endcase
					end
					PS_QUANTA_HI: begin
						PauseState			<= PS_QUANTA_LO;
						PauseQuanta[15:8]	<= RxD;
					end
					PS_QUANTA_LO: begin
						PauseState			<= PS_SYN;
						PauseQuanta[7:0]	<= RxD;
					end
					PS_SYN: begin
						if(RxState == S_IFG)	PauseState <= PS_IDLE;
					end
				endcase
			//end
		end
	end

	always @(posedge CLK or negedge RST_N) begin
		if(!RST_N)														PauseValid <= 1'b0;
		else if(RxState == S_OK_END && PauseState == PS_SYN && !Mode)	PauseValid <= 1'b1;
		else if(PAUSE_QUANTA_COMPLETE)									PauseValid <= 1'b0;
	end

	assign PAUSE_QUANTA_VALID	= PauseValid;
	assign PAUSE_QUANTA			= PauseQuanta;

	// CRC Check Module
	aq_gemac_rx_crc u_aq_gemac_rx_crc(
		.RST_N		( RST_N				),
		.CLK		( CLK				),

		.CRC_DATA   ( RxDl				),
		.CRC_INIT   ( CrcInit			),
		.CRC_ENABLE ( BuffWriteEnable	),

		.CRC_ERR	( CrcError			)
	);

	// IP/TCP/UDP/ARP/ICMP Offload Engine
	wire [15:0]	DecodeStatus;
	aq_gemac_rx_decode u_aq_gemac_rx_decode(
		.RST_N		( RST_N				),
		.CLK		( CLK				),

		.BUFF_WE	( BuffWriteEnable	),
		.BUFF_START ( BUFFWriteStart	),
		.BUFF_END   ( BUFFWriteEnd		),
		.BUFF_DATA  ( RxDl				),

		.MAC_ADDRESS( MAC_ADDRESS		),
		.IP_ADDRESS ( IP_ADDRESS		),

		.PORT0		( PORT0[15:0]		),
		.PORT1		( PORT1[15:0]		),
		.PORT2		( PORT2[15:0]		),
		.PORT3		( PORT3[15:0]		),

		.STATUS		( DecodeStatus		)
	);

	reg [15:0] DecodeStatusReg;
	always @(posedge CLK or negedge RST_N) begin
		if(!RST_N)				DecodeStatusReg <= 16'd0;
		else if(BUFFWriteEnd)   DecodeStatusReg <= DecodeStatus;
	end

	wire DecodePort = |DecodeStatusReg[15:12];

	// Output Signals
	assign BUFF_WE		= BuffWriteEnable;
	assign BUFF_DATA	= RxDl;
	assign BUFF_START	= BUFFWriteStart;
	assign BUFF_END		= BUFFWriteEnd;
	assign BUFF_STATUS	= {DecodeStatusReg[7:0], DecodeStatusReg[9:8], DecodePort, TooShort, TooLong,  ErrorStatusDrop, ErrorStatusCrc, ErrorStatusValid};

endmodule
