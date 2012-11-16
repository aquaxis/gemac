/*
* PROJECT: AQUAXIS Giga Ethernet MAC
* ----------------------------------------------------------------------
*
* aq_gemac_ipic.v
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
//----------------------------------------------------------------------------
// user_logic.vhd - module
//----------------------------------------------------------------------------
//
// ***************************************************************************
// ** Copyright (c) 1995-2008 Xilinx, Inc.  All rights reserved.            **
// **                                                                       **
// ** Xilinx, Inc.                                                          **
// ** XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"         **
// ** AS A COURTESY TO YOU, SOLELY FOR USE IN DEVELOPING PROGRAMS AND       **
// ** SOLUTIONS FOR XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE,        **
// ** OR INFORMATION AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,        **
// ** APPLICATION OR STANDARD, XILINX IS MAKING NO REPRESENTATION           **
// ** THAT THIS IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,     **
// ** AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE      **
// ** FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY              **
// ** WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE               **
// ** IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR        **
// ** REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF       **
// ** INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS       **
// ** FOR A PARTICULAR PURPOSE.                                             **
// **                                                                       **
// ***************************************************************************
//
//----------------------------------------------------------------------------
// Filename:          user_logic.vhd
// Version:           1.00.a
// Description:       User logic module.
// Date:              Thu Aug  7 17:31:16 2008 (by Create and Import Peripheral Wizard)
// Verilog Standard:  Verilog-2001
//----------------------------------------------------------------------------
// Naming Conventions:
//   active low signals:                    "*_n"
//   clock signals:                         "clk", "clk_div#", "clk_#x"
//   reset signals:                         "rst", "rst_n"
//   generics:                              "C_*"
//   user defined types:                    "*_TYPE"
//   state machine next state:              "*_ns"
//   state machine current state:           "*_cs"
//   combinatorial signals:                 "*_com"
//   pipelined or register delay signals:   "*_d#"
//   counter signals:                       "*cnt*"
//   clock enable signals:                  "*_ce"
//   internal version of output port:       "*_i"
//   device pins:                           "*_pin"
//   ports:                                 "- Names begin with Uppercase"
//   processes:                             "*_PROCESS"
//   component instantiations:              "<ENTITY_>I_<#|FUNC>"
//----------------------------------------------------------------------------

module ETHER_IPIC(
    // -- ADD USER PORTS BELOW THIS LINE ---------------
    // --USER ports added here
    // -- ADD USER PORTS ABOVE THIS LINE ---------------
    EMAC_CLK125M,   // Clock 125MHz

    EMAC_GTX_CLK,   // Tx Clock(Out) for 1000 Mode
    EMAC_TX_CLK,    // Tx Clock(In)  for 10/100 Mode
    EMAC_TXD,       // Tx Data
    EMAC_TX_EN,     // Tx Data Enable
    EMAC_TX_ER,     // Tx Error
    EMAC_COL,       // Collision signal
    EMAC_CRS,       // CRS

    EMAC_RX_CLK,    // Rx Clock(In)  for 10/100/1000 Mode
    EMAC_RXD,       // Rx Data
    EMAC_RX_DV,     // Rx Data Valid
    EMAC_RX_ER,     // Rx Error

    EMAC_INT,       // Interrupt
    EMAC_RST,       // PHY Reset

    STATUS,         // Running Status

    MAC_RST,        // MAC Controller Reset

//    MIIM_MDC,     // MIIM Clock
//    MIIM_MDIO,    // MIIM I/O

    // -- DO NOT EDIT BELOW THIS LINE ------------------
    // -- Bus protocol ports, do not add to or delete
    Bus2IP_Clk,                     // Bus to IP clock
    Bus2IP_Reset,                   // Bus to IP reset
    Bus2IP_Addr,                    // Bus to IP address bus
    Bus2IP_CS,                      // Bus to IP chip select for user logic memory selection
    Bus2IP_RNW,                     // Bus to IP read/not write
    Bus2IP_Data,                    // Bus to IP data bus
    Bus2IP_BE,                      // Bus to IP byte enables
    Bus2IP_RdCE,                    // Bus to IP read chip enable
    Bus2IP_WrCE,                    // Bus to IP write chip enable
    IP2Bus_Data,                    // IP to Bus data bus
    IP2Bus_RdAck,                   // IP to Bus read transfer acknowledgement
    IP2Bus_WrAck,                   // IP to Bus write transfer acknowledgement
    IP2Bus_Error,                   // IP to Bus error response
    IP2Bus_MstRd_Req,               // IP to Bus master read request
    IP2Bus_MstWr_Req,               // IP to Bus master write request
    IP2Bus_Mst_Addr,                // IP to Bus master address bus
    IP2Bus_Mst_BE,                  // IP to Bus master byte enables
    IP2Bus_Mst_Length,              // IP to Bus master transfer length
    IP2Bus_Mst_Type,                // IP to Bus master transfer type
    IP2Bus_Mst_Lock,                // IP to Bus master lock
    IP2Bus_Mst_Reset,               // IP to Bus master reset
    Bus2IP_Mst_CmdAck,              // Bus to IP master command acknowledgement
    Bus2IP_Mst_Cmplt,               // Bus to IP master transfer completion
    Bus2IP_Mst_Error,               // Bus to IP master error response
    Bus2IP_Mst_Rearbitrate,         // Bus to IP master re-arbitrate
    Bus2IP_Mst_Cmd_Timeout,         // Bus to IP master command timeout
    Bus2IP_MstRd_d,                 // Bus to IP master read data bus
    Bus2IP_MstRd_rem,               // Bus to IP master read remainder
    Bus2IP_MstRd_sof_n,             // Bus to IP master read start of frame
    Bus2IP_MstRd_eof_n,             // Bus to IP master read end of frame
    Bus2IP_MstRd_src_rdy_n,         // Bus to IP master read source ready
    Bus2IP_MstRd_src_dsc_n,         // Bus to IP master read source discontinue
    IP2Bus_MstRd_dst_rdy_n,         // IP to Bus master read destination ready
    IP2Bus_MstRd_dst_dsc_n,         // IP to Bus master read destination discontinue
    IP2Bus_MstWr_d,                 // IP to Bus master write data bus
    IP2Bus_MstWr_rem,               // IP to Bus master write remainder
    IP2Bus_MstWr_sof_n,             // IP to Bus master write start of frame
    IP2Bus_MstWr_eof_n,             // IP to Bus master write end of frame
    IP2Bus_MstWr_src_rdy_n,         // IP to Bus master write source ready
    IP2Bus_MstWr_src_dsc_n,         // IP to Bus master write source discontinue
    Bus2IP_MstWr_dst_rdy_n,         // Bus to IP master write destination ready
    Bus2IP_MstWr_dst_dsc_n,         // Bus to IP master write destination discontinue
    IP2Bus_IntrEvent                // IP to Bus interrupt event
    // -- DO NOT EDIT ABOVE THIS LINE ------------------
); // user_logic

    // -- ADD USER PARAMETERS BELOW THIS LINE ------------
    // --USER parameters added here
    // -- ADD USER PARAMETERS ABOVE THIS LINE ------------
    input           EMAC_CLK125M;
    output          EMAC_GTX_CLK;

    input           EMAC_TX_CLK;
    output [7:0]    EMAC_TXD;
    output          EMAC_TX_EN;
    output          EMAC_TX_ER;
    input           EMAC_COL;
    input           EMAC_CRS;

    input           EMAC_RX_CLK;
    input [7:0]     EMAC_RXD;
    input           EMAC_RX_DV;
    input           EMAC_RX_ER;

    input           EMAC_INT;
    output          EMAC_RST;

    output [1:0]    STATUS;

    input           MAC_RST;

    // -- DO NOT EDIT BELOW THIS LINE --------------------
    // -- Bus protocol parameters, do not add to or delete
    parameter C_SLV_AWIDTH                   = 32;
    parameter C_SLV_DWIDTH                   = 32;
    parameter C_MST_AWIDTH                   = 32;
    parameter C_MST_DWIDTH                   = 32;
    parameter C_NUM_REG                      = 4;
    parameter C_NUM_MEM                      = 1;
    parameter C_NUM_INTR                     = 1;
    // -- DO NOT EDIT ABOVE THIS LINE --------------------
    parameter DEFAULT_MY_MAC_ADRS  = 48'h332211000000;
    parameter DEFAULT_MY_IP_ADRS   = 32'hFE01A8C0;
    parameter DEFAULT_MY_REC0_PORT = 16'd0004;
    parameter DEFAULT_MY_REC1_PORT = 16'd0104;
    parameter DEFAULT_MY_SEND_PORT = 16'd0004;
    parameter DEFAULT_PEER_IP_ADRS = 32'hFE01A8C0;

    // -- ADD USER PORTS BELOW THIS LINE -----------------
    // --USER ports added here
    // -- ADD USER PORTS ABOVE THIS LINE -----------------

    // -- DO NOT EDIT BELOW THIS LINE --------------------
    // -- Bus protocol ports, do not add to or delete
    input                                     Bus2IP_Clk;
    input                                     Bus2IP_Reset;
    input      [0 : C_SLV_AWIDTH-1]           Bus2IP_Addr;
    input      [0 : C_NUM_MEM-1]              Bus2IP_CS;
    input                                     Bus2IP_RNW;
    input      [0 : C_SLV_DWIDTH-1]           Bus2IP_Data;
    input      [0 : C_SLV_DWIDTH/8-1]         Bus2IP_BE;
    input      [0 : C_NUM_REG-1]              Bus2IP_RdCE;
    input      [0 : C_NUM_REG-1]              Bus2IP_WrCE;
    output     [0 : C_SLV_DWIDTH-1]           IP2Bus_Data;
    output                                    IP2Bus_RdAck;
    output                                    IP2Bus_WrAck;
    output                                    IP2Bus_Error;
    output                                    IP2Bus_MstRd_Req;
    output                                    IP2Bus_MstWr_Req;
    output     [0 : C_MST_AWIDTH-1]           IP2Bus_Mst_Addr;
    output     [0 : C_MST_DWIDTH/8-1]         IP2Bus_Mst_BE;
    output     [0 : 11]                       IP2Bus_Mst_Length;
    output                                    IP2Bus_Mst_Type;
    output                                    IP2Bus_Mst_Lock;
    output                                    IP2Bus_Mst_Reset;
    input                                     Bus2IP_Mst_CmdAck;
    input                                     Bus2IP_Mst_Cmplt;
    input                                     Bus2IP_Mst_Error;
    input                                     Bus2IP_Mst_Rearbitrate;
    input                                     Bus2IP_Mst_Cmd_Timeout;
    input      [0 : C_MST_DWIDTH-1]           Bus2IP_MstRd_d;
    input      [0 : C_MST_DWIDTH/8-1]         Bus2IP_MstRd_rem;
    input                                     Bus2IP_MstRd_sof_n;
    input                                     Bus2IP_MstRd_eof_n;
    input                                     Bus2IP_MstRd_src_rdy_n;
    input                                     Bus2IP_MstRd_src_dsc_n;
    output                                    IP2Bus_MstRd_dst_rdy_n;
    output                                    IP2Bus_MstRd_dst_dsc_n;
    output     [0 : C_MST_DWIDTH-1]           IP2Bus_MstWr_d;
    output     [0 : C_MST_DWIDTH/8-1]         IP2Bus_MstWr_rem;
    output                                    IP2Bus_MstWr_sof_n;
    output                                    IP2Bus_MstWr_eof_n;
    output                                    IP2Bus_MstWr_src_rdy_n;
    output                                    IP2Bus_MstWr_src_dsc_n;
    input                                     Bus2IP_MstWr_dst_rdy_n;
    input                                     Bus2IP_MstWr_dst_dsc_n;
    output     [0 : C_NUM_INTR-1]             IP2Bus_IntrEvent;
    // -- DO NOT EDIT ABOVE THIS LINE --------------------
    reg         test_mode;

    wire [7:0]  gEMAC_TXD;
    wire        gEMAC_TX_EN;
    wire        gEMAC_TX_ER;
    wire        gEMAC_COL;
    wire        gEMAC_CRS;
    wire [7:0]  gEMAC_RXD;
    wire        gEMAC_RX_DV;
    wire        gEMAC_RX_ER;

    wire        tx_buff_we, tx_buff_start, tx_buff_end, tx_buff_ready, tx_buff_full;
    wire [31:0] tx_buff_data;
    wire [9:0]  tx_buff_space;

    wire        rx_buff_re, rx_buff_empty, rx_buff_valid;
    wire [31:0] rx_buff_data;
    wire [15:0] rx_buff_length;
    wire [15:0] rx_buff_status;

    wire        etx_buff_we, etx_buff_start, etx_buff_end, etx_buff_ready, etx_buff_full;
    wire [31:0] etx_buff_data;
    wire [9:0]  etx_buff_space;

    wire        erx_buff_re;
    wire        erx_buff_empty, erx_buff_valid;
    wire [31:0] erx_buff_data;
    wire [15:0] erx_buff_length;
    wire [15:0] erx_buff_status;

    reg [15:0]  pause_data;
    reg         pause_enable;
    reg         tx_pause_enable;

    wire        random_time_meet;
    reg [3:0]   max_retry;
    reg         giga_mode;
    reg         full_duplex;

    wire        arp_enable, arp_start, arp_valid;

    wire [15:0] l3_ext_status;

    wire        udp_send_request;
    wire [11:0] udp_send_length;
    wire        udp_send_busy;
    wire [15:0] udp_send_dstport;
    wire [15:0] udp_send_srcport;
    wire        udp_send_data_valid;
    wire        udp_send_data_read;
    wire [31:0] udp_send_data;

    wire        udp_rec_request;
    wire [15:0] udp_rec_length;
    wire        udp_rec_busy;
    wire [15:0] udp_rec_dstport0;
    wire [15:0] udp_rec_dstport1;
    wire        udp_rec_data_valid0;
    wire        udp_rec_data_valid1;
    wire        udp_rec_data_read, udp_rec0_data_read, udp_rec1_data_read;
    wire [31:0] udp_rec_data;

    wire        rec1_ram_we;
    reg [31:0]  rec1_ram [0:511];
    reg         hit_mem_delay;

    reg [31:0]  send_adrs;
    reg [23:0]  send_len;
    reg [15:0]  send_port;
    wire        master_send_start, master_send_fin, master_send_int;
    wire        master_rec0_start, master_rec0_fin, master_rec0_int;
    wire        master_rec1_start, master_rec1_fin, master_rec1_int;

    reg [31:0]  master_send_adrs;
    reg [11:0]  master_send_len;

    wire        master_cmd_idle;

    //----------------------------------------------------------------------------
    // Implementation
    //----------------------------------------------------------------------------

    wire        clk, rst_b;
    assign clk = Bus2IP_Clk;
    //assign rst_b = ~Bus2IP_Reset;
    assign rst_b = ~MAC_RST;

    // IPIC Slave Interface Control
    /*
    Bus2IP_Addr,                    // Bus to IP address bus
    Bus2IP_CS,                      // Bus to IP chip select for user logic memory selection
    Bus2IP_RNW,                     // Bus to IP read/not write
    Bus2IP_Data,                    // Bus to IP data bus
    Bus2IP_BE,                      // Bus to IP byte enables
    Bus2IP_RdCE,                    // Bus to IP read chip enable
    Bus2IP_WrCE,                    // Bus to IP write chip enable
    IP2Bus_Data,                    // IP to Bus data bus
    IP2Bus_RdAck,                   // IP to Bus read transfer acknowledgement
    IP2Bus_WrAck,                   // IP to Bus write transfer acknowledgement
    IP2Bus_Error,                   // IP to Bus error response
    */

    /*
    アドレスマップ
    0x0000_0000: 割り込みステータス
    0x0000_0004: 割り込みイネーブル
    0x0000_0010: 送信元アドレス
    0x0000_0014: 送信レングス
    0x0000_0018: 送信先ポート番号
    0x0000_0020: 受信先アドレス0
    0x0000_0024: 受信レングス0
    0x0000_0028: 受信先ポート番号0
    0x0000_0030: 受信先アドレス1
    0x0000_0034: 受信レングス1
    0x0000_0038: 受信先ポート番号1

    0x0000_0040: 自MACアドレス(Byte3〜0)
    0x0000_0044: 自MACアドレス(Byte5〜4)
    0x0000_0048: 自IPアドレス
    0x0000_004C: モード設定
                 [27:24] Max Retry
                 [2] Tx Pause Enable
                 [1] Full Duplex
                 [0] Giga Mode

    0x0000_0050: ARPリクエスト・MACアドレス(Byte3〜0)
    0x0000_0054: ARPリクエスト・MACアドレス(Byte5〜4)
    0x0000_0058: ARPリクエスト・IPアドレス
    0x0000_005C: ARPリクエスト・コントロール
                [0] ARP Send Request

    0x0000_0060: PAUSEリクエスト・コントロール
                 [31:16] Pause Quanta Data
                 [0] Pause Send Enable

    0x0000_0800〜0x0000_0FFF: Packet 1 - Receive Data
    */

    wire        hit_wr, hit_rd;
    wire        hit_int, hit_int_ena;
    wire        hit_send_adrs, hit_send_len, hit_send_port;
    wire        hit_rec0_adrs, hit_rec0_len, hit_rec0_port;
    wire        hit_rec1_adrs, hit_rec1_len, hit_rec1_port;
    wire        hit_my_mac0, hit_my_mac1, hit_my_ip, hit_mode;
    wire        hit_peer_mac0, hit_peer_mac1, hit_peer_ip, hit_arp;
    wire        hit_pause;
    wire        hit_rec1_data;
    wire        hit_status0, hit_status1, hit_status2, hit_status3, hit_status4;

    // ビット変換テーブル
    // 00000000001111111111222222222233
    // 01234567890123456789012345678901
    //
    // 33222222222211111111110000000000
    // 10987654321098765432109876543210

    assign hit_rd = (Bus2IP_CS[0] &&  Bus2IP_RNW);
    assign hit_wr = (Bus2IP_CS[0] && ~Bus2IP_RNW);

    // アドレス・デコード
    assign hit_int          = (Bus2IP_Addr[21:31] == 11'h000);
    assign hit_int_ena      = (Bus2IP_Addr[21:31] == 11'h004);

    assign hit_send_adrs    = (Bus2IP_Addr[21:31] == 11'h010);
    assign hit_send_len     = (Bus2IP_Addr[21:31] == 11'h014);
    assign hit_send_port    = (Bus2IP_Addr[21:31] == 11'h018);

    assign hit_rec0_adrs    = (Bus2IP_Addr[21:31] == 11'h020);
    assign hit_rec0_len     = (Bus2IP_Addr[21:31] == 11'h024);
    assign hit_rec0_port    = (Bus2IP_Addr[21:31] == 11'h028);

    assign hit_rec1_adrs    = (Bus2IP_Addr[21:31] == 11'h030);
    assign hit_rec1_len     = (Bus2IP_Addr[21:31] == 11'h034);
    assign hit_rec1_port    = (Bus2IP_Addr[21:31] == 11'h038);

    assign hit_my_mac0      = (Bus2IP_Addr[21:31] == 11'h040);
    assign hit_my_mac1      = (Bus2IP_Addr[21:31] == 11'h044);
    assign hit_my_ip        = (Bus2IP_Addr[21:31] == 11'h048);
    assign hit_mode         = (Bus2IP_Addr[21:31] == 11'h04C);

    assign hit_peer_mac0    = (Bus2IP_Addr[21:31] == 11'h050);
    assign hit_peer_mac1    = (Bus2IP_Addr[21:31] == 11'h054);
    assign hit_peer_ip      = (Bus2IP_Addr[21:31] == 11'h058);
    assign hit_arp          = (Bus2IP_Addr[21:31] == 11'h05C);

    assign hit_pause        = (Bus2IP_Addr[21:31] == 11'h060);

    assign hit_status0      = (Bus2IP_Addr[21:31] == 11'h070);
    assign hit_status1      = (Bus2IP_Addr[21:31] == 11'h074);
    assign hit_status2      = (Bus2IP_Addr[21:31] == 11'h078);
    assign hit_status3      = (Bus2IP_Addr[21:31] == 11'h07C);

    assign hit_status4      = (Bus2IP_Addr[21:31] == 11'h080);

    assign hit_rec1_data    = (Bus2IP_Addr[21] == 1'b1);

    //////////////////////////////////////////////////////////////////////
    // Interrupt
    //////////////////////////////////////////////////////////////////////
    // Interrupt Status
    reg [31:0]  int_status, int_enable;
    wire [31:0] int_req;
    assign int_req[31:0] ={ 8'd0,
                            8'd0,
                            8'd0,
                            5'd0, master_send_int, master_rec0_int, master_rec1_int};
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

    // Status Select
    reg         status_sel;
    always @(posedge clk or negedge rst_b) begin
        if(!rst_b) begin
            status_sel <= 1'b0;
        end else begin
            if(hit_status4 && hit_wr) begin
                if(Bus2IP_BE[3]) status_sel <= Bus2IP_Data[31];
            end
        end
    end

    //////////////////////////////////////////////////////////////////////
    // Station Configuration
    //////////////////////////////////////////////////////////////////////
    reg [47:0]  my_mac_address;
    reg [31:0]  my_ip_address;
    wire [47:0] peer_mac_address;
    reg [31:0]  peer_ip_address;
    always @(posedge clk or negedge rst_b) begin
        if(!rst_b) begin
            my_mac_address[47:0]    <= DEFAULT_MY_MAC_ADRS;
            my_ip_address[31:0]     <= DEFAULT_MY_IP_ADRS;
            peer_ip_address[31:0]   <= DEFAULT_PEER_IP_ADRS;
            max_retry[3:0]          <= 8'd8;
            tx_pause_enable         <= 1'b0;
            full_duplex             <= 1'b1;
            giga_mode               <= 1'b0;
            pause_data[15:0]        <= 16'd0;
            test_mode               <= 1'b0;
            pause_enable            <= 1'b0;
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
            if(hit_peer_ip && hit_wr) begin
                if(Bus2IP_BE[0]) peer_ip_address[31:24] <= Bus2IP_Data[ 0: 7];
                if(Bus2IP_BE[1]) peer_ip_address[23:16] <= Bus2IP_Data[ 8:15];
                if(Bus2IP_BE[2]) peer_ip_address[15: 8] <= Bus2IP_Data[16:23];
                if(Bus2IP_BE[3]) peer_ip_address[ 7: 0] <= Bus2IP_Data[24:31];
            end
/*
    0x0000_004C: モード設定
                 [27:24] Max Retry
                 [2] Tx Pause Enable
                 [1] Full Duplex
                 [0] Giga Mode
*/
            if(hit_mode && hit_wr) begin
                if(Bus2IP_BE[0]) max_retry[3:0] <= Bus2IP_Data[ 4: 7];
                if(Bus2IP_BE[3]) begin
                    test_mode       <= Bus2IP_Data[28];
                    tx_pause_enable <= Bus2IP_Data[29];
                    full_duplex     <= Bus2IP_Data[30];
                    giga_mode       <= Bus2IP_Data[31];
                end
            end
/*
    0x0000_0060: PAUSEリクエスト・コントロール
                 [31:16] Pause Quanta Data
                 [0] Pause Send Enable
*/
            if(hit_pause && hit_wr) begin
                if(Bus2IP_BE[0]) pause_data[15:8] <= Bus2IP_Data[ 0: 7];
                if(Bus2IP_BE[1]) pause_data[ 7:0] <= Bus2IP_Data[ 8:15];
                if(Bus2IP_BE[3]) pause_enable     <= Bus2IP_Data[31];
            end
        end
    end
/*
    0x0000_005C: ARPリクエスト・コントロール
                [0] ARP Send Request
    0x0000_0060: PAUSEリクエスト・コントロール
                 [31:16] Pause Quanta Data
                 [0] Pause Send Enable
*/
    assign arp_start    = (hit_arp   && hit_wr && Bus2IP_BE[3] && Bus2IP_Data[31]);

    assign IP2Bus_WrAck = hit_wr;

    //////////////////////////////////////////////////////////////////////
    // Packet Send
    //////////////////////////////////////////////////////////////////////
    // Send Config

    // Send Control
    reg [3:0]   send_state;
    parameter S_SEND_IDLE           = 4'd0;
    parameter S_SEND_START          = 4'd1;
    parameter S_SEND_START_UDP      = 4'd2;
    parameter S_SEND_START_MASTER   = 4'd3;
    parameter S_SEND_WAIT           = 4'd4;
    parameter S_SEND_FIN            = 4'd5;
    parameter S_SEND_INT            = 4'd6;

    always @(posedge clk or negedge rst_b) begin
        if(!rst_b) begin
            send_state <= S_SEND_IDLE;
            send_adrs  <= 32'd0;
            send_len   <= 24'd0;
            send_port  <= DEFAULT_MY_SEND_PORT;
        end else begin
            case(send_state)
            S_SEND_IDLE: begin
                if(hit_send_adrs && hit_wr && ~udp_send_busy) begin
                    send_state <= S_SEND_START;
                end
                // Send Address
                if(hit_send_adrs && hit_wr) begin
                    if(Bus2IP_BE[0]) send_adrs[31:24] <= Bus2IP_Data[ 0: 7];
                    if(Bus2IP_BE[1]) send_adrs[23:16] <= Bus2IP_Data[ 8:15];
                    if(Bus2IP_BE[2]) send_adrs[15: 8] <= Bus2IP_Data[16:23];
                    if(Bus2IP_BE[3]) send_adrs[ 7: 0] <= Bus2IP_Data[24:31];
                end
                // Send Length
                if(hit_send_len && hit_wr) begin
                    if(Bus2IP_BE[1]) send_len[23:16] <= Bus2IP_Data[ 8:15];
                    if(Bus2IP_BE[2]) send_len[15: 8] <= Bus2IP_Data[16:23];
                    if(Bus2IP_BE[3]) send_len[ 7: 0] <= Bus2IP_Data[24:31];
                end
                // Send Port
                if(hit_send_port && hit_wr) begin
                    if(Bus2IP_BE[2]) send_port[15: 8] <= Bus2IP_Data[16:23];
                    if(Bus2IP_BE[3]) send_port[ 7: 0] <= Bus2IP_Data[24:31];
                end
            end
            S_SEND_START: begin
                send_state <= S_SEND_START_UDP;
                master_send_adrs[31:0] <= send_adrs[31:0];
                if(send_len[23:0] > 24'd1472) begin
                    master_send_len[11:0]   <= 12'd1472;
                    send_adrs[31:0]         <= send_adrs[31:0] + 32'd1472;
                    send_len[23:0]          <= send_len[23:0] - 24'd1472;
                end else begin
                    master_send_len[11:0]   <= send_len[11:0];
                    send_len[23:0]          <= 24'd0;
                end
            end
            S_SEND_START_UDP: begin
                if(udp_send_data_read) begin
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
                if(send_len[23:0] != 24'd0) begin
                    send_state <= S_SEND_START;
                end else begin
                    send_state <= S_SEND_INT;
                end
            end
            S_SEND_INT: begin
                send_state      <= S_SEND_IDLE;
            end
            default: begin
                send_state <= S_SEND_IDLE;
            end
            endcase
        end
    end
    assign master_send_start = (send_state == S_SEND_START_MASTER)?1'b1:1'b0;
    assign master_send_int   = (send_state == S_SEND_INT)?1'b1:1'b0;

    assign udp_send_request  = (send_state == S_SEND_START_UDP);
    assign udp_send_length[11:0]   = master_send_len[11:0];
    assign udp_send_srcport  = 16'h0004;
    assign udp_send_dstport  = send_port;
    //////////////////////////////////////////////////////////////////////
    // Packet Receive 0
    //////////////////////////////////////////////////////////////////////
    // Rec0 Config
    reg [31:0]  rec0_adrs;
    reg [23:0]  rec0_len;
    reg [15:0]  rec0_port;
    reg [11:0]  rec0_len_remainder;

    reg [31:0]  master_rec0_adrs;
    reg [11:0]  master_rec0_len;

    reg [3:0]   rec0_state;
    parameter S_REC0_IDLE   = 4'd0;
    parameter S_REC0_START  = 4'd1;
    parameter S_REC0_START_MASTER  = 4'd2;
    parameter S_REC0_WAIT   = 4'd3;
    parameter S_REC0_FIN    = 4'd4;
    parameter S_REC0_INT    = 4'd5;
    parameter S_REC0_DUMMY_READ = 4'd6;

    always @(posedge clk or negedge rst_b) begin
        if(!rst_b) begin
            rec0_state <= S_REC0_IDLE;
            rec0_adrs <= 32'd0;
            rec0_len  <= 24'd0;
            rec0_port <= DEFAULT_MY_REC0_PORT ;
            rec0_len_remainder <= 12'd0;
        end else begin
            case(rec0_state)
            S_REC0_IDLE: begin
                if(udp_rec_data_valid0) begin
                    rec0_state <= S_REC0_START;
                end
                // Receive 0 Address
                if(hit_rec0_adrs && hit_wr) begin
                    if(Bus2IP_BE[0]) rec0_adrs[31:24] <= Bus2IP_Data[ 0: 7];
                    if(Bus2IP_BE[1]) rec0_adrs[23:16] <= Bus2IP_Data[ 8:15];
                    if(Bus2IP_BE[2]) rec0_adrs[15: 8] <= Bus2IP_Data[16:23];
                    if(Bus2IP_BE[3]) rec0_adrs[ 7: 0] <= Bus2IP_Data[24:31];
                end
                // Receive 0 Length
                if(hit_rec0_len && hit_wr) begin
                    if(Bus2IP_BE[1]) rec0_len[23:16] <= Bus2IP_Data[ 8:15];
                    if(Bus2IP_BE[2]) rec0_len[15: 8] <= Bus2IP_Data[16:23];
                    if(Bus2IP_BE[3]) rec0_len[ 7: 0] <= Bus2IP_Data[24:31];
                end
                // Receive 0 Port
                if(hit_rec0_port && hit_wr) begin
                    if(Bus2IP_BE[2]) rec0_port[15: 8] <= Bus2IP_Data[16:23];
                    if(Bus2IP_BE[3]) rec0_port[ 7: 0] <= Bus2IP_Data[24:31];
                end
            end
            S_REC0_START: begin
                master_rec0_adrs[31:0] <= rec0_adrs[31:0];
                rec0_adrs[31:0]        <= rec0_adrs[31:0] + {20'd0, udp_rec_length[11:0]};
                if(rec0_len[23:0] >= {12'd0, udp_rec_length[11:0]}) begin
                    rec0_state <= S_REC0_START_MASTER;
                    master_rec0_len[11:0]    <= udp_rec_length[11:0];
                    rec0_len[23:0]           <= rec0_len[23:0] - {12'd0, udp_rec_length[11:0]};
                    rec0_len_remainder[11:0] <= 12'd0;
                end else if(rec0_len[23:0] > 24'd0) begin
                    rec0_state <= S_REC0_START_MASTER;
                    master_rec0_len[11:0]    <= rec0_len[11:0];
                    rec0_len[23:0]           <= 24'd0;
                    rec0_len_remainder[11:0] <= udp_rec_length[11:0] - rec0_len[11:0];
                end else begin
                    rec0_state <= S_REC0_DUMMY_READ;
                    master_rec0_len[11:0]    <= 12'd0;
                    rec0_len[23:0]           <= 24'd0;
                    rec0_len_remainder[11:0] <= udp_rec_length[11:0];
                end
            end
            S_REC0_START_MASTER: begin
                if(master_cmd_idle) rec0_state <= S_REC0_WAIT;
            end
            S_REC0_WAIT: begin
                if(master_rec0_fin) begin
                    rec0_state <= S_REC0_FIN;
                end
            end
            S_REC0_FIN: begin
                if(rec0_len_remainder[11:0] > 12'd0) begin
                    rec0_state <= S_REC0_DUMMY_READ;
                end else begin
                    rec0_state <= S_REC0_IDLE;
                end
            end
            S_REC0_DUMMY_READ: begin
                rec0_len_remainder[11:0] <= rec0_len_remainder[11:0] - 12'd4;
                if(rec0_len_remainder[11:0] <= 12'd4) begin
                    rec0_state <= S_REC0_IDLE;
                end
            end
            default: begin
                rec0_state <= S_REC0_IDLE;
            end
            endcase
        end
    end
    assign master_rec0_start = (rec0_state == S_REC0_START_MASTER)?1'b1:1'b0;
    assign master_rec0_int   = (rec0_state == S_REC0_FIN)?1'b1:1'b0;

    assign udp_rec_dstport0[15:0] = rec0_port[15:0];

    //////////////////////////////////////////////////////////////////////
    // Packet Receive 1
    //////////////////////////////////////////////////////////////////////
    // Rec1 Config
    reg [9:0]   rec1_adrs;
    reg [23:0]  rec1_len;
    reg [15:0]  rec1_port;
    reg [11:0]  rec1_len_reg;

    reg [3:0]   rec1_state;
    parameter S_REC1_IDLE   = 4'd0;
    parameter S_REC1_DATA   = 4'd1;
    parameter S_REC1_FIN    = 4'd3;
    parameter S_REC1_INT    = 4'd4;

    always @(posedge clk or negedge rst_b) begin
        if(!rst_b) begin
            rec1_state <= S_REC1_IDLE;
            rec1_adrs <= 10'd0;
            rec1_len  <= 24'd0;
            rec1_port <= DEFAULT_MY_REC1_PORT;
            rec1_len_reg[11:0] <= 12'd0;
        end else begin
            case(rec1_state)
            S_REC1_IDLE: begin
                // Receive 1 Address, Length
                if(udp_rec_data_valid1) begin
                    rec1_state <= S_REC1_DATA;
                    rec1_adrs[9:0] <= 10'd0;
                    rec1_len[23:0] <= (udp_rec_length[11:2] + (udp_rec_length[1] | udp_rec_length[0]));
                    rec1_len_reg[11:0] <= udp_rec_length[11:0];
                end
                // Receive 1 Port
                if(hit_rec1_len && hit_wr) begin
                    if(Bus2IP_BE[2]) rec1_port[15: 8] <= Bus2IP_Data[16:23];
                    if(Bus2IP_BE[3]) rec1_port[ 7: 0] <= Bus2IP_Data[24:31];
                end
            end
            S_REC1_DATA: begin
                if(rec1_len[23:0] == 16'd1) begin
                    rec1_state <= S_REC1_FIN;
                end else begin
                    rec1_len[23:0] <= rec1_len[23:0] - 24'd1;
                end
            end
            S_REC1_FIN: begin
                rec1_state <= S_REC1_IDLE;
            end
            default: begin
                rec1_state <= S_REC1_IDLE;
            end
            endcase
        end
    end
//    assign master_rec1_start = (rec1_state == S_REC1_START)?1'b1:1'b0;

    assign rec1_ram_we = (rec1_state == S_REC1_DATA)?1'b1:1'b0;

    reg [31:0]  rec1_ram_rddata;
    wire [9:0]  rec1_rdadrs;

    // RAM
    always @(posedge clk) begin
        if(rec1_ram_we) begin
            rec1_ram[rec1_adrs[9:0]] = udp_rec_data[31:0];
        end
    end

    always @(posedge clk) begin
        rec1_ram_rddata[31:0] <= rec1_ram[rec1_rdadrs[9:0]];
    end

    assign master_rec1_int = (rec1_state == S_REC1_FIN)?1'b1:1'b0;

    assign udp_rec1_data_read = (rec1_state == S_REC1_DATA)?1'b1:1'b0;
    assign udp_rec_dstport1[15:0] = rec1_port[15:0];


    //////////////////////////////////////////////////////////////////////
    // Master Command
    //////////////////////////////////////////////////////////////////////
    reg         IP2Bus_MstRd_Req;
    reg         IP2Bus_MstWr_Req;
    reg         IP2Bus_Mst_Type;
    reg [0:31]  IP2Bus_Mst_Addr;
    reg [0:3]   IP2Bus_Mst_BE;
    reg [0:11]  IP2Bus_Mst_Length;
    reg         IP2Bus_Mst_Lock;
    reg         IP2Bus_Mst_Reset;

    reg [3:0]   master_cmd_state;
    parameter S_MSTCMD_IDLE         = 4'd0;
    parameter S_MSTCMD_SEND_REQUEST = 4'd1;
    parameter S_MSTCMD_SEND_FIN     = 4'd2;
    parameter S_MSTCMD_REC0_REQUEST = 4'd3;
    parameter S_MSTCMD_REC0_FIN     = 4'd4;
    parameter S_MSTCMD_REC1_REQUEST = 4'd5;
    parameter S_MSTCMD_REC1_FIN     = 4'd6;

    always @(posedge clk or negedge rst_b) begin
        if(!rst_b) begin
            master_cmd_state <= S_MSTCMD_IDLE;
            IP2Bus_MstRd_Req         <= 1'b0;            // Read Request
            IP2Bus_MstWr_Req         <= 1'b0;            // Write Request
            IP2Bus_Mst_Type         <= 1'b0;            // Burst Request
            IP2Bus_Mst_Addr[0:31]   <= 32'h0000_0000;   // Address
            IP2Bus_Mst_BE[0:3]      <= 4'h0;            // Byte Enable
            IP2Bus_Mst_Length[0:11] <= 12'd0;           // Burst Length
            IP2Bus_Mst_Lock         <= 1'b0;            // Lock Signal
            IP2Bus_Mst_Reset        <= 1'b0;            // Reset Signal
        end else begin
            case(master_cmd_state)
            S_MSTCMD_IDLE: begin
                if(master_send_start) begin
                    master_cmd_state <= S_MSTCMD_SEND_REQUEST;
                    IP2Bus_MstRd_Req         <= 1'b1;            // Read Request
                    IP2Bus_MstWr_Req         <= 1'b0;            // Write Request
                    IP2Bus_Mst_Type         <= 1'b1;            // Burst Request
                    IP2Bus_Mst_Addr[0:31]   <= master_send_adrs[31:0];   // Address
                    IP2Bus_Mst_BE[0:3]      <= 4'hF;            // Byte Enable
                    IP2Bus_Mst_Length[0:11] <= master_send_len[11:0];   // Burst Length
                    IP2Bus_Mst_Lock         <= 1'b0;            // Lock Signal
                    IP2Bus_Mst_Reset        <= 1'b0;            // Reset Signal
                end else if(master_rec0_start) begin
                    master_cmd_state <= S_MSTCMD_REC0_REQUEST;
                    IP2Bus_MstRd_Req         <= 1'b0;            // Read Request
                    IP2Bus_MstWr_Req         <= 1'b1;            // Write Request
                    IP2Bus_Mst_Type         <= 1'b1;            // Burst Request
                    IP2Bus_Mst_Addr[0:31]   <= master_rec0_adrs[31:0];   // Address
                    IP2Bus_Mst_BE[0:3]      <= 4'hF;            // Byte Enable
                    IP2Bus_Mst_Length[0:11] <= master_rec0_len[11:0];           // Burst Length
                    IP2Bus_Mst_Lock         <= 1'b0;            // Lock Signal
                    IP2Bus_Mst_Reset        <= 1'b0;            // Reset Signal
                end else if(master_rec1_start) begin
                    master_cmd_state <= S_MSTCMD_REC1_REQUEST;
                end
            end
            S_MSTCMD_SEND_REQUEST: begin
                if(Bus2IP_Mst_CmdAck) begin
                    master_cmd_state <= S_MSTCMD_SEND_FIN;
                    IP2Bus_MstRd_Req         <= 1'b0;            // Read Request
                    IP2Bus_MstWr_Req         <= 1'b0;            // Write Request
                    IP2Bus_Mst_Type         <= 1'b0;            // Burst Request
                    IP2Bus_Mst_Addr[0:31]   <= 32'h0000_0000;   // Address
                    IP2Bus_Mst_BE[0:3]      <= 4'h0;            // Byte Enable
                    IP2Bus_Mst_Length[0:11] <= 12'd0;           // Burst Length
                    IP2Bus_Mst_Lock         <= 1'b0;            // Lock Signal
                    IP2Bus_Mst_Reset        <= 1'b0;            // Reset Signal
                end
            end
            S_MSTCMD_SEND_FIN: begin
                // wait last a cmplt.
                if(Bus2IP_Mst_Cmplt) begin
                    master_cmd_state <= S_MSTCMD_IDLE;
                end
            end
            S_MSTCMD_REC0_REQUEST: begin
                // rec0 send a master
                if(Bus2IP_Mst_CmdAck) begin
                    master_cmd_state <= S_MSTCMD_REC0_FIN;
                    IP2Bus_MstRd_Req         <= 1'b0;            // Read Request
                    IP2Bus_MstWr_Req         <= 1'b0;            // Write Request
                    IP2Bus_Mst_Type         <= 1'b0;            // Burst Request
                    IP2Bus_Mst_Addr[0:31]   <= 32'h0000_0000;   // Address
                    IP2Bus_Mst_BE[0:3]      <= 4'h0;            // Byte Enable
                    IP2Bus_Mst_Length[0:11] <= 12'd0;           // Burst Length
                    IP2Bus_Mst_Lock         <= 1'b0;            // Lock Signal
                    IP2Bus_Mst_Reset        <= 1'b0;            // Reset Signal
                end
            end
            S_MSTCMD_REC0_FIN: begin
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

    //assign IP2Bus_MstRd_Req = (master_cmd_state == S_MSTCMD_SEND_REQUEST)?1'b1:1'b0;

    //////////////////////////////////////////////////////////////////////
    // Master Data
    //////////////////////////////////////////////////////////////////////
    reg         IP2Bus_MstRd_dst_rdy_n;
    reg         IP2Bus_MstRd_dst_dsc_n;
    reg         IP2Bus_MstWr_src_rdy_n;
    reg         IP2Bus_MstWr_sof_n;
    reg         IP2Bus_MstWr_eof_n;
    reg [11:0]  master_data_len;

    reg [3:0]   master_data_state;
    parameter S_MSTDATA_IDLE        = 4'd0;
    parameter S_MSTDATA_SEND_REQ    = 4'd1;
    parameter S_MSTDATA_SEND_DATA   = 4'd2;
    parameter S_MSTDATA_SEND_FIN    = 4'd3;
    parameter S_MSTDATA_REC0_REQ    = 4'd4;
    parameter S_MSTDATA_REC0_START  = 4'd5;
    parameter S_MSTDATA_REC0_DATA   = 4'd6;
    parameter S_MSTDATA_REC0_FIN    = 4'd7;
    parameter S_MSTDATA_WAIT_CMPLT  = 4'd8;

    always @(posedge clk or negedge rst_b) begin
        if(!rst_b) begin
            master_data_state <= S_MSTDATA_IDLE;
            IP2Bus_MstRd_dst_rdy_n <= 1'b1;
            IP2Bus_MstRd_dst_dsc_n <= 1'b1;
            IP2Bus_MstWr_sof_n     <= 1'b1;
            IP2Bus_MstWr_eof_n     <= 1'b1;
            IP2Bus_MstWr_src_rdy_n <= 1'b1;
        end else begin
            case(master_data_state)
            S_MSTDATA_IDLE: begin
                if(master_send_start) begin
                    master_data_state <= S_MSTDATA_SEND_REQ;
                end else if(master_rec0_start) begin
                    master_data_state <= S_MSTDATA_REC0_REQ;
                    master_data_len[11:0] <= master_rec0_len[11:0];
//                end else if(master_rec1_start) begin
//                    master_data_state <= S_MSTDATA_REQ0_REQ;
                end
            end
            // Send Process
            S_MSTDATA_SEND_REQ: begin
                master_data_state <= S_MSTDATA_SEND_DATA;
                IP2Bus_MstRd_dst_rdy_n <= 1'b0;
            end
            S_MSTDATA_SEND_DATA: begin
                if(!Bus2IP_MstRd_eof_n) begin
                    master_data_state <= S_MSTDATA_SEND_FIN;
                    IP2Bus_MstRd_dst_rdy_n <= 1'b1;
                end
            end
            S_MSTDATA_SEND_FIN: begin
                master_data_state <= S_MSTDATA_WAIT_CMPLT;
            end
            // Receive 0 Process
            S_MSTDATA_REC0_REQ: begin
                master_data_state <= S_MSTDATA_REC0_START;
                IP2Bus_MstWr_src_rdy_n <= 1'b0;
                IP2Bus_MstWr_sof_n     <= 1'b0;
            end
            S_MSTDATA_REC0_START: begin
                if(!Bus2IP_MstWr_dst_rdy_n) begin
                    master_data_state <= S_MSTDATA_REC0_DATA;
                    IP2Bus_MstWr_sof_n     <= 1'b1;
                    master_data_len[11:0] <= master_data_len[11:0] - 12'd4;
                end
            end
            S_MSTDATA_REC0_DATA: begin
                if(!Bus2IP_MstWr_dst_rdy_n) begin
                    if(master_data_len[11:0] <= 12'd8) begin
                        master_data_state <= S_MSTDATA_REC0_FIN;
                        IP2Bus_MstWr_eof_n     <= 1'b0;
                    end
                    master_data_len[11:0] <= master_data_len[11:0] - 12'd4;
                end
            end
            S_MSTDATA_REC0_FIN: begin
                if(!Bus2IP_MstWr_dst_rdy_n) begin
                    master_data_state <= S_MSTDATA_WAIT_CMPLT;
                    IP2Bus_MstWr_src_rdy_n <= 1'b1;
                    IP2Bus_MstWr_eof_n     <= 1'b1;
                end
            end
            S_MSTDATA_WAIT_CMPLT: begin
                // wait last a cmplt.
                if(Bus2IP_Mst_Cmplt) begin
                    master_data_state <= S_MSTDATA_IDLE;
                end
            end
            default: begin
                master_data_state <= S_MSTDATA_IDLE;
            end
            endcase
        end
    end

    assign master_send_fin = (master_data_state == S_MSTDATA_SEND_FIN)?1'b1:1'b0;
    assign master_rec0_fin = (master_data_state == S_MSTDATA_REC0_FIN)?1'b1:1'b0;

    assign master_cmd_idle = ((master_cmd_state == S_MSTCMD_IDLE) && (master_data_state == S_MSTDATA_IDLE))?1'b1:1'b0;

    assign udp_send_data_valid  = ~Bus2IP_MstRd_src_rdy_n;
    assign udp_send_data[31:0]  = Bus2IP_MstRd_d[0:31];
    //assign udp_send_length[11:0]    = master_send_len[11:0];

    assign udp_rec0_data_read   = ((((master_data_state == S_MSTDATA_REC0_START) || (master_data_state == S_MSTDATA_REC0_DATA) || (master_data_state == S_MSTDATA_REC0_FIN)) && ~Bus2IP_MstWr_dst_rdy_n) || (rec0_state == S_REC0_DUMMY_READ))?1'b1:1'b0;
    assign IP2Bus_MstWr_d[0:31] = udp_rec_data[31:0];

    // --USER nets declarations added here, as needed for user logic

    // --USER logic implementation added here
    assign IP2Bus_MstWr_src_dsc_n = 1'b1;
    assign IP2Bus_Error = 1'b0;
    assign IP2Bus_MstWr_rem = 4'd0;

    //////////////////////////////////////////////////////////////////////
    // Slave Read
    //////////////////////////////////////////////////////////////////////
    always @(posedge clk or negedge rst_b) begin
        if(!rst_b) begin
            hit_mem_delay <= 1'b0;
        end else begin
            hit_mem_delay <= (hit_rd & hit_rec1_data);
        end
    end
    assign rec1_rdadrs[9:0] = Bus2IP_Addr[22:31];
    assign IP2Bus_RdAck = ((hit_rd && ~hit_rec1_data) || (hit_rd && hit_mem_delay))?1'b1:1'b0;

    wire [31:0] pause_status, mode_status, arp_status;
    assign pause_status[31:0] = {pause_data[15:0],
                                15'd0,
                                pause_enable
                                };
    assign arp_status[31:0]  = {30'd0, arp_enable, arp_valid
                               };
    assign mode_status[31:0] = {4'd0, max_retry[3:0],
                                16'd0,
                                5'd0, tx_pause_enable, full_duplex, giga_mode
                               };

    assign IP2Bus_Data[0:31] =  ((hit_rd && hit_int)?      int_status[31:0]                :32'd0) |
                                ((hit_rd && hit_int_ena)?  int_enable[31:0]                :32'd0) |
                                ((hit_rd && hit_send_adrs)?send_adrs[31:0]                 :32'd0) |
                                ((hit_rd && hit_send_len)? {8'd0, send_len[23:0]}          :32'd0) |
                                ((hit_rd && hit_send_port)?{16'd0, send_port[15:0]}        :32'd0) |
                                ((hit_rd && hit_rec0_adrs)?rec0_adrs[31:0]                 :32'd0) |
                                ((hit_rd && hit_rec0_len)? {8'd0, rec0_len[23:0]}          :32'd0) |
                                ((hit_rd && hit_rec0_port)?{16'd0, rec0_port[15:0]}        :32'd0) |
                                ((hit_rd && hit_rec1_adrs)?{22'd0, rec1_adrs[9:0]}         :32'd0) |
                                ((hit_rd && hit_rec1_len)? {20'd0, rec1_len_reg[11:0]}     :32'd0) |
                                ((hit_rd && hit_rec1_port)?{16'd0, rec1_port[15:0]}        :32'd0) |
                                ((hit_rd && hit_my_mac0)?  my_mac_address[31:0]            :32'd0) |
                                ((hit_rd && hit_my_mac1)?  {16'd0, my_mac_address[47:32]}  :32'd0) |
                                ((hit_rd && hit_my_ip)?    my_ip_address[31:0]             :32'd0) |
                                ((hit_rd && hit_mode)?     mode_status[31:0]               :32'd0) |
                                ((hit_rd && hit_peer_mac0)?peer_mac_address[31:0]          :32'd0) |
                                ((hit_rd && hit_peer_mac1)?{16'd0, peer_mac_address[47:32]}:32'd0) |
                                ((hit_rd && hit_peer_ip)?  peer_ip_address[31:0]           :32'd0) |
                                ((hit_rd && hit_arp)?      arp_status[31:0]                :32'd0) |
                                ((hit_rd && hit_pause)?    pause_status[31:0]              :32'd0) |
                                ((hit_rd && hit_mem_delay)?rec1_ram_rddata[31:0]           :32'd0) |
                                ((hit_rd && hit_status0)?  {28'd0, rec0_state[3:0]}        :32'd0) |
                                ((hit_rd && hit_status1)?  {28'd0, master_cmd_state[3:0]}  :32'd0) |
                                ((hit_rd && hit_status2)?  {28'd0, master_data_state[3:0]} :32'd0) |
                                ((hit_rd && hit_status3)?  {16'd0, 6'd0, rx_buff_valid, rx_buff_empty, 6'd0, tx_buff_full, tx_buff_ready}        :32'd0) |
                                ((hit_rd && hit_status4)?  {31'd0, status_sel}             :32'd0)
                                ;

    // ------------------------------------------------------------
    // Example code to drive IP to Bus signals
    // ------------------------------------------------------------

//    assign IP2Bus_Data    = 0;
//    assign IP2Bus_WrAck   = Bus2IP_WrCE[0];
//    assign IP2Bus_RdAck   = Bus2IP_RdCE[0];
//    assign IP2Bus_Error   = 0;

    // ------------------------------------------------------------
    // Module
    // ------------------------------------------------------------
    // Ethernet MAC
    wire        tx_clk, rx_clk;
    assign tx_clk = (giga_mode)?EMAC_CLK125M:EMAC_TX_CLK;
    assign rx_clk = EMAC_RX_CLK;
    assign EMAC_RST     = rst_b;

    // ------------------------------------------------------------
    // Status
    // ------------------------------------------------------------
    assign STATUS[1:0] = (status_sel)?{gEMAC_RX_DV, (rec0_len[23:0] > 24'd0)}:{gEMAC_TX_EN, (send_state != S_SEND_INT)};

`ifdef RGMII
    ETHER_GMII2RGMII u_ETHER_GMII2RGMII(
        .rst_b      ( rst_b         ),

        .tx_clk     ( tx_clk        ),
        .gmii_txd   ( gEMAC_TXD     ),
        .gmii_txe   ( gEMAC_TX_EN   ),
        .gmii_txer  ( gEMAC_TX_ER   ),
        .gmii_rxd   ( gEMAC_RXD     ),
        .gmii_rxe   ( gEMAC_RX_DV   ),
        .gmii_rxer  ( gEMAC_RX_ER   ),

        .rx_clk     ( rx_clk        ),
        .rgmii_txd  ( EMAC_TXD[3:0] ),
        .rgmii_txe  ( EMAC_TX_ER    ),
        .rgmii_rxd  ( EMAC_RXD[3:0] ),
        .rgmii_rxe  ( EMAC_RX_ER    ),
        .rgmii_tck  ( EMAC_GTX_CLK  )
    );
    assign gEMAC_COL <= 1'b0;
    assign gEMAC_CRS <= 1'b0;
`else
    ETHER_GMII_BUFF u_ETHER_GMII_BUFF(
        .rst_b          ( rst_b         ),

        .tx_clk         ( tx_clk        ),
        .bgmii_txd      ( gEMAC_TXD     ),
        .bgmii_txe      ( gEMAC_TX_EN   ),
        .bgmii_txer     ( gEMAC_TX_ER   ),
        .bgmii_rxd      ( gEMAC_RXD     ),
        .bgmii_rxe      ( gEMAC_RX_DV   ),
        .bgmii_rxer     ( gEMAC_RX_ER   ),
        .bgmii_cos      ( gEMAC_COL     ),
        .bgmii_crs      ( gEMAC_CRS     ),

        .rx_clk         ( rx_clk        ),
        .gmii_txd       ( EMAC_TXD      ),
        .gmii_txe       ( EMAC_TX_EN    ),
        .gmii_txer      ( EMAC_TX_ER    ),
        .gmii_rxd       ( EMAC_RXD      ),
        .gmii_rxe       ( EMAC_RX_DV    ),
        .gmii_rxer      ( EMAC_RX_ER    ),
        .gmii_col       ( EMAC_COS      ),
        .gmii_crs       ( EMAC_CRS      ),
        .gmii_gtk_clk   ( EMAC_GTX_CLK  )
    );
`endif

//    wire [7:0]  rx_rxd;
//    wire        rx_clk, rx_dv, rx_er, col, crs;
//    wire [7:0]  tx_txd;
//    wire        tx_en, tx_er;

//    assign rx_clk = (test_mode)?tx_clk:~EMAC_RX_CLK;
//    assign rx_rxd = (test_mode)?tx_txd:EMAC_RXD;
//    assign rx_dv  = (test_mode)?tx_en:EMAC_RX_DV;
//    assign rx_er  = (test_mode)?tx_er:EMAC_RX_ER;
//    assign col    = (test_mode)?1'b0:EMAC_COL;
//    assign crs    = (test_mode)?tx_en:EMAC_CRS;

//    assign EMAC_TXD   = (test_mode)?7'd0:tx_txd;
//    assign EMAC_TX_EN = (test_mode)?1'b0:tx_en;
//    assign EMAC_TX_ER = (test_mode)?1'b0:tx_er;

    ETHER_MAC u_ETHER_MAC(
        .RST                ( rst_b             ),

        // GMII,MII Interface
        //.TX_CLK             ( tx_clk            ),
        //.TXD                ( tx_txd            ),
        //.TX_EN              ( tx_en             ),
        //.TX_ER              ( tx_er             ),
        //.RX_CLK             ( rx_clk            ),
        //.RXD                ( rx_rxd            ),
        //.RX_DV              ( rx_dv             ),
        //.RX_ER              ( rx_er             ),
        //.COL                ( col               ),
        //.CRS                ( crs               ),

        .TX_CLK             ( tx_clk            ),
        .TXD                ( gEMAC_TXD          ),
        .TX_EN              ( gEMAC_TX_EN        ),
        .TX_ER              ( gEMAC_TX_ER        ),
        .RX_CLK             ( rx_clk             ),
        .RXD                ( gEMAC_RXD          ),
        .RX_DV              ( gEMAC_RX_DV        ),
        .RX_ER              ( gEMAC_RX_ER        ),
        .COL                ( gEMAC_COL          ),
        .CRS                ( gEMAC_CRS          ),

        // RGMII Interface
        //.TX_CLK             ( tx_clk            ),
        //.TXD                ( gEMAC_TXD          ),
        //.TX_EN              ( gEMAC_TX_EN        ),
        //.TX_ER              ( gEMAC_TX_ER        ),
        //.RX_CLK             ( rx_clk             ),
        //.RXD                ( gEMAC_RXD          ),
        //.RX_DV              ( gEMAC_RX_DV        ),
        //.RX_ER              ( gEMAC_RX_ER        ),
        //.COL                ( 1'b0              ),
        //.CRS                ( 1'b0              ),

        // System Clock
        .CLK                ( clk               ),

        // RX Buffer Interface
        .RX_BUFF_RE         ( rx_buff_re        ),
        .RX_BUFF_DATA       ( rx_buff_data      ),
        .RX_BUFF_EMPTY      ( rx_buff_empty     ),
        .RX_BUFF_VALID      ( rx_buff_valid     ),
        .RX_BUFF_LENGTH     ( rx_buff_length    ),
        .RX_BUFF_STATUS     ( rx_buff_status    ),

        // TX Buffer Interface
        .TX_BUFF_WE         ( tx_buff_we        ),
        .TX_BUFF_START      ( tx_buff_start     ),
        .TX_BUFF_END        ( tx_buff_end       ),
        .TX_BUFF_READY      ( tx_buff_ready     ),
        .TX_BUFF_DATA       ( tx_buff_data      ),
        .TX_BUFF_FULL       ( tx_buff_full      ),
        .TX_BUFF_SPACE      ( tx_buff_space     ),

        // From CPU
        .PAUSE_QUANTA_DATA  ( pause_data[15:0]  ),
        .PAUSE_SEND_ENABLE  ( pause_enable      ),
        .TX_PAUSE_ENABLE    ( tx_pause_enable   ),

        // Setting
        .RANDOM_TIME_MEET   ( random_time_meet      ),
        .MAC_ADDRESS        ( my_mac_address[47:0]  ),
        .IP_ADDRESS         ( my_ip_address[31:0]   ),
        .MAX_RETRY          ( max_retry             ),
        .GIG_MODE           ( giga_mode             ),
        .FULL_DUPLEX        ( full_duplex           )
    );
    assign random_time_meet = 1'b1;

    // Layer 3 Extension
    ETHER_L3_CTL u_ETHER_L3_CTL(
        .RST                ( rst_b             ),
        .CLK                ( clk               ),

        // RX Buffer Interface
        .RX_BUFF_RE         ( rx_buff_re        ),
        .RX_BUFF_DATA       ( rx_buff_data      ),
        .RX_BUFF_EMPTY      ( rx_buff_empty     ),
        .RX_BUFF_VALID      ( rx_buff_valid     ),
        .RX_BUFF_LENGTH     ( rx_buff_length    ),
        .RX_BUFF_STATUS     ( rx_buff_status    ),

        // TX Buffer Interface
        .TX_BUFF_WE         ( tx_buff_we        ),
        .TX_BUFF_START      ( tx_buff_start     ),
        .TX_BUFF_END        ( tx_buff_end       ),
        .TX_BUFF_READY      ( tx_buff_ready     ),
        .TX_BUFF_DATA       ( tx_buff_data      ),
        .TX_BUFF_FULL       ( tx_buff_full      ),
        .TX_BUFF_SPACE      ( tx_buff_space     ),

        // External RX Buffer Interface
        .ERX_BUFF_RE        ( erx_buff_re       ),
        .ERX_BUFF_DATA      ( erx_buff_data     ),
        .ERX_BUFF_EMPTY     ( erx_buff_empty    ),
        .ERX_BUFF_VALID     ( erx_buff_valid    ),
        .ERX_BUFF_LENGTH    ( erx_buff_length   ),
        .ERX_BUFF_STATUS    ( erx_buff_status   ),

        // External TX Buffer Interface
        .ETX_BUFF_WE        ( etx_buff_we       ),
        .ETX_BUFF_START     ( etx_buff_start    ),
        .ETX_BUFF_END       ( etx_buff_end      ),
        .ETX_BUFF_READY     ( etx_buff_ready    ),
        .ETX_BUFF_DATA      ( etx_buff_data     ),
        .ETX_BUFF_FULL      ( etx_buff_full     ),
        .ETX_BUFF_SPACE     ( etx_buff_space    ),

        .MAC_ADDRESS        ( my_mac_address[47:0]      ),
        .IP_ADDRESS         ( my_ip_address[31:0]       ),

        .ARPC_ENABLE        ( arp_enable       ),
        .ARPC_REQUEST       ( arp_start        ),
        .ARPC_VALID         ( arp_valid        ),
        .ARPC_IP_ADDRESS    ( peer_ip_address[31:0]     ),
        .ARPC_MAC_ADDRESS   ( peer_mac_address[47:0]    ),

        .STATUS             ( l3_ext_status     )
    );

    assign udp_rec_data_read = (udp_rec0_data_read || udp_rec1_data_read)?1'b1:1'b0;
    // UDP Controller
    ETHER_UDP_CTL u_ETHER_UDP_CTL(
        .RST                    ( rst_b                 ),
        .CLK                    ( clk                   ),

        .UDP_PEER_MAC_ADDRESS   ( peer_mac_address      ),
        .UDP_PEER_IP_ADDRESS    ( peer_ip_address       ),
        .UDP_MY_MAC_ADDRESS     ( my_mac_address        ),
        .UDP_MY_IP_ADDRESS      ( my_ip_address         ),

        // Send UDP
        .UDP_SEND_REQUEST       ( udp_send_request      ),
        .UDP_SEND_LENGTH        ( {4'd0, udp_send_length}       ),
        .UDP_SEND_BUSY          ( udp_send_busy         ),
        .UDP_SEND_DSTPORT       ( udp_send_dstport      ),
        .UDP_SEND_SRCPORT       ( udp_send_srcport      ),
        .UDP_SEND_DATA_VALID    ( udp_send_data_valid   ),
        .UDP_SEND_DATA_READ     ( udp_send_data_read    ),
        .UDP_SEND_DATA          ( udp_send_data         ),

        // Receive UDP
        .UDP_REC_REQUEST        ( udp_rec_request       ),
        .UDP_REC_LENGTH         ( udp_rec_length        ),
        .UDP_REC_BUSY           ( udp_rec_busy          ),
        .UDP_REC_DSTPORT0       ( udp_rec_dstport0      ),
        .UDP_REC_DSTPORT1       ( udp_rec_dstport1      ),
        .UDP_REC_DATA_VALID0    ( udp_rec_data_valid0   ),
        .UDP_REC_DATA_VALID1    ( udp_rec_data_valid1   ),
        .UDP_REC_DATA_READ      ( udp_rec_data_read     ),
        .UDP_REC_DATA           ( udp_rec_data          ),

        // for ETHER-MAC BUFFER
        .TX_WE                  ( etx_buff_we       ),
        .TX_START               ( etx_buff_start    ),
        .TX_END                 ( etx_buff_end      ),
        .TX_READY               ( etx_buff_ready    ),
        .TX_DATA                ( etx_buff_data     ),
        .TX_FULL                ( etx_buff_full     ),
        .TX_SPACE               ( etx_buff_space    ),

        .RX_RE                  ( erx_buff_re       ),
        .RX_DATA                ( erx_buff_data     ),
        .RX_EMPTY               ( erx_buff_empty    ),
        .RX_VALID               ( erx_buff_valid    ),
        .RX_LENGTH              ( erx_buff_length   ),
        .RX_STATUS              ( erx_buff_status   )
    );

endmodule
