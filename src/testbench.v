//---------------------------------------------------------------------------
// File Name		: testbench.v
// Module Name	: test
// Description	: TestBench for FIFO
// Project		: FIFO
// Belong to		:
// Author			: H.Ishihara
// E-Mail			: hidemi@sweetcafe.jp
// HomePage		: http://www.sweetcafe.jp/
// Editor			: Eclipse with VerilogEditor
// Tab				: 4 spaces
// Date			: 2007/02/28
// Rev.			: 1.0
//---------------------------------------------------------------------------
// Rev. Date		 Description
//---------------------------------------------------------------------------
// 1.00 2007/02/28 1st Release
//* 2007/01/06 1st release
//* 2011/04/24 rename
//---------------------------------------------------------------------------
// $Id:
//---------------------------------------------------------------------------
`timescale 1ps / 1ps

module test;

	parameter	WR_TIME	= 10000;
	parameter	RD_TIME	= 2000;
//	parameter	WR_TIME	= 4000;
//	parameter	RD_TIME	= 10000;

	wire		wr_ena;
	wire [7:0]	wr_data;
	wire		rd_ena;

	reg			RST;
	reg			WR_CLK;
	reg			WR_ENA;
	reg	[7:0]	WR_DATA;
	wire			WR_FULL;
	wire			WR_ALM_FULL;
	reg	[3:0]	WR_ALM_COUNT;

	reg			RD_CLK;
	reg			RD_ENA;
	wire [7:0]	RD_DATA;
	wire			RD_EMPTY;
	wire			RD_ALM_EMPTY;
	reg [3:0]		RD_ALM_COUNT;

	integer		WriteEnd, ReadEnd;

	assign #10 wr_ena = WR_ENA;
	assign #10 wr_data = WR_DATA;
	assign #10 rd_ena = ~RD_EMPTY;

	fifo #(4,8) u_fifo(
		.RST					( RST				),

		.FIFO_WR_CLK			( WR_CLK			),
		.FIFO_WR_ENA			( wr_ena			),
		.FIFO_WR_DATA			( wr_data			),
		.FIFO_WR_FULL			( WR_FULL			),
		.FIFO_WR_ALM_FULL	( WR_ALM_FULL		),
		.FIFO_WR_ALM_COUNT	( WR_ALM_COUNT	),

		.FIFO_RD_CLK			( RD_CLK			),
		.FIFO_RD_ENA			( rd_ena			),
		.FIFO_RD_DATA			( RD_DATA			),
		.FIFO_RD_EMPTY		( RD_EMPTY		),
		.FIFO_RD_ALM_EMPTY	( RD_ALM_EMPTY	),
		.FIFO_RD_ALM_COUNT	( RD_ALM_COUNT	)
		);

	// Clock & Reset signal
	initial begin
		WR_CLK = 1'b0;
		RD_CLK = 1'b0;
	end

	always begin
		#(WR_TIME/2)	WR_CLK <= ~WR_CLK;
	end

	always begin
		#(RD_TIME/2)	RD_CLK <= ~RD_CLK;
	end

	initial begin
		RST = 1'b0;
		repeat (4) @(posedge WR_CLK); #2;
		RST = 1'b1;
	end

	// Write Task
	task WRITE;
		input [7:0]		data;
		begin
			WR_ENA	= 1'b1;
			WR_DATA	= data;
			@(posedge WR_CLK);
			WR_ENA	= 1'b0;
		end
	endtask

	// Read Task
	task READ;
		begin
			RD_ENA	= 1'b1;
			$display("Read Data: %02x\n",RD_DATA);
			@(posedge RD_CLK);
			RD_ENA	= 1'b0;
			@(posedge RD_CLK);
		end
	endtask

	// Init
	initial begin
		WR_ENA			= 1'b0;
		WR_DATA			= 8'h00;
		WR_ALM_COUNT	= 4'd1;
		RD_ENA			= 1'b0;
		RD_ALM_COUNT	= 4'd1;
	end

	integer i;

	// Write Sequence
	initial begin
		WriteEnd = 0;
		wait(RST == 1);

		@(posedge WR_CLK);

		for(i=0;i<256;i=i+1) begin
			wait(!WR_ALM_FULL);
			@(posedge WR_CLK);
			WRITE(i);
		end

		repeat (1000) @(posedge WR_CLK);
		WriteEnd = 1;
		$finish();
	end

	integer s;

	// Read Sequence
	initial begin
		s = 0;
	end

	initial begin
		while(1) begin
			@(posedge RD_CLK);
			if(~RD_EMPTY) begin
				if(RD_DATA != s) $display("Error");
				s=s+1;
			end
		end
	end

	initial begin
		wait(WriteEnd == 1);
		wait(ReadEnd == 1);
		//$finish;
	end

endmodule
