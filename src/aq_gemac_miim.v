/*
* PROJECT: AQUAXIS Giga Ethernet MAC
* ----------------------------------------------------------------------
*
* aq_gemac_miim.v
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
module aq_gemac_miim(
	input			RST_N,
	input			CLK,

	input			MIIM_REQUEST,
	input			MIIM_WRITE,
	input [4:0]		MIIM_PHY_ADDRESS,
	input [4:0]		MIIM_REG_ADDRESS,
	input [15:0]	MIIM_WDATA,
	output [15:0]	MIIM_RDATA,
	output			MIIM_BUSY,

	output			MDC,
	input			MDIO_IN,
	output			MDIO_OUT,
	output			MDIO_OUT_ENABLE
);

	wire		ClkDiv;
	reg [15:0]	ClkDivCount;

	reg			Opmode, RegOut, RegOutEnable;
	reg [4:0]	Count;

	reg [4:0]	State;

	parameter S_IDLE		= 5'd0;
	parameter S_START_WAIT	= 5'd1;
	parameter S_PREAMBLE	= 5'd2;
	parameter S_SFD0		= 5'd3;
	parameter S_SFD1		= 5'd4;
	parameter S_WRITE0		= 5'd5;
	parameter S_WRITE1		= 5'd6;
	parameter S_READ0		= 5'd7;
	parameter S_READ1		= 5'd8;
	parameter S_ADDRESS		= 5'd9;
	parameter S_REGISTER	= 5'd10;
	parameter S_WTA0		= 5'd11;
	parameter S_WTA1		= 5'd12;
	parameter S_RTA0		= 5'd13;
	parameter S_RTA1		= 5'd14;
	parameter S_WRITE_DATA	= 5'd15;
	parameter S_READ_DATA	= 5'd16;
	parameter S_END			= 5'd17;

	reg [25:0]	ShiftReg;
	reg			RegShift;
	wire		ClkRise;

	parameter CLK_MAX = 16'd50;

	always @(posedge CLK or negedge RST_N) begin
		if(!RST_N) begin
			ClkDivCount	<= 16'd0;
		end else begin
			if(ClkDivCount == (CLK_MAX -16'd1)) begin
				ClkDivCount	<= 16'd0;
			end else begin
				ClkDivCount	<= ClkDivCount + 16'd1;
			end
		end
	end

	assign ClkDiv	= 16'd0;
	assign ClkRise	= (ClkDivCount >= (CLK_MAX /2));

	always @(posedge CLK or negedge RST_N) begin
		if(!RST_N) begin
			State			<= S_IDLE;
			Opmode			<= 1'b0;
			RegOut			<= 1'b0;
			RegOutEnable	<= 1'b0;
			RegShift		<= 1'b0;
			Count			<= 4'd0;
		end else begin
			case(State)
				S_IDLE: begin
					if(MIIM_REQUEST) begin
						State	<= S_START_WAIT;
						Opmode	<= MIIM_WRITE;
					end
				end
				S_START_WAIT: begin
					if(ClkDiv)	State		   <= S_PREAMBLE;
				end
				S_PREAMBLE: begin
					if(ClkDiv)	State		   <= S_SFD0;
					RegOut			<= 1'b1;
					RegOutEnable	<= 1'b1;
				end
				S_SFD0: begin
					if(ClkDiv)	State		   <= S_SFD1;
					RegOut			<= 1'b0;
					RegOutEnable	<= 1'b1;
				end
				S_SFD1: begin
					if(ClkDiv)  begin
						if(Opmode)	State   <= S_WRITE0;
						else		State   <= S_READ0;
					end
					RegOut			<= 1'b1;
					RegOutEnable	<= 1'b1;
				end
				S_WRITE0: begin
					if(ClkDiv)	State		   <= S_WRITE1;
					RegOut			<= 1'b0;
					RegOutEnable	<= 1'b1;
				end
				S_WRITE1: begin
					if(ClkDiv)	State		   <= S_ADDRESS;
					RegOut			<= 1'b1;
					RegOutEnable	<= 1'b1;
					Count			<= 4'd4;
				end
				S_READ0: begin
					if(ClkDiv)	State		   <= S_READ1;
					RegOut			<= 1'b1;
					RegOutEnable	<= 1'b1;
				end
				S_READ1: begin
					if(ClkDiv)	State		   <= S_ADDRESS;
					RegOut			<= 1'b0;
					RegOutEnable	<= 1'b1;
					Count			<= 4'd4;
				end
				S_ADDRESS: begin
					RegOut			<= ShiftReg[23];
					RegOutEnable	<= 1'b1;
					RegShift		<= 1'b1;
					if(ClkDiv)  begin
						if(Count == 4'd0) begin
							State	<= S_REGISTER;
							Count	<= 4'd4;
						end else begin
							Count	<= Count -4'd1;
						end
					end
				end
				S_REGISTER: begin
					RegOut			<= ShiftReg[23];
					RegOutEnable	<= 1'b1;
					if(ClkDiv) begin
						if(Count == 4'd0) begin
							if(Opmode)	State <= S_WTA0;
							else		State <= S_RTA0;
							Count	<= 4'd3;
						end else begin
							Count	<= Count -4'd1;
						end
					end
				end
				S_WTA0: begin
					State			<= S_WTA1;
					RegOut			<= 1'b1;
					RegOutEnable	<= 1'b1;
					RegShift		<= 1'b0;
				end
				S_WTA1: begin
					State			<= S_WRITE_DATA;
					RegOut			<= 1'b1;
					RegOutEnable	<= 1'b1;
					Count			<= 4'd15;
				end
				S_WRITE_DATA: begin
					RegOut			<= ShiftReg[23];
					RegOutEnable	<= 1'b1;
					RegShift		<= 1'b1;
					if(ClkDiv) begin
						if(Count == 4'd0) begin
							State	<= S_END;
						end else begin
							Count	<= Count -4'd1;
						end
					end
				end
				S_RTA0: begin
					State			<= S_RTA1;
					RegOutEnable	<= 1'b0;
					RegShift		<= 1'b0;
				end
				S_RTA1: begin
					State			<= S_READ_DATA;
					Count			<= 4'd15;
				end
				S_READ_DATA: begin
					RegShift		<= 1'b1;
					if(ClkDiv) begin
						if(Count == 4'd0) begin
							State	<= S_END;
						end else begin
							Count	<= Count +4'd1;
						end
					end
				end
				S_END: begin
					State			<= S_IDLE;
					RegOut			<= 1'b0;
					RegOutEnable	<= 1'b0;
					RegShift		<= 1'b0;
				end
			endcase
		end
	end

	always @(posedge CLK or negedge RST_N) begin
		if(!RST_N) begin
			ShiftReg	<= 26'd0;
		end else begin
			if((State == S_IDLE) && MIIM_REQUEST) begin
				ShiftReg	<= {MIIM_PHY_ADDRESS, MIIM_REG_ADDRESS, MIIM_WDATA};
			end else if(RegShift) begin
				ShiftReg	<= {ShiftReg[25:1], MDIO_IN};
			end
		end
	end

	assign MDIO_OUT			= RegOut;
	assign MDIO_OUT_ENABLE	= RegOutEnable;
	assign MDC				= ClkRise;
	assign MIIM_BUSY		= (State != S_IDLE);
	assign MIIM_RDATA		= ShiftReg[15:0];
endmodule
