/*
* PROJECT: AQUAXIS Giga Ethernet MAC
* ----------------------------------------------------------------------
*
* IP Controller with Gigabit MAC
* File: aq_gemac_ip.v
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
* 2007/01/06 H.Ishihara	1st release
* 2011/04/24 H.Ishihara	rename
* 2013/02/26 H.Ishihara	Modify for IPIC
*/

module aq_gemac_gemod
#(
	// for PLB Parameters
	parameter C_SLV_AWIDTH	= 32,
	parameter C_SLV_DWIDTH	= 32,
	parameter C_MST_AWIDTH	= 32,
	parameter C_MST_DWIDTH	= 32,
	parameter C_NUM_REG		= 4,
	parameter C_NUM_MEM		= 1,
	parameter C_NUM_INTR	= 3,
	// GEMAC Parameters
	parameter USE_MIIM				= 1,
	parameter DEFAULT_MY_MAC_ADRS	= 48'h332211000000,
	parameter DEFAULT_MY_IP_ADRS	= 32'hFE01A8C0,
	parameter DEFAULT_MY_REC_PORT	= 16'd0004,
	parameter DEFAULT_MY_REC1_PORT	= 16'd0104,
	parameter DEFAULT_MY_SEND_PORT	= 16'd0004,
	parameter DEFAULT_PEER_IP_ADRS	= 32'hFE01A8C0
)

