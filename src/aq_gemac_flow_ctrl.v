/*
* PROJECT: AQUAXIS Giga Ethernet MAC
* ----------------------------------------------------------------------
*
* aq_gemac_flow_ctrl.v
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
* 2011/04/24 rename
*/
module aq_gemac_flow_ctrl(
	input			RST_N,
	input			CLK,				// Clock from Tx Clock

	// From CPU
	input			TX_PAUSE_ENABLE,

	// Rx MAC
	input [15:0]	PAUSE_QUANTA,
	input			PAUSE_QUANTA_VALID,
	output			PAUSE_QUANTA_COMPLETE,

	// Tx MAC
	output			PAUSE_APPLY,
	input			PAUSE_QUANTA_SUB
);

	reg			PauseQuantaValidDl1, PauseQuantaValidDl2;
	reg [15:0]	PauseQuanta, PauseQuantaCount;
	reg			PauseApply;

	always @(posedge CLK or negedge RST_N) begin
		if(!RST_N) begin
		end else begin
			PauseQuantaValidDl1	<= PAUSE_QUANTA_VALID;
			PauseQuantaValidDl2	<= PauseQuantaValidDl1;
			PauseQuanta			<= PAUSE_QUANTA;
		end
	end

	always @(posedge CLK or negedge RST_N) begin
		if(!RST_N)												PauseQuantaCount <= 16'd0;
		else if(!PauseQuantaValidDl2 && PauseQuantaValidDl1)	PauseQuantaCount <= PauseQuanta;
		else if(PAUSE_QUANTA_SUB && PauseQuantaCount != 0)		  PauseQuantaCount <= PauseQuantaCount - 16'd1;
	end

	always @(posedge CLK or negedge RST_N) begin
		if(!RST_N)						PauseApply <= 1'b0;
		else if(PauseQuantaCount == 0)	PauseApply <= 1'b0;
		else if(TX_PAUSE_ENABLE)		PauseApply <= 1'b1;
	end

	assign PAUSE_QUANTA_COMPLETE	= PauseQuantaValidDl1 & PauseQuantaValidDl2;
	assign PAUSE_APPLY				= PauseApply;
endmodule
