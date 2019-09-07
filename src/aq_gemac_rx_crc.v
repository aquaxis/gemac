/*
* PROJECT: AQUAXIS Giga Ethernet MAC
* ----------------------------------------------------------------------
*
* Rx CRC Checker
* File: aq_gemac_rx_crc.v
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
* 2011/04/24 H.Ishihara	rename
* 2012/05/29 H.Ishihara	change license, GPLv3 -> MIT
*/
module aq_gemac_rx_crc(
	input		RST_N,
	input		CLK,

	input [7:0]	CRC_DATA,
	input		CRC_INIT,
	input		CRC_ENABLE,

	output		CRC_ERR
);

	reg	[31:0]	CrcReg;

	function[31:0]	GenCrcData;
		input[7:0]	DataIn;
		input[31:0]	RegData;
		begin
			GenCrcData[0]	= RegData[24] ^ RegData[30] ^ DataIn[1]   ^ DataIn[7];
			GenCrcData[1]	= RegData[25] ^ RegData[31] ^ DataIn[0]   ^ DataIn[6]   ^ RegData[24] ^ RegData[30] ^ DataIn[1]   ^ DataIn[7];
			GenCrcData[2]	= RegData[26] ^ DataIn[5]   ^ RegData[25] ^ RegData[31] ^ DataIn[0]   ^ DataIn[6]   ^ RegData[24] ^ RegData[30] ^ DataIn[1]   ^ DataIn[7];
			GenCrcData[3]	= RegData[27] ^ DataIn[4]   ^ RegData[26] ^ DataIn[5]   ^ RegData[25] ^ RegData[31] ^ DataIn[0]   ^ DataIn[6];
			GenCrcData[4]	= RegData[28] ^ DataIn[3]   ^ RegData[27] ^ DataIn[4]   ^ RegData[26] ^ DataIn[5]   ^ RegData[24] ^ RegData[30] ^ DataIn[1]   ^ DataIn[7];
			GenCrcData[5]	= RegData[29] ^ DataIn[2]   ^ RegData[28] ^ DataIn[3]   ^ RegData[27] ^ DataIn[4]   ^ RegData[25] ^ RegData[31] ^ DataIn[0]   ^ DataIn[6]   ^ RegData[24] ^ RegData[30] ^ DataIn[1] ^ DataIn[7];
			GenCrcData[6]	= RegData[30] ^ DataIn[1]   ^ RegData[29] ^ DataIn[2]   ^ RegData[28] ^ DataIn[3]   ^ RegData[26] ^ DataIn[5]   ^ RegData[25] ^ RegData[31] ^ DataIn[0]   ^ DataIn[6];
			GenCrcData[7]	= RegData[31] ^ DataIn[0]   ^ RegData[29] ^ DataIn[2]   ^ RegData[27] ^ DataIn[4]   ^ RegData[26] ^ DataIn[5]   ^ RegData[24] ^ DataIn[7];
			GenCrcData[8]	= RegData[0]  ^ RegData[28] ^ DataIn[3]   ^ RegData[27] ^ DataIn[4]   ^ RegData[25] ^ DataIn[6]   ^ RegData[24] ^ DataIn[7];
			GenCrcData[9]	= RegData[1]  ^ RegData[29] ^ DataIn[2]   ^ RegData[28] ^ DataIn[3]   ^ RegData[26] ^ DataIn[5]   ^ RegData[25] ^ DataIn[6];
			GenCrcData[10]	= RegData[2]  ^ RegData[29] ^ DataIn[2]   ^ RegData[27] ^ DataIn[4]   ^ RegData[26] ^ DataIn[5]   ^ RegData[24] ^ DataIn[7];
			GenCrcData[11]	= RegData[3]  ^ RegData[28] ^ DataIn[3]   ^ RegData[27] ^ DataIn[4]   ^ RegData[25] ^ DataIn[6]   ^ RegData[24] ^ DataIn[7];
			GenCrcData[12]	= RegData[4]  ^ RegData[29] ^ DataIn[2]   ^ RegData[28] ^ DataIn[3]   ^ RegData[26] ^ DataIn[5]   ^ RegData[25] ^ DataIn[6]   ^ RegData[24] ^ RegData[30] ^ DataIn[1]   ^ DataIn[7];
			GenCrcData[13]	= RegData[5]  ^ RegData[30] ^ DataIn[1]   ^ RegData[29] ^ DataIn[2]   ^ RegData[27] ^ DataIn[4]   ^ RegData[26] ^ DataIn[5]   ^ RegData[25] ^ RegData[31] ^ DataIn[0]   ^ DataIn[6];
			GenCrcData[14]	= RegData[6]  ^ RegData[31] ^ DataIn[0]   ^ RegData[30] ^ DataIn[1]   ^ RegData[28] ^ DataIn[3]   ^ RegData[27] ^ DataIn[4]   ^ RegData[26] ^ DataIn[5];
			GenCrcData[15]	= RegData[7]  ^ RegData[31] ^ DataIn[0]   ^ RegData[29] ^ DataIn[2]   ^ RegData[28] ^ DataIn[3]   ^ RegData[27] ^ DataIn[4];
			GenCrcData[16]	= RegData[8]  ^ RegData[29] ^ DataIn[2]   ^ RegData[28] ^ DataIn[3]   ^ RegData[24] ^ DataIn[7];
			GenCrcData[17]	= RegData[9]  ^ RegData[30] ^ DataIn[1]   ^ RegData[29] ^ DataIn[2]   ^ RegData[25] ^ DataIn[6];
			GenCrcData[18]	= RegData[10] ^ RegData[31] ^ DataIn[0]   ^ RegData[30] ^ DataIn[1]   ^ RegData[26] ^ DataIn[5];
			GenCrcData[19]	= RegData[11] ^ RegData[31] ^ DataIn[0]   ^ RegData[27] ^ DataIn[4];
			GenCrcData[20]	= RegData[12] ^ RegData[28] ^ DataIn[3];
			GenCrcData[21]	= RegData[13] ^ RegData[29] ^ DataIn[2];
			GenCrcData[22]	= RegData[14] ^ RegData[24] ^ DataIn[7];
			GenCrcData[23]	= RegData[15] ^ RegData[25] ^ DataIn[6]   ^ RegData[24] ^ RegData[30] ^ DataIn[1]   ^ DataIn[7];
			GenCrcData[24]	= RegData[16] ^ RegData[26] ^ DataIn[5]   ^ RegData[25] ^ RegData[31] ^ DataIn[0]   ^ DataIn[6];
			GenCrcData[25]	= RegData[17] ^ RegData[27] ^ DataIn[4]   ^ RegData[26] ^ DataIn[5];
			GenCrcData[26]	= RegData[18] ^ RegData[28] ^ DataIn[3]   ^ RegData[27] ^ DataIn[4]   ^ RegData[24] ^ RegData[30] ^ DataIn[1]   ^ DataIn[7];
			GenCrcData[27]	= RegData[19] ^ RegData[29] ^ DataIn[2]   ^ RegData[28] ^ DataIn[3]   ^ RegData[25] ^ RegData[31] ^ DataIn[0]   ^ DataIn[6];
			GenCrcData[28]	= RegData[20] ^ RegData[30] ^ DataIn[1]   ^ RegData[29] ^ DataIn[2]   ^ RegData[26] ^ DataIn[5];
			GenCrcData[29]	= RegData[21] ^ RegData[31] ^ DataIn[0]   ^ RegData[30] ^ DataIn[1]   ^ RegData[27] ^ DataIn[4];
			GenCrcData[30]	= RegData[22] ^ RegData[31] ^ DataIn[0]   ^ RegData[28] ^ DataIn[3];
			GenCrcData[31]	= RegData[23] ^ RegData[29] ^ DataIn[2];
		end
	endfunction

	always @(posedge CLK or negedge RST_N) begin
		if(!RST_N) begin
			CrcReg <= 32'hFFFFFFFF;
		end else begin
			if(CRC_INIT)		CrcReg <= 32'hFFFFFFFF;
			else if(CRC_ENABLE)	CrcReg <= GenCrcData(CRC_DATA, CrcReg);
		end
	end

	assign CRC_ERR = CrcReg != 32'hC704DD7B;

endmodule

