/*
* PROJECT: AQUAXIS Giga Ethernet MAC
* ----------------------------------------------------------------------
*
* fifo.v
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
* 2007/01/01 1st release
* 2011/04/24 rename
*/
`timescale 1ps / 1ps

module fifo(
	RST,

	FIFO_WR_CLK,
	FIFO_WR_ENA,
	FIFO_WR_DATA,
	FIFO_WR_FULL,
	FIFO_WR_ALM_FULL,
	FIFO_WR_ALM_COUNT,

	FIFO_RD_CLK,
	FIFO_RD_ENA,
	FIFO_RD_DATA,
	FIFO_RD_EMPTY,
	FIFO_RD_ALM_EMPTY,
	FIFO_RD_ALM_COUNT
	);

	parameter FIFO_DEPTH	= 8;
	parameter FIFO_WIDTH	= 32;

	input							RST;

	input 							FIFO_WR_CLK;
	input 							FIFO_WR_ENA;
	input [FIFO_WIDTH -1:0]		FIFO_WR_DATA;
	output 						FIFO_WR_FULL;
	output 						FIFO_WR_ALM_FULL;
	input [FIFO_DEPTH -1:0]		FIFO_WR_ALM_COUNT;

	input 							FIFO_RD_CLK;
	input 							FIFO_RD_ENA;
	output [FIFO_WIDTH -1:0]	FIFO_RD_DATA;
	output 						FIFO_RD_EMPTY;
	output 						FIFO_RD_ALM_EMPTY;
	input [FIFO_DEPTH -1:0]		FIFO_RD_ALM_COUNT;

	reg [FIFO_DEPTH -1:0]		wr_adrs;
	reg 							wr_full, wr_alm_full;
	reg [FIFO_DEPTH -1:0]		wr_rd_count_d1r,wr_rd_count_d2r,wr_rd_count;

	reg [FIFO_DEPTH -1:0]		rd_adrs;
	reg 							rd_empty, rd_alm_empty;
	reg [FIFO_DEPTH -1:0]		rd_wr_count_d1r,rd_wr_count_d2r,rd_wr_count;

	wire 							wr_ena;
	reg 							wr_ena_req;
	wire 							rd_wr_ena, rd_wr_ena_ack;
	reg 							rd_wr_ena_d1r,rd_wr_ena_d2r;
	reg							rd_wr_full_d1r, rd_wr_full;

	reg 							rd_ena_req;
	wire 							wr_rd_ena, wr_rd_ena_ack;
	reg 							wr_rd_ena_d1r,wr_rd_ena_d2r;
	reg								wr_rd_empty_d1r, wr_rd_empty;

	wire							reserve_ena;
	reg							reserve_empty, reserve_read;
	wire							reserve_alm_empty;
	reg [FIFO_WIDTH -1:0]		reserve_data;

	wire [FIFO_WIDTH -1:0]		rd_fifo;

	assign wr_ena = (!wr_full)?FIFO_WR_ENA:1'b0;

	/////////////////////////////////////////////////////////////////////
	// Write Block

	// Write Address
	always @(posedge FIFO_WR_CLK or negedge RST) begin
		if(!RST) begin
			wr_adrs <= 0;
		end else begin
			if(!wr_full & FIFO_WR_ENA) wr_adrs <= wr_adrs + 1;
		end
	end

	wire [FIFO_DEPTH -1:0] wr_adrs_s1, wr_adrs_s2;
	assign wr_adrs_s1 = wr_rd_count -1;
	assign wr_adrs_s2 = wr_rd_count -2;

	// make a full and almost full signal
	always @(posedge FIFO_WR_CLK or negedge RST) begin
		if(!RST) begin
			wr_full		<= 1'b0;
			wr_alm_full	<= 1'b0;
		end else begin
			if(FIFO_WR_ENA & (wr_adrs == wr_adrs_s1)) begin
				wr_full	<= 1'b1;
			end else if(wr_rd_empty | wr_rd_ena & !(wr_adrs == wr_adrs_s1)) begin
				wr_full	<= 1'b0;
			end
			if(FIFO_WR_ENA & ((wr_adrs == wr_adrs_s1) | (wr_adrs == wr_adrs_s2))) begin
				wr_alm_full <= 1'b1;
			end else if(wr_rd_empty | wr_rd_ena & !((wr_adrs == wr_adrs_s1) | (wr_adrs == wr_adrs_s2))) begin
				wr_alm_full <= 1'b0;
			end
		end
	end
	// Read Control signal from Read Block
	always @(posedge FIFO_WR_CLK or negedge RST) begin
		if(!RST) begin
			wr_rd_count_d1r	<= {FIFO_DEPTH{1'b1}};
			wr_rd_count		<= {FIFO_DEPTH{1'b1}};
		end else begin
			wr_rd_ena_d1r		<= rd_ena_req;
			wr_rd_ena_d2r		<= wr_rd_ena_d1r;
			wr_rd_count_d1r	<= rd_adrs;
			wr_rd_count	<= wr_rd_count_d1r;
			wr_rd_empty_d1r		<= rd_empty;
			wr_rd_empty		<= wr_rd_empty_d1r;
		end
	end
	assign wr_rd_ena		= wr_rd_ena_d1r & ~wr_rd_ena_d2r;
	assign wr_rd_ena_ack	= wr_rd_ena_d1r & wr_rd_ena_d2r;

	// Send a write enable signal for Read Block
	always @(posedge FIFO_WR_CLK or negedge RST) begin
		if(!RST) begin
			wr_ena_req <= 1'b0;
		end else begin
			if(FIFO_WR_ENA) begin
				wr_ena_req <= 1'b1;
			end else if(rd_wr_ena_ack) begin
				wr_ena_req <= 1'b0;
			end
		end
	end

	/////////////////////////////////////////////////////////////////////
	// Read Block

	// Read Address
	always @(posedge FIFO_RD_CLK or negedge RST) begin
		if(!RST) begin
			rd_adrs	  <= 0;
		end else begin
			if(!rd_empty & reserve_ena) begin
				rd_adrs <= rd_adrs + 1;
			end
		end
	end

	wire [FIFO_DEPTH -1:0] rd_adrs_s1, rd_adrs_s2;
	assign rd_adrs_s1 = rd_wr_count -1;
	assign rd_adrs_s2 = rd_wr_count -2;

	// make a empty and almost empty signal
	always @(posedge FIFO_RD_CLK or negedge RST) begin
		if(!RST) begin
			rd_empty		<= 1'b1;
			rd_alm_empty	<= 1'b1;
		end else begin
			if(reserve_ena & (rd_adrs == rd_adrs_s1)) begin
				rd_empty	<= 1'b1;
			end else if(rd_wr_full | rd_wr_ena & !(rd_adrs == rd_adrs_s1)) begin
				rd_empty	<= 1'b0;
			end
			if(reserve_ena & ((rd_adrs == rd_adrs_s1) | (rd_adrs == rd_adrs_s2))) begin
				rd_alm_empty	<= 1'b1;
			end else if(rd_wr_full | rd_wr_ena & !((rd_adrs == rd_adrs_s1) | (rd_adrs == rd_adrs_s2))) begin
				rd_alm_empty	<= 1'b0;
			end
		end
	end

	// Write Control signal from Write Block
	always @(posedge FIFO_RD_CLK or negedge RST) begin
		if(!RST) begin
			rd_wr_ena_d1r		<= 1'b0;
			rd_wr_ena_d2r		<= 1'b0;
			rd_wr_count_d1r	<= {FIFO_DEPTH{1'b1}};
			rd_wr_count_d2r	<= {FIFO_DEPTH{1'b1}};
			rd_wr_count		<= {FIFO_DEPTH{1'b1}};
		end else begin
			rd_wr_ena_d1r		<= wr_ena_req;
			rd_wr_ena_d2r		<= rd_wr_ena_d1r;
			rd_wr_count_d1r	<= wr_adrs;
			rd_wr_count	<= rd_wr_count_d1r;
			rd_wr_full_d1r	<= wr_full;
			rd_wr_full	<= rd_wr_full_d1r;
		end
	end

	// Write enable signal from write block
	assign rd_wr_ena = ~rd_wr_ena_d2r & rd_wr_ena_d1r;
	assign rd_wr_ena_ack = rd_wr_ena_d2r & rd_wr_ena_d1r;

	// Send a read enable signal for Write Block
	always @(posedge FIFO_RD_CLK or negedge RST) begin
		if(!RST) begin
			rd_ena_req <= 1'b0;
		end else begin
			if(reserve_ena) begin
				rd_ena_req <= 1'b1;
			end else if(wr_rd_ena_ack) begin
				rd_ena_req <= 1'b0;
			end
		end
	end

	/////////////////////////////////////////////////////////////////////
	// Reserve Block
	assign reserve_ena = reserve_empty == 1'b1 & rd_empty == 1'b0;
	always @(posedge FIFO_RD_CLK or negedge RST) begin
		if(!RST) begin
			reserve_data			<= {FIFO_WIDTH{1'b0}};
			reserve_empty			<= 1'b1;
		end else begin
			if(reserve_ena) begin
				reserve_data			<= rd_fifo;
				reserve_empty			<= 1'b0;
			end else if(FIFO_RD_ENA) begin
				reserve_empty			<= 1'b1;
			end
		end
	end

	assign reserve_alm_empty = (rd_empty & ~reserve_empty);
	/////////////////////////////////////////////////////////////////////
	// output signals
	assign FIFO_WR_FULL			= wr_full;
	assign FIFO_WR_ALM_FULL		= wr_alm_full;
	assign FIFO_RD_EMPTY			= reserve_empty;
	assign FIFO_RD_ALM_EMPTY	= reserve_alm_empty;
	assign FIFO_RD_DATA			= reserve_data;

	/////////////////////////////////////////////////////////////////////
	// RAM
	fifo_ram #(FIFO_DEPTH,FIFO_WIDTH) u_fifo_ram(
		.WR_CLK  ( FIFO_WR_CLK  ),
		.WR_ENA  ( wr_ena  ),
		.WR_ADRS ( wr_adrs ),
		.WR_DATA ( FIFO_WR_DATA ),

		.RD_CLK  ( FIFO_RD_CLK  ),
		.RD_ADRS ( rd_adrs ),
		.RD_DATA ( rd_fifo )
		);

endmodule

module fifo_ram(
	WR_CLK,
	WR_ENA,
	WR_ADRS,
	WR_DATA,

	RD_CLK,
	RD_ADRS,
	RD_DATA
	);

	parameter DEPTH	= 12;
	parameter WIDTH	= 32;

	input					WR_CLK;
	input 					WR_ENA;
	input [DEPTH -1:0] 	WR_ADRS;
	input [WIDTH -1:0]	WR_DATA;

	input 					RD_CLK;
	input [DEPTH -1:0] 	RD_ADRS;
	output [WIDTH -1:0]	RD_DATA;

	reg [WIDTH -1:0]	ram [0:(2**DEPTH) -1];
	reg [WIDTH -1:0]	RD_DATA;

	always @(posedge WR_CLK) begin
		if(WR_ENA) ram[WR_ADRS] <= WR_DATA;
	end

	always @(posedge RD_CLK) begin
		RD_DATA <= ram[RD_ADRS];
	end

endmodule
