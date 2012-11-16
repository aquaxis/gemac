/*
* PROJECT: AQUAXIS Giga Ethernet MAC
* ----------------------------------------------------------------------
*
* aq_gemac_flow_ctrl.v
* Copyright (C)2007-2011 H.Ishihara
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*
* For further information please contact.
*   http://www.aquaxis.com/
*   info(at)aquaxis.com or hidemi(at)sweetcafe.jp
*
* Create 2007/06/01 H.Ishihara
* 2007/01/06 1st release
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