(
	// -- ADD USER PORTS BELOW THIS LINE ---------------
	input			RST,			// MAC Controller Reset

	input			EMAC_TX_CLK,	// Tx Clock(In)	for 10/100 Mode
	output [7:0]	EMAC_TXD,		// Tx Data
	output			EMAC_TX_EN,	// Tx Data Enable
	output			EMAC_TX_ER,	// Tx Error
	input			EMAC_COL,		// Collision signal
	input			EMAC_CRS,		// CRS
	input			EMAC_RX_CLK,	// Rx Clock(In)	for 10/100/1000 Mode
	input [7:0]		EMAC_RXD,		// Rx Data
	input			EMAC_RX_DV,	// Rx Data Valid
	input			EMAC_RX_ER,	// Rx Error

	// Send UDP
	input			SEND_REQUEST,
	input [15:0]	SEND_LENGTH,
	output			SEND_BUSY,
	input [47:0]	SEND_MAC_ADDRESS,
	input [31:0]	SEND_IP_ADDRESS,
	input [15:0]	SEND_DST_PORT,
	input [15:0]	SEND_SRC_PORT,
	input			SEND_DATA_VALID,
	output			SEND_DATA_READ,
	input [31:0]	SEND_DATA,

	// Receive UDP
	output			REC_REQUEST,
	output [15:0]	REC_LENGTH,
	output			REC_BUSY,
	output [3:0]	REC_DATA_VALID,
	output [47:0]	REC_SRC_MAC,
	output [31:0]	REC_SRC_IP,
	output [15:0]	REC_SRC_PORT,
	input			REC_DATA_READ,
	output [31:0]	REC_DATA,
	// -- ADD USER PORTS ABOVE THIS LINE ---------------

	// -- DO NOT EDIT BELOW THIS LINE ------------------
	input							Bus2IP_Clk,						// Bus to IP clock
	input							Bus2IP_Reset,					// Bus to IP reset
	input [0 : C_SLV_AWIDTH-1]		Bus2IP_Addr,					// Bus to IP address bus
	input [0 : C_NUM_MEM-1]			Bus2IP_CS,						// Bus to IP chip select for user logic memory selection
	input							Bus2IP_RNW,						// Bus to IP read/not write
	input [0 : C_SLV_DWIDTH-1]		Bus2IP_Data,					// Bus to IP data bus
	input [0 : C_SLV_DWIDTH/8-1]	Bus2IP_BE,						// Bus to IP byte enables
	input [0 : C_NUM_REG-1]			Bus2IP_RdCE,					// Bus to IP read chip enable
	input [0 : C_NUM_REG-1]			Bus2IP_WrCE,					// Bus to IP write chip enable
	output [0 : C_SLV_DWIDTH-1]		IP2Bus_Data,					// IP to Bus data bus
	output							IP2Bus_RdAck,					// IP to Bus read transfer acknowledgement
	output							IP2Bus_WrAck,					// IP to Bus write transfer acknowledgement
	output							IP2Bus_Error,					// IP to Bus error response

	output							IP2Bus_MstRd_Req,				// IP to Bus master read request
	output							IP2Bus_MstWr_Req,				// IP to Bus master write request
	output [0 : C_MST_AWIDTH-1]		IP2Bus_Mst_Addr,				// IP to Bus master address bus
	output [0 : C_MST_DWIDTH/8-1]	IP2Bus_Mst_BE,					// IP to Bus master byte enables
	output [0 : 11]					IP2Bus_Mst_Length,				// IP to Bus master transfer length
	output							IP2Bus_Mst_Type,				// IP to Bus master transfer type
	output							IP2Bus_Mst_Lock,				// IP to Bus master lock
	output							IP2Bus_Mst_Reset,				// IP to Bus master reset
	input							Bus2IP_Mst_CmdAck,				// Bus to IP master command acknowledgement
	input							Bus2IP_Mst_Cmplt,				// Bus to IP master transfer completion
	input							Bus2IP_Mst_Error,				// Bus to IP master error response
	input							Bus2IP_Mst_Rearbitrate,			// Bus to IP master re-arbitrate
	input							Bus2IP_Mst_Cmd_Timeout,			// Bus to IP master command timeout

	input [0 : C_MST_DWIDTH-1]		Bus2IP_MstRd_d,					// Bus to IP master read data bus
	input [0 : C_MST_DWIDTH/8-1]	Bus2IP_MstRd_rem,				// Bus to IP master read remainder
	input							Bus2IP_MstRd_sof_n,				// Bus to IP master read start of frame
	input							Bus2IP_MstRd_eof_n,				// Bus to IP master read end of frame
	input							Bus2IP_MstRd_src_rdy_n,			// Bus to IP master read source ready
	input							Bus2IP_MstRd_src_dsc_n,			// Bus to IP master read source discontinue
	output							IP2Bus_MstRd_dst_rdy_n,			// IP to Bus master read destination ready
	output							IP2Bus_MstRd_dst_dsc_n,			// IP to Bus master read destination discontinue

	output [0 : C_MST_DWIDTH-1]		IP2Bus_MstWr_d,					// IP to Bus master write data bus
	output [0 : C_MST_DWIDTH/8-1]	IP2Bus_MstWr_rem,				// IP to Bus master write remainder
	output							IP2Bus_MstWr_sof_n,				// IP to Bus master write start of frame
	output							IP2Bus_MstWr_eof_n,				// IP to Bus master write end of frame
	output							IP2Bus_MstWr_src_rdy_n,			// IP to Bus master write source ready
	output							IP2Bus_MstWr_src_dsc_n,			// IP to Bus master write source discontinue

	input							Bus2IP_MstWr_dst_rdy_n,			// Bus to IP master write destination ready
	input							Bus2IP_MstWr_dst_dsc_n,			// Bus to IP master write destination discontinue
	output [0 : C_NUM_INTR-1]		IP2Bus_IntrEvent				// IP to Bus interrupt event
	// -- DO NOT EDIT ABOVE THIS LINE ------------------
);
	reg			test_mode;

	wire [7:0]	gEMAC_TXD;
	wire		gEMAC_TX_EN;
	wire		gEMAC_TX_ER;
	wire		gEMAC_COL;
	wire		gEMAC_CRS;
	wire [7:0]	gEMAC_RXD;
	wire		gEMAC_RX_DV;
	wire		gEMAC_RX_ER;

	wire		tx_buff_we, tx_buff_start, tx_buff_end, tx_buff_ready, tx_buff_full;
	wire [31:0] tx_buff_data;
	wire [9:0]	tx_buff_space;

	wire		rx_buff_re, rx_buff_empty, rx_buff_valid;
	wire [31:0] rx_buff_data;
	wire [15:0] rx_buff_length;
	wire [15:0] rx_buff_status;

	reg [15:0]	pause_data;
	reg			pause_enable;
	reg			tx_pause_enable;

	wire		random_time_meet;
	reg [3:0]	max_retry;
	reg			giga_mode;
	reg			full_duplex;

	wire		arp_enable, arp_start, arp_valid;

	wire [15:0] l3_ext_status;

	reg			hit_mem_delay;

	reg [31:0]	send_adrs;
	reg [23:0]	send_len;
	reg [15:0]	send_port;
	wire		master_send_start, master_send_fin, master_send_int;
	wire		master_rec_start, master_rec_fin, master_rec_int;

	reg [31:0]	master_send_adrs;
	reg [11:0]	master_send_len;

	wire		master_cmd_idle;

	//----------------------------------------------------------------------------
	// Implementation
	//----------------------------------------------------------------------------

	wire		clk, rst_b;
	assign clk = Bus2IP_Clk;
	//assign rst_b = ~Bus2IP_Reset;
	assign rst_b = ~RST;

	/*
	アドレスマップ
	0x0000: ステータス
	0x0004: 割り込みイネーブル
	0x0008: 割り込みステータス
	
	0x0010: MAC Address[47:16]
	0x0014: MAC Address[15:0]
	0x0018: IP Address[31:0]
	
	0x001C: モード設定
				[27:24] Max Retry
				[2] Tx Pause Enable
				[1] Full Duplex
				[0] Giga Mode

	0x0020:	UDP Port 0[15:0]
	0x0024:	UDP Port 1[15:0]
	0x0028:	UDP Port 2[15:0]
	0x002C:	UDP Port 3[15:0]
	
	0x0030: ARPリクエスト・MACアドレス(Byte3〜0)
	0x0034: ARPリクエスト・MACアドレス(Byte5〜4)
	0x0038: ARPリクエスト・IPアドレス
	0x003C: ARPリクエスト・コントロール
				[0] ARP Send Request

	0x0040: PAUSEリクエスト・コントロール
				[31:16] Pause Quanta Data
				[0] Pause Send Enable
	*/

	parameter P_STATUS_REG			= 13'h0000;
	parameter P_INT_ENA_REG			= 13'h0004;
	parameter P_INT_REG				= 13'h0008;
	
	parameter P_MAC0_REG			= 13'h0010;
	parameter P_MAC1_REG			= 13'h0014;
	parameter P_IP_REG				= 13'h0018;
	parameter P_MODE_REG			= 13'h001C;
	
	parameter P_UDP0_REG			= 13'h0020;
	parameter P_UDP1_REG			= 13'h0024;
	parameter P_UDP2_REG			= 13'h0028;
	parameter P_UDP3_REG			= 13'h002C;
	
	parameter P_ARP_MAC0_REG		= 13'h0030;
	parameter P_ARP_MAC1_REG		= 13'h0034;
	parameter P_ARP_IP_REG			= 13'h0038;
	parameter P_ARP_REQ_REG			= 13'h003C;
	
	parameter P_PAUSE_REG			= 13'h0040;
	
	parameter P_RX_STATUS_REG		= 13'h0100;
	parameter P_RX_FR_STATUS_REG	= 13'h0104;
	parameter P_RX_DMA_REQ_REG		= 13'h0110;
	parameter P_RX_DMA_ADRS_REG		= 13'h0114;
	parameter P_RX_DMA_LENG_REG		= 13'h0118;

	parameter P_TX_STATUS_REG		= 13'h0200;
	parameter P_TX_DMA_REQ_REG		= 13'h0210;
	parameter P_TX_DMA_ADRS_REG		= 13'h0214;
	parameter P_TX_DMA_LENG_REG		= 13'h0218;
	
	wire		hit_wr, hit_rd;
	wire		hit_status, hit_int_ena, hit_int;
	wire		hit_my_mac0, hit_my_mac1, hit_my_ip, hit_mode;
	wire		hit_udp0, hit_udp1, hit_udp2, hit_udp3;
	wire		hit_peer_mac0, hit_peer_mac1, hit_peer_ip, hit_arp;
	wire		hit_pause;
	wire		hit_rx_status, hit_rx_fr_status, hit_rx_dma_req, hit_rx_dma_adrs, hit_rx_dma_leng;
	wire		hit_tx_status, hit_tx_dma_req, hit_tx_dma_adrs, hit_tx_dma_leng;

	// ビット変換テーブル
	// 00000000001111111111222222222233
	// 01234567890123456789012345678901
	//
	// 33222222222211111111110000000000
	// 10987654321098765432109876543210

	assign hit_rd = ( Bus2IP_CS[0] &&  Bus2IP_RNW );
	assign hit_wr = ( Bus2IP_CS[0] && ~Bus2IP_RNW );

	// アドレス・デコード
	assign hit_status		= (Bus2IP_Addr[19:31] == P_STATUS_REG);
	assign hit_int_ena		= (Bus2IP_Addr[19:31] == P_INT_ENA_REG);
	assign hit_int			= (Bus2IP_Addr[19:31] == P_INT_REG);

	assign hit_my_mac0		= (Bus2IP_Addr[19:31] == P_MAC0_REG);
	assign hit_my_mac1		= (Bus2IP_Addr[19:31] == P_MAC1_REG);
	assign hit_my_ip		= (Bus2IP_Addr[19:31] == P_IP_REG);
	assign hit_mode			= (Bus2IP_Addr[19:31] == P_MODE_REG);

	assign hit_udp0			= (Bus2IP_Addr[19:31] == P_UDP0_REG);
	assign hit_udp1			= (Bus2IP_Addr[19:31] == P_UDP1_REG);
	assign hit_udp2			= (Bus2IP_Addr[19:31] == P_UDP2_REG);
	assign hit_udp3			= (Bus2IP_Addr[19:31] == P_UDP3_REG);
	
	assign hit_peer_mac0	= (Bus2IP_Addr[19:31] == P_ARP_MAC0_REG);
	assign hit_peer_mac1	= (Bus2IP_Addr[19:31] == P_ARP_MAC1_REG);
	assign hit_peer_ip		= (Bus2IP_Addr[19:31] == P_ARP_IP_REG);
	assign hit_arp			= (Bus2IP_Addr[19:31] == P_ARP_REQ_REG);

	assign hit_pause		= (Bus2IP_Addr[19:31] == P_PAUSE_REG);

	assign hit_rx_status	= (Bus2IP_Addr[19:31] == P_RX_STATUS_REG);
	assign hit_rx_fr_status	= (Bus2IP_Addr[19:31] == P_RX_FR_STATUS_REG);
	assign hit_rx_dma_req	= (Bus2IP_Addr[19:31] == P_RX_DMA_REQ_REG);
	assign hit_rx_dma_adrs	= (Bus2IP_Addr[19:31] == P_RX_DMA_ADRS_REG);
	assign hit_rx_dma_leng	= (Bus2IP_Addr[19:31] == P_RX_DMA_LENG_REG);

	assign hit_tx_status	= (Bus2IP_Addr[19:31] == P_TX_STATUS_REG);
	assign hit_tx_dma_req	= (Bus2IP_Addr[19:31] == P_TX_DMA_REQ_REG);
	assign hit_tx_dma_adrs	= (Bus2IP_Addr[19:31] == P_TX_DMA_ADRS_REG);
	assign hit_tx_dma_leng	= (Bus2IP_Addr[19:31] == P_TX_DMA_LENG_REG);

	//////////////////////////////////////////////////////////////////////
	// Interrupt
	//////////////////////////////////////////////////////////////////////
	// Interrupt Status
	reg [31:0]	int_enable, int_status, int_status_delay;
	wire [31:0] int_req;
	assign int_req[31:0] ={ 8'd0,
							8'd0,
							7'd0, master_rec_int,
							6'd0, master_send_int, rx_buff_valid};
	// master_send_int
	generate begin
		genvar i;
		for(i=0;i<32;i=i+1)
		begin: bit
			always @(posedge clk or negedge rst_b) begin
				if(!rst_b) begin
					int_status[i] <= 1'b0;
				end else begin
					if((hit_int && Bus2IP_CS[0] && ~Bus2IP_RNW && Bus2IP_BE[3-(i/8)]) ||
						(~int_status[i])) begin
						int_status[i] <= int_req[i];
					end
				end
			end
		end
	end
	endgenerate
    wire        int_status_req;
    reg         int_status_req_delay;
    assign int_status_req = |(int_status[31:0] & int_enable[31:0]);
    always @(posedge clk or negedge rst_b) begin
        if(!rst_b) begin
            int_status_req_delay <= 1'b0;
        end else begin
            int_status_req_delay <= int_status_req;
        end
    end
    assign IP2Bus_IntrEvent = (int_status_req && ~int_status_req_delay)?1'b1:1'b0;

	// Interrupt Enable
	always @(posedge clk or negedge rst_b) begin
		if(!rst_b) begin
			int_enable[31:0] <= 32'd0;
		end else begin
			if(hit_int_ena && hit_wr) begin
				if(Bus2IP_BE[0]) int_enable[31:24] <= Bus2IP_Data[ 0: 7];
				if(Bus2IP_BE[1]) int_enable[23:16] <= Bus2IP_Data[ 8:15];
				if(Bus2IP_BE[2]) int_enable[15: 8] <= Bus2IP_Data[16:23];
				if(Bus2IP_BE[3]) int_enable[ 7: 0] <= Bus2IP_Data[24:31];
			end
		end
	end

	//////////////////////////////////////////////////////////////////////
	// Station Configuration
	//////////////////////////////////////////////////////////////////////
	reg [47:0]	my_mac_address;
	reg [31:0]	my_ip_address;
	wire [47:0] peer_mac_address;
	reg [31:0]	peer_ip_address;
	reg [15:0]	udp_port0, udp_port1, udp_port2, udp_port3;
	always @(posedge clk or negedge rst_b) begin
		if(!rst_b) begin
			my_mac_address[47:0]	<= DEFAULT_MY_MAC_ADRS;
			my_ip_address[31:0]		<= DEFAULT_MY_IP_ADRS;
			peer_ip_address[31:0]	<= DEFAULT_PEER_IP_ADRS;
			max_retry[3:0]			<= 8'd8;
			tx_pause_enable			<= 1'b0;
			full_duplex				<= 1'b1;
			giga_mode				<= 1'b0;
			pause_data[15:0]		<= 16'd0;
			test_mode				<= 1'b0;
			pause_enable			<= 1'b0;
			udp_port0[15:0]			<= 16'd0;
			udp_port1[15:0]			<= 16'd0;
			udp_port2[15:0]			<= 16'd0;
			udp_port3[15:0]			<= 16'd0;
		end else begin
			if(hit_my_mac0 && hit_wr) begin
				if(Bus2IP_BE[0]) my_mac_address[31:24] <= Bus2IP_Data[ 0: 7];
				if(Bus2IP_BE[1]) my_mac_address[23:16] <= Bus2IP_Data[ 8:15];
				if(Bus2IP_BE[2]) my_mac_address[15: 8] <= Bus2IP_Data[16:23];
				if(Bus2IP_BE[3]) my_mac_address[ 7: 0] <= Bus2IP_Data[24:31];
			end
			if(hit_my_mac1 && hit_wr) begin
				if(Bus2IP_BE[2]) my_mac_address[47:40] <= Bus2IP_Data[16:23];
				if(Bus2IP_BE[3]) my_mac_address[39:32] <= Bus2IP_Data[24:31];
			end
			if(hit_my_ip && hit_wr) begin
				if(Bus2IP_BE[0]) my_ip_address[31:24] <= Bus2IP_Data[ 0: 7];
				if(Bus2IP_BE[1]) my_ip_address[23:16] <= Bus2IP_Data[ 8:15];
				if(Bus2IP_BE[2]) my_ip_address[15: 8] <= Bus2IP_Data[16:23];
				if(Bus2IP_BE[3]) my_ip_address[ 7: 0] <= Bus2IP_Data[24:31];
			end
			// Mode
			//  [27:24] Max Retry
			//  [2] Tx Pause Enable
			//  [1] Full Duplex
			//  [0] Giga Mode
			if(hit_mode && hit_wr) begin
				if(Bus2IP_BE[0]) max_retry[3:0] <= Bus2IP_Data[ 4: 7];
				if(Bus2IP_BE[3]) begin
					test_mode		<= Bus2IP_Data[28];
					tx_pause_enable <= Bus2IP_Data[29];
					full_duplex		<= Bus2IP_Data[30];
					giga_mode		<= Bus2IP_Data[31];
				end
			end
			// ARP IP Address
			if(hit_peer_ip && hit_wr) begin
				if(Bus2IP_BE[0]) peer_ip_address[31:24] <= Bus2IP_Data[ 0: 7];
				if(Bus2IP_BE[1]) peer_ip_address[23:16] <= Bus2IP_Data[ 8:15];
				if(Bus2IP_BE[2]) peer_ip_address[15: 8] <= Bus2IP_Data[16:23];
				if(Bus2IP_BE[3]) peer_ip_address[ 7: 0] <= Bus2IP_Data[24:31];
			end
			// PUASE Request
			//  [31:16] Pause Quanta Data
			//  [0] Pause Send Enable
			if(hit_pause && hit_wr) begin
				if(Bus2IP_BE[0]) pause_data[15:8]	<= Bus2IP_Data[ 0: 7];
				if(Bus2IP_BE[1]) pause_data[ 7:0]	<= Bus2IP_Data[ 8:15];
				if(Bus2IP_BE[3]) pause_enable		<= Bus2IP_Data[31];
			end
			
			if(hit_udp0 && hit_wr) begin
				if(Bus2IP_BE[2]) udp_port0[15:8]	<= Bus2IP_Data[16:23];
				if(Bus2IP_BE[3]) udp_port0[7:0]		<= Bus2IP_Data[24:31];
			end
			if(hit_udp1 && hit_wr) begin
				if(Bus2IP_BE[2]) udp_port1[15:8]	<= Bus2IP_Data[16:23];
				if(Bus2IP_BE[3]) udp_port1[7:0]		<= Bus2IP_Data[24:31];
			end
			if(hit_udp2 && hit_wr) begin
				if(Bus2IP_BE[2]) udp_port2[15:8]	<= Bus2IP_Data[16:23];
				if(Bus2IP_BE[3]) udp_port2[7:0]		<= Bus2IP_Data[24:31];
			end
			if(hit_udp3 && hit_wr) begin
				if(Bus2IP_BE[2]) udp_port3[15:8]	<= Bus2IP_Data[16:23];
				if(Bus2IP_BE[3]) udp_port3[7:0]		<= Bus2IP_Data[24:31];
			end
		end
	end
	// ARP Request
	assign arp_start	= (hit_arp	&& hit_wr && Bus2IP_BE[3] && Bus2IP_Data[31]);

	assign IP2Bus_WrAck = hit_wr;

	//////////////////////////////////////////////////////////////////////
	// Packet Transimt
	//////////////////////////////////////////////////////////////////////
	// Send Config

	// Send Control
	reg [3:0]	send_state;
	parameter S_SEND_IDLE			= 4'd0;
	parameter S_SEND_START			= 4'd1;
	parameter S_SEND_START_FRAME	= 4'd2;
	parameter S_SEND_START_MASTER	= 4'd3;
	parameter S_SEND_WAIT			= 4'd4;
	parameter S_SEND_FIN			= 4'd5;
	parameter S_SEND_INT			= 4'd6;

	always @(posedge clk or negedge rst_b) begin
		if(!rst_b) begin
			send_state <= S_SEND_IDLE;
			send_adrs	<= 32'd0;
			send_len	<= 24'd0;
		end else begin
			case(send_state)
			S_SEND_IDLE: begin
				if(hit_tx_dma_req && hit_wr) begin
					send_state <= S_SEND_START;
				end
				// Send Address
				if(hit_tx_dma_adrs && hit_wr) begin
					if(Bus2IP_BE[0]) send_adrs[31:24] <= Bus2IP_Data[ 0: 7];
					if(Bus2IP_BE[1]) send_adrs[23:16] <= Bus2IP_Data[ 8:15];
					if(Bus2IP_BE[2]) send_adrs[15: 8] <= Bus2IP_Data[16:23];
					if(Bus2IP_BE[3]) send_adrs[ 7: 0] <= Bus2IP_Data[24:31];
				end
				// Send Length
				if(hit_tx_dma_leng && hit_wr) begin
					if(Bus2IP_BE[1]) send_len[23:16] <= Bus2IP_Data[ 8:15];
					if(Bus2IP_BE[2]) send_len[15: 8] <= Bus2IP_Data[16:23];
					if(Bus2IP_BE[3]) send_len[ 7: 0] <= Bus2IP_Data[24:31];
				end
			end
			S_SEND_START: begin
				send_state <= S_SEND_START_FRAME;
				master_send_adrs[31:0]	<= send_adrs[31:0];
//				// インクリメンタル・バースト転送に対応するならコメントを外す
//				if(send_len[23:0] > 24'd1472) begin
//					master_send_len[11:0]	<= 12'd1472;
//					send_adrs[31:0]			<= send_adrs[31:0] + 32'd1472;
//					send_len[23:0]			<= send_len[23:0] - 24'd1472;
//				end else begin
					master_send_len[11:0]	<= send_len[11:0];
//					send_len[23:0]			<= 24'd0;
//				end
			end
			S_SEND_START_FRAME: begin
				// Txバッファに空きができた場合、データ転送を開始する。
				if((send_len[11:0] <= { tx_buff_space[9:0], 2'b00}) && (tx_buff_ready == 1'b1)) begin
					send_state <= S_SEND_START_MASTER;
				end
			end
			S_SEND_START_MASTER: begin
				if(master_cmd_idle) send_state <= S_SEND_WAIT;
			end
			S_SEND_WAIT: begin
				if(master_send_fin) begin
					send_state <= S_SEND_FIN;
				end
			end
			S_SEND_FIN: begin
//				// インクリメンタル・バースト転送に対応するならコメントを外す
//				if(send_len[23:0] != 24'd0) begin
//					send_state <= S_SEND_START;
//				end else begin
					send_state <= S_SEND_INT;
//				end
			end
			S_SEND_INT: begin
				send_state		<= S_SEND_IDLE;
			end
			default: begin
				send_state <= S_SEND_IDLE;
			end
			endcase
		end
	end
	assign master_send_start	= (send_state == S_SEND_START_MASTER)?1'b1:1'b0;
	assign master_send_int		= (send_state == S_SEND_INT)?1'b1:1'b0;
	assign master_send_busy		= (send_state != S_SEND_IDLE)?1'b1:1'b0;
	assign master_send_stanby	= (send_state == S_SEND_IDLE)?1'b1:1'b0;

	//////////////////////////////////////////////////////////////////////
	// Packet Receive
	//////////////////////////////////////////////////////////////////////
	// Rec Config
	reg [31:0]	rec_adrs;
	reg [23:0]	rec_len;
	reg [15:0]	rec_port;
	reg [11:0]	rec_len_remainder;

	reg [31:0]	master_rec_adrs;
	reg [11:0]	master_rec_len;

	reg [3:0]	rec_state;
	parameter S_REC_IDLE	= 4'd0;
	parameter S_REC_START	= 4'd1;
	parameter S_REC_START_MASTER	= 4'd2;
	parameter S_REC_WAIT	= 4'd3;
	parameter S_REC_FIN	= 4'd4;
	parameter S_REC_INT	= 4'd5;
	parameter S_REC_DUMMY_READ = 4'd6;

	always @(posedge clk or negedge rst_b) begin
		if(!rst_b) begin
			rec_state			<= S_REC_IDLE;
			rec_adrs			<= 32'd0;
			rec_len				<= 24'd0;
			rec_len_remainder	<= 12'd0;
		end else begin
			case(rec_state)
			S_REC_IDLE: begin
				if((hit_rx_dma_req && hit_wr) && (rx_buff_valid)) begin
					// Receiveの発動はrx_buff_validが立っていなければいけません。
					rec_state	<= S_REC_START;
				end
				// Receive Address
				if(hit_rx_dma_adrs && hit_wr) begin
					if(Bus2IP_BE[0]) rec_adrs[31:24] <= Bus2IP_Data[ 0: 7];
					if(Bus2IP_BE[1]) rec_adrs[23:16] <= Bus2IP_Data[ 8:15];
					if(Bus2IP_BE[2]) rec_adrs[15: 8] <= Bus2IP_Data[16:23];
					if(Bus2IP_BE[3]) rec_adrs[ 7: 0] <= Bus2IP_Data[24:31];
				end
				// Receive Length
				if(hit_rx_dma_leng && hit_wr) begin
					if(Bus2IP_BE[1]) rec_len[23:16] <= Bus2IP_Data[ 8:15];
					if(Bus2IP_BE[2]) rec_len[15: 8] <= Bus2IP_Data[16:23];
					if(Bus2IP_BE[3]) rec_len[ 7: 0] <= Bus2IP_Data[24:31];
				end
			end
			S_REC_START: begin
				master_rec_adrs[31:0]		<= rec_adrs[31:0];
				rec_adrs[31:0]				<= rec_adrs[31:0] + {20'd0, rx_buff_length[11:0]};
				if(rec_len[23:0] >= {12'd0, rx_buff_length[11:0]}) begin
					rec_state				<= S_REC_START_MASTER;
					master_rec_len[11:0]	<= rx_buff_length[11:0];
					rec_len[23:0]			<= rec_len[23:0] - {12'd0, rx_buff_length[11:0]};
					rec_len_remainder[11:0]	<= 12'd0;
				end else if(rec_len[23:0] > 24'd0) begin
					rec_state				<= S_REC_START_MASTER;
					master_rec_len[11:0]	<= rec_len[11:0];
					rec_len[23:0]			<= 24'd0;
					rec_len_remainder[11:0]	<= rx_buff_length[11:0] - rec_len[11:0];
				end else begin
					rec_state				<= S_REC_DUMMY_READ;
					master_rec_len[11:0]	<= 12'd0;
					rec_len[23:0]			<= 24'd0;
					rec_len_remainder[11:0]	<= rx_buff_length[11:0];
				end
			end
			S_REC_START_MASTER: begin
				if(master_cmd_idle) rec_state <= S_REC_WAIT;
			end
			S_REC_WAIT: begin
				if(master_rec_fin) begin
					rec_state <= S_REC_FIN;
				end
			end
			S_REC_FIN: begin
				if(rec_len_remainder[11:0] > 12'd0) begin
					rec_state <= S_REC_DUMMY_READ;
				end else begin
					rec_state <= S_REC_IDLE;
				end
			end
			S_REC_DUMMY_READ: begin
				rec_len_remainder[11:0] <= rec_len_remainder[11:0] - 12'd4;
				if(rec_len_remainder[11:0] <= 12'd4) begin
					rec_state <= S_REC_IDLE;
				end
			end
			default: begin
				rec_state <= S_REC_IDLE;
			end
			endcase
		end
	end
	assign master_rec_start 	= (rec_state == S_REC_START_MASTER)?1'b1:1'b0;
	assign master_rec_int		= (rec_state == S_REC_FIN)?1'b1:1'b0;
	assign master_rec_busy		= (rec_state != S_REC_IDLE)?1'b1:1'b0;
	assign master_rec_stanby	= (rec_state == S_REC_IDLE)?1'b1:1'b0;

	//////////////////////////////////////////////////////////////////////
	// Master Command
	//////////////////////////////////////////////////////////////////////
	reg			IP2Bus_MstRd_Req_o;
	reg			IP2Bus_MstWr_Req_o;
	reg			IP2Bus_Mst_Type_o;
	reg [0:31]	IP2Bus_Mst_Addr_o;
	reg [0:3]	IP2Bus_Mst_BE_o;
	reg [0:11]	IP2Bus_Mst_Length_o;
	reg			IP2Bus_Mst_Lock_o;
	reg			IP2Bus_Mst_Reset_o;

	reg [3:0]	master_cmd_state;
	parameter S_MSTCMD_IDLE			= 4'd0;
	parameter S_MSTCMD_SEND_REQUEST = 4'd1;
	parameter S_MSTCMD_SEND_FIN		= 4'd2;
	parameter S_MSTCMD_REC_REQUEST = 4'd3;
	parameter S_MSTCMD_REC_FIN		= 4'd4;
	parameter S_MSTCMD_REC1_REQUEST = 4'd5;
	parameter S_MSTCMD_REC1_FIN		= 4'd6;

	always @(posedge clk or negedge rst_b) begin
		if(!rst_b) begin
			master_cmd_state			<= S_MSTCMD_IDLE;
			IP2Bus_MstRd_Req_o			<= 1'b0;			// Read Request
			IP2Bus_MstWr_Req_o			<= 1'b0;			// Write Request
			IP2Bus_Mst_Type_o			<= 1'b0;			// Burst Request
			IP2Bus_Mst_Addr_o[0:31]		<= 32'h0000_0000;	// Address
			IP2Bus_Mst_BE_o[0:3]		<= 4'h0;			// Byte Enable
			IP2Bus_Mst_Length_o[0:11] 	<= 12'd0;			// Burst Length
			IP2Bus_Mst_Lock_o			<= 1'b0;			// Lock Signal
			IP2Bus_Mst_Reset_o			<= 1'b0;			// Reset Signal
		end else begin
			case(master_cmd_state)
				S_MSTCMD_IDLE: begin
					if(master_send_start) begin
						master_cmd_state			<= S_MSTCMD_SEND_REQUEST;
						IP2Bus_MstRd_Req_o			<= 1'b1;					// Read Request
						IP2Bus_MstWr_Req_o			<= 1'b0;					// Write Request
						IP2Bus_Mst_Type_o			<= 1'b1;					// Burst Request
						IP2Bus_Mst_Addr_o[0:31]		<= master_send_adrs[31:0];	// Address
						IP2Bus_Mst_BE_o[0:3]		<= 4'hF;					// Byte Enable
						IP2Bus_Mst_Length_o[0:11]	<= master_send_len[11:0];	// Burst Length
						IP2Bus_Mst_Lock_o			<= 1'b0;					// Lock Signal
						IP2Bus_Mst_Reset_o			<= 1'b0;					// Reset Signal
					end else if(master_rec_start) begin
						master_cmd_state			<= S_MSTCMD_REC_REQUEST;
						IP2Bus_MstRd_Req_o			<= 1'b0;					// Read Request
						IP2Bus_MstWr_Req_o			<= 1'b1;					// Write Request
						IP2Bus_Mst_Type_o			<= 1'b1;					// Burst Request
						IP2Bus_Mst_Addr_o[0:31]		<= master_rec_adrs[31:0];	// Address
						IP2Bus_Mst_BE_o[0:3]		<= 4'hF;					// Byte Enable
						IP2Bus_Mst_Length_o[0:11]	<= master_rec_len[11:0];	// Burst Length
						IP2Bus_Mst_Lock_o			<= 1'b0;					// Lock Signal
						IP2Bus_Mst_Reset_o			<= 1'b0;					// Reset Signal
					end
				end
				S_MSTCMD_SEND_REQUEST: begin
					if(Bus2IP_Mst_CmdAck) begin
						master_cmd_state			<= S_MSTCMD_SEND_FIN;
						IP2Bus_MstRd_Req_o			<= 1'b0;			// Read Request
						IP2Bus_MstWr_Req_o			<= 1'b0;			// Write Request
						IP2Bus_Mst_Type_o			<= 1'b0;			// Burst Request
						IP2Bus_Mst_Addr_o[0:31]		<= 32'h0000_0000;	// Address
						IP2Bus_Mst_BE_o[0:3]		<= 4'h0;			// Byte Enable
						IP2Bus_Mst_Length_o[0:11]	<= 12'd0;			// Burst Length
						IP2Bus_Mst_Lock_o			<= 1'b0;			// Lock Signal
						IP2Bus_Mst_Reset_o			<= 1'b0;			// Reset Signal
					end
				end
				S_MSTCMD_SEND_FIN: begin
					// wait last a cmplt.
					if(Bus2IP_Mst_Cmplt) begin
						master_cmd_state <= S_MSTCMD_IDLE;
					end
				end
				S_MSTCMD_REC_REQUEST: begin
					// rec send a master
					if(Bus2IP_Mst_CmdAck) begin
						master_cmd_state <= S_MSTCMD_REC_FIN;
						IP2Bus_MstRd_Req_o			<= 1'b0;			// Read Request
						IP2Bus_MstWr_Req_o			<= 1'b0;			// Write Request
						IP2Bus_Mst_Type_o			<= 1'b0;			// Burst Request
						IP2Bus_Mst_Addr_o[0:31]		<= 32'h0000_0000;	// Address
						IP2Bus_Mst_BE_o[0:3]		<= 4'h0;			// Byte Enable
						IP2Bus_Mst_Length_o[0:11]	<= 12'd0;			// Burst Length
						IP2Bus_Mst_Lock_o			<= 1'b0;			// Lock Signal
						IP2Bus_Mst_Reset_o			<= 1'b0;			// Reset Signal
					end
				end
				S_MSTCMD_REC_FIN: begin
					// wait last a cmplt.
					if(Bus2IP_Mst_Cmplt) begin
						master_cmd_state <= S_MSTCMD_IDLE;
					end
				end
				default: begin
					master_cmd_state <= S_MSTCMD_IDLE;
				end
			endcase
		end
	end

	assign IP2Bus_MstRd_Req		= IP2Bus_MstRd_Req_o;
	assign IP2Bus_MstWr_Req		= IP2Bus_MstWr_Req_o;
	assign IP2Bus_Mst_Type		= IP2Bus_Mst_Type_o;
	assign IP2Bus_Mst_Addr		= IP2Bus_Mst_Addr_o;
	assign IP2Bus_Mst_BE		= IP2Bus_Mst_BE_o;
	assign IP2Bus_Mst_Length	= IP2Bus_Mst_Length_o;
	assign IP2Bus_Mst_Lock		= IP2Bus_Mst_Lock_o;
	assign IP2Bus_Mst_Reset		= IP2Bus_Mst_Reset_o;

	//////////////////////////////////////////////////////////////////////
	// Master Data
	//////////////////////////////////////////////////////////////////////
	reg			IP2Bus_MstRd_dst_rdy_n_o;
	reg			IP2Bus_MstRd_dst_dsc_n_o;
	reg			IP2Bus_MstWr_src_rdy_n_o;
	reg			IP2Bus_MstWr_sof_n_o;
	reg			IP2Bus_MstWr_eof_n_o;
	reg [11:0]	master_data_len;

	reg [3:0]	master_data_state;
	parameter S_MSTDATA_IDLE		= 4'd0;
	parameter S_MSTDATA_SEND_PREV	= 4'd1;
	parameter S_MSTDATA_SEND_REQ	= 4'd2;
	parameter S_MSTDATA_SEND_DATA	= 4'd3;
	parameter S_MSTDATA_SEND_FIN	= 4'd4;
	parameter S_MSTDATA_REC_REQ		= 4'd5;
	parameter S_MSTDATA_REC_START	= 4'd6;
	parameter S_MSTDATA_REC_DATA	= 4'd7;
	parameter S_MSTDATA_REC_FIN		= 4'd8;
	parameter S_MSTDATA_WAIT_CMPLT	= 4'd9;

	always @(posedge clk or negedge rst_b) begin
		if(!rst_b) begin
			master_data_state			<= S_MSTDATA_IDLE;
			IP2Bus_MstRd_dst_rdy_n_o	<= 1'b1;
			IP2Bus_MstRd_dst_dsc_n_o	<= 1'b1;
			IP2Bus_MstWr_sof_n_o		<= 1'b1;
			IP2Bus_MstWr_eof_n_o		<= 1'b1;
			IP2Bus_MstWr_src_rdy_n_o	<= 1'b1;
		end else begin
			case(master_data_state)
				S_MSTDATA_IDLE: begin
					if(master_send_start) begin
						master_data_state			<= S_MSTDATA_SEND_PREV;
					end else if(master_rec_start) begin
						master_data_state			<= S_MSTDATA_REC_REQ;
						master_data_len[11:0]		<= master_rec_len[11:0];
					end
				end
				// Send Process
				S_MSTDATA_SEND_PREV: begin
					master_data_state				<= S_MSTDATA_SEND_REQ;
				end
				S_MSTDATA_SEND_REQ: begin
					master_data_state				<= S_MSTDATA_SEND_DATA;
					IP2Bus_MstRd_dst_rdy_n_o		<= 1'b0;
				end
				S_MSTDATA_SEND_DATA: begin
					if(!Bus2IP_MstRd_eof_n) begin
						master_data_state			<= S_MSTDATA_SEND_FIN;
						IP2Bus_MstRd_dst_rdy_n_o	<= 1'b1;
					end
				end
				S_MSTDATA_SEND_FIN: begin
					master_data_state				<= S_MSTDATA_WAIT_CMPLT;
				end
				// Receive Process
				S_MSTDATA_REC_REQ: begin
					master_data_state				<= S_MSTDATA_REC_START;
					IP2Bus_MstWr_src_rdy_n_o		<= 1'b0;
					IP2Bus_MstWr_sof_n_o			<= 1'b0;
				end
				S_MSTDATA_REC_START: begin
					if(!Bus2IP_MstWr_dst_rdy_n) begin
						master_data_state			<= S_MSTDATA_REC_DATA;
						IP2Bus_MstWr_sof_n_o		<= 1'b1;
						master_data_len[11:0]		<= master_data_len[11:0] - 12'd4;
					end
				end
				S_MSTDATA_REC_DATA: begin
					if(!Bus2IP_MstWr_dst_rdy_n) begin
						if(master_data_len[11:0] <= 12'd4) begin
							master_data_state		<= S_MSTDATA_REC_FIN;
							IP2Bus_MstWr_eof_n_o	<= 1'b0;
						end
						master_data_len[11:0]		<= master_data_len[11:0] - 12'd4;
					end
				end
				S_MSTDATA_REC_FIN: begin
					if(!Bus2IP_MstWr_dst_rdy_n) begin
						master_data_state			<= S_MSTDATA_WAIT_CMPLT;
						IP2Bus_MstWr_src_rdy_n_o	<= 1'b1;
						IP2Bus_MstWr_eof_n_o		<= 1'b1;
					end
				end
				S_MSTDATA_WAIT_CMPLT: begin
					// wait last a cmplt.
					if(Bus2IP_Mst_Cmplt) begin
						master_data_state			<= S_MSTDATA_IDLE;
					end
				end
				default: begin
					master_data_state				<= S_MSTDATA_IDLE;
				end
			endcase
		end
	end

	assign master_send_fin	= (master_data_state == S_MSTDATA_SEND_FIN)?1'b1:1'b0;
	assign master_rec_fin	= (master_data_state == S_MSTDATA_REC_FIN)?1'b1:1'b0;
	assign master_cmd_idle	= ((master_cmd_state == S_MSTCMD_IDLE) && (master_data_state == S_MSTDATA_IDLE))?1'b1:1'b0;

	// Transmit
	wire		send_data_valid, send_data_start, send_data_end;
	wire [31:0]	send_data;
	assign send_data_valid	= (~Bus2IP_MstRd_src_rdy_n) || (master_data_state == S_MSTDATA_SEND_PREV);
	assign send_data_start	= (master_data_state == S_MSTDATA_SEND_PREV)?1'b1:1'b0;
	assign send_data_end	= !Bus2IP_MstRd_eof_n;
	assign send_data[31:0]	= (!send_data_start)?Bus2IP_MstRd_d[0:31]:{4'd0, master_send_len[11:0], 16'd0};

	// Receive
	assign rec_data_read	= ((((master_data_state == S_MSTDATA_REC_START) || (master_data_state == S_MSTDATA_REC_DATA) || (master_data_state == S_MSTDATA_REC_FIN)) && ~Bus2IP_MstWr_dst_rdy_n) || (rec_state == S_REC_DUMMY_READ))?1'b1:1'b0;
	assign IP2Bus_MstWr_d[0:31] = rx_buff_data[31:0];

	assign IP2Bus_MstWr_src_dsc_n	= 1'b1;
	assign IP2Bus_Error				= 1'b0;
	assign IP2Bus_MstWr_rem			= 4'd0;

	assign IP2Bus_MstRd_dst_rdy_n	= IP2Bus_MstRd_dst_rdy_n_o;
	assign IP2Bus_MstRd_dst_dsc_n	= IP2Bus_MstRd_dst_dsc_n_o;
	assign IP2Bus_MstWr_src_rdy_n	= IP2Bus_MstWr_src_rdy_n_o;
	assign IP2Bus_MstWr_sof_n		= IP2Bus_MstWr_sof_n_o;
	assign IP2Bus_MstWr_eof_n		= IP2Bus_MstWr_eof_n_o;

	//////////////////////////////////////////////////////////////////////
	// Convert
	//////////////////////////////////////////////////////////////////////
	// Transmit
	assign tx_buff_we		= send_data_valid;
	assign tx_buff_start	= send_data_start;
	assign tx_buff_end		= send_data_end;
	assign tx_buff_data		= send_data;
// tx_buff_full

	assign rx_buff_re		= rec_data_read;
	
// rx_buff_empty
// rx_buff_status

	
	//////////////////////////////////////////////////////////////////////
	// Slave Read
	//////////////////////////////////////////////////////////////////////
	always @(posedge clk or negedge rst_b) begin
		if(!rst_b) begin
			hit_mem_delay <= 1'b0;
		end else begin
			hit_mem_delay <= hit_rd;
		end
	end
	assign IP2Bus_RdAck = (hit_mem_delay)?1'b1:1'b0;
	
	wire [31:0] pause_status, mode_status, arp_status, status, rx_status, rx_fr_status, rx_req, tx_status, tx_req;
	assign pause_status[31:0] =
	{
		pause_data[15:0],
		15'd0,
		pause_enable
	};
	assign arp_status[31:0]	=
	{
		30'd0, arp_enable, arp_valid
	};
	assign mode_status[31:0] =
	{
		4'd0, max_retry[3:0],
		16'd0,
		5'd0, tx_pause_enable, full_duplex, giga_mode
	};
	
	
	assign status[31:0] =
	{
		28'd0,
		master_send_stanby, master_send_busy, master_rec_stanby, master_rec_busy
	};
	assign rx_status[31:0] =
	{
		master_rec_busy,
		29'd0,
		rx_buff_empty, rx_buff_valid
	};
	assign rx_fr_status[31:0] =
	{
		rx_buff_status[15:0],
		rx_buff_length[15:0]
	};
	assign rx_req[31:0] =
	{
		31'd0, master_rec_busy
	};
	assign tx_status[31:0] =
	{
		master_send_busy, 6'd0, tx_buff_full,
		16'd0,
		6'd0, tx_buff_space[9:0]
	};
	assign tx_req[31:0] =
	{
		31'd0, master_send_busy
	};

	assign IP2Bus_Data[0:31] =	((hit_rd && hit_int)?			int_status[31:0]				:32'd0) |
								((hit_rd && hit_int_ena)?		int_enable[31:0]				:32'd0) |
								((hit_rd && hit_status)?		status[31:0]					:32'd0) |
								
								((hit_rd && hit_my_mac0)?		my_mac_address[31:0]			:32'd0) |
								((hit_rd && hit_my_mac1)?		{16'd0, my_mac_address[47:32]}	:32'd0) |
								((hit_rd && hit_my_ip)?			my_ip_address[31:0]				:32'd0) |
								((hit_rd && hit_mode)?			mode_status[31:0]				:32'd0) |

								((hit_rd && hit_udp0)?			{16'd0, udp_port0[15:0]}		:32'd0) |
								((hit_rd && hit_udp1)?			{16'd0, udp_port1[15:0]}		:32'd0) |
								((hit_rd && hit_udp2)?			{16'd0, udp_port2[15:0]}		:32'd0) |
								((hit_rd && hit_udp3)?			{16'd0, udp_port3[15:0]}		:32'd0) |
								
								((hit_rd && hit_peer_mac0)?		peer_mac_address[31:0]			:32'd0) |
								((hit_rd && hit_peer_mac1)?		{16'd0, peer_mac_address[47:32]}:32'd0) |
								((hit_rd && hit_peer_ip)?		peer_ip_address[31:0]			:32'd0) |
								((hit_rd && hit_arp)?			arp_status[31:0]				:32'd0) |

								((hit_rd && hit_pause)?			pause_status[31:0]				:32'd0) |

								((hit_rd && hit_rx_status)?		rx_status[31:0]					:32'd0) |
								((hit_rd && hit_rx_fr_status)?	rx_fr_status[31:0]				:32'd0) |
								((hit_rd && hit_rx_dma_req)?	rx_req[31:0]					:32'd0) |
								((hit_rd && hit_rx_dma_adrs)?	rec_adrs[31:0]					:32'd0) |
								((hit_rd && hit_rx_dma_leng)?	{8'd0, rec_len[23:0]}			:32'd0) |
								
								((hit_rd && hit_tx_status)?		tx_status[31:0]					:32'd0) |
								((hit_rd && hit_tx_dma_req)?	tx_req[31:0]					:32'd0) |
								((hit_rd && hit_tx_dma_adrs)?	send_adrs[31:0]					:32'd0) |
								((hit_rd && hit_tx_dma_leng)?	{8'd0, send_len[23:0]}			:32'd0) |
								
								32'd0
								;

	// ------------------------------------------------------------
	// Module
	// ------------------------------------------------------------
	// GEMAC Modules
	aq_gemac_ip 
	#(
		.USE_MIIM			( USE_MIIM		)
	)
	u_aq_gemac_ip(
		.RST_N				( rst_b			),
		.SYS_CLK			( Bus2IP_Clk	),

		// GEMAC Interface
		.EMAC_TX_CLK		( EMAC_TX_CLK	),
		.EMAC_TXD			( EMAC_TXD		),
		.EMAC_TX_EN			( EMAC_TX_EN	),
		.EMAC_TX_ER			( EMAC_TX_ER	),
		.EMAC_COL			( EMAC_COL		),
		.EMAC_CRS			( EMAC_CRS		),
		.EMAC_RX_CLK		( EMAC_RX_CLK	),
		.EMAC_RXD			( EMAC_RXD		),
		.EMAC_RX_DV			( EMAC_RX_DV	),
		.EMAC_RX_ER			( EMAC_RX_ER	),

		// GEMAC MIIM Interface
		.MIIM_MDIO_CLK		(),
		.MIIM_MDIO_DI		(),
		.MIIM_MDIO_DO		(),
		.MIIM_MDIO_T		(),

		.MIIM_REQUEST		(),
		.MIIM_WRITE			(),
		.MIIM_PHY_ADDRESS	(),
		.MIIM_REG_ADDRESS	(),
		.MIIM_WDATA			(),
		.MIIM_RDATA			(),
		.MIIM_BUSY			(),

		// RX Buffer Interface
		.RX_BUFF_RE			( rx_buff_re		),
		.RX_BUFF_DATA		( rx_buff_data		),
		.RX_BUFF_EMPTY		( rx_buff_empty		),
		.RX_BUFF_VALID		( rx_buff_valid		),
		.RX_BUFF_LENGTH		( rx_buff_length	),
		.RX_BUFF_STATUS		( rx_buff_status	),

		// TX Buffer Interface
		.TX_BUFF_WE			( tx_buff_we		),
		.TX_BUFF_START		( tx_buff_start		),
		.TX_BUFF_END		( tx_buff_end		),
		.TX_BUFF_READY		( tx_buff_ready		),
		.TX_BUFF_DATA		( tx_buff_data		),
		.TX_BUFF_FULL		( tx_buff_full		),
		.TX_BUFF_SPACE		( tx_buff_space		),

		// From CPU
		.PAUSE_QUANTA_DATA	(),
		.PAUSE_SEND_ENABLE	(),
		.TX_PAUSE_ENABLE	(),

		.PEER_MAC_ADDRESS	( peer_mac_address	),
		.PEER_IP_ADDRESS	( peer_ip_address	),
		.MY_MAC_ADDRESS		( my_mac_address	),
		.MY_IP_ADDRESS		( my_ip_address		),

		.ARPC_ENABLE		( arpc_enable		),
		.ARPC_REQUEST		( arpc_request		),
		.ARPC_VALID			( arpc_valid		),

		.MAX_RETRY			( max_retry			),
		.GIG_MODE			( giga_mode			),
		.FULL_DUPLEX		( full_duplex		),

		// Send UDP
		.SEND_REQUEST		( SEND_REQUEST			),
		.SEND_LENGTH		( SEND_LENGTH			),
		.SEND_BUSY			( SEND_BUSY				),
		.SEND_MAC_ADDRESS	( SEND_MAC_ADDRESS		),
		.SEND_IP_ADDRESS	( SEND_IP_ADDRESS		),
		.SEND_DST_PORT		( SEND_DST_PORT			),
		.SEND_SRC_PORT		( SEND_SRC_PORT			),
		.SEND_DATA_VALID	( SEND_DATA_VALID		),
		.SEND_DATA_READ		( SEND_DATA_READ		),
		.SEND_DATA			( SEND_DATA				),

		// Receive UDP
		.REC_REQUEST		( REC_REQUEST			),
		.REC_LENGTH			( REC_LENGTH			),
		.REC_BUSY			( REC_BUSY				),
		.REC_DST_PORT0		( udp_port0[15:0]		),
		.REC_DST_PORT1		( udp_port1[15:0]		),
		.REC_DST_PORT2		( udp_port2[15:0]		),
		.REC_DST_PORT3		( udp_port3[15:0]		),
		.REC_DATA_VALID		( REC_DATA_VALID[3:0]	),
		.REC_SRC_MAC		( REC_SRC_MAC[47:0]		),	// 130315 add ENDO
		.REC_SRC_IP			( REC_SRC_IP[31:0]		),	// 130315 add ENDO
		.REC_SRC_PORT		( REC_SRC_PORT[15:0]	),	// 130315 add ENDO
		.REC_DATA_READ		( REC_DATA_READ			),
		.REC_DATA			( REC_DATA				)
	);

endmodule
