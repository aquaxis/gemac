module ETHER_UDP_LOOP(
	RST,
	CLK,

	UDP_PEER_MAC_ADDRESS,
	UDP_PEER_IP_ADDRESS,
	UDP_MY_MAC_ADDRESS,
	UDP_MY_IP_ADDRESS,

	UDP_PEER_ENABLE,

	// for ETHER-MAC BUFFER
	TX_WE,
	TX_START,
	TX_END,
	TX_READY,
	TX_DATA,
	TX_FULL,
	TX_SPACE,

	RX_RE,
	RX_DATA,
	RX_EMPTY,
	RX_VALID,
	RX_LENGTH,
	RX_STATUS,

	STATUS
);

	input		   RST;
	input		   CLK;

	input [47:0]	UDP_PEER_MAC_ADDRESS;
	input [31:0]	UDP_PEER_IP_ADDRESS;
	input [47:0]	UDP_MY_MAC_ADDRESS;
	input [31:0]	UDP_MY_IP_ADDRESS;

	input			UDP_PEER_ENABLE;

	output		  TX_WE;
	output		  TX_START;
	output		  TX_END;
	input		   TX_READY;
	output [31:0]   TX_DATA;
	input		   TX_FULL;
	input [9:0]	 TX_SPACE;

	output		  RX_RE;
	input [31:0]	RX_DATA;
	input		   RX_EMPTY;
	input		   RX_VALID;
	input [15:0]	RX_LENGTH;
	input [15:0]	RX_STATUS;

	output [15:0]	STATUS;

	reg [4:0]	   TxState;

	parameter S_IDLE	= 5'd0;
	parameter S_WAIT	= 5'd1;
	parameter S_SEND0   = 5'd2;
	parameter S_SEND1   = 5'd3;
	parameter S_SEND2   = 5'd4;
	parameter S_SEND3   = 5'd5;
	parameter S_SEND4   = 5'd6;
	parameter S_SEND5   = 5'd7;
	parameter S_SEND6   = 5'd8;
	parameter S_SEND7   = 5'd9;
	parameter S_SEND8   = 5'd10;
	parameter S_SEND9   = 5'd11;
	parameter S_SEND10  = 5'd12;
	parameter S_SEND11  = 5'd13;
	parameter S_SEND12  = 5'd14;
	parameter S_END	 = 5'd15;
	parameter S_CHECK = 5'd16;

	reg [15:0]	  SendLength;
	reg			 SendWe, SendStart, SendEnd;
	reg [31:0]	  SendData;
	reg [31:0]	  UdpSendDelay;
	reg			 UdpSendRead;

	// Tx State
	always @(posedge CLK or negedge RST) begin
		if(!RST) begin
			TxState		   <= S_IDLE;
			SendWe		  <= 1'b0;
			SendStart	   <= 1'b0;
			SendEnd		 <= 1'b0;
			SendData		<= 32'd0;
			SendLength	  <= 16'd0;
			UdpSendDelay	<= 32'd0;
			UdpSendRead	<= 1'b0;
		end else begin
			case(TxState)
				S_IDLE: begin
//					if(UDP_SEND_REQUEST) TxState <= S_WAIT;
					if(RX_VALID) begin
						TxState <= S_CHECK;
//					end else if(!RX_EMPTY) begin
//						TxState <= S_END;
					end
//					SendLength	  <= 16'd14 + 16'd20 + 16'd8 + UDP_SEND_LENGTH;
					SendWe		  <= 1'b0;
					SendStart	   <= 1'b0;
					SendEnd		 <= 1'b0;
					SendData		<= 32'd0;
					UdpSendRead	 <= 1'b0;
				end
				S_CHECK: begin
					if(RX_STATUS == 16'hB1C0) begin
						if(UDP_PEER_ENABLE) begin
							TxState <= S_WAIT;
						end else begin
							TxState <= S_END;
						end
					end else begin
						TxState <= S_END;
					end
					SendLength	  <= RX_LENGTH - 16'd4;
				end
				S_WAIT: begin
					if(TX_READY && ({4'd0, TX_SPACE, 2'd0} > SendLength)) TxState <= S_SEND0;
				end
				S_SEND0: begin  // Send Frame Length
					TxState	 <= S_SEND1;
					SendWe	  <= 1'b1;
					SendStart   <= 1'b1;
					SendData	<= {SendLength, 16'h0000};
					SendLength  <= SendLength -16'd14;
				end
				S_SEND1: begin  // Send Destination MAC Address
					TxState	   <= S_SEND2;
					SendWe	  <= 1'b1;
					SendStart   <= 1'b0;
					SendData	<= UDP_PEER_MAC_ADDRESS[31:0];
				end
				S_SEND2: begin  // Send Source MAC Address, Destination MAC Address
					TxState	   <= S_SEND3;
					SendWe	  <= 1'b1;
					SendData	<= {UDP_MY_MAC_ADDRESS[15:0], UDP_PEER_MAC_ADDRESS[47:32]};
				end
				S_SEND3: begin  // Send Source MAC Address
					TxState	   <= S_SEND4;
					SendWe	  <= 1'b1;
					SendData	<= UDP_MY_MAC_ADDRESS[47:16];
				end
				S_SEND4: begin  // Send IP Header(Service Type, Header Length, Version), Ethernet Type
					TxState	   <= S_SEND5;
					SendWe	  <= 1'b1;
					SendData	<= {16'h0045, 16'h0008};
				end
				S_SEND5: begin  // Send Identification, Total Length
					TxState	   <= S_SEND6;
					SendWe	  <= 1'b1;
					SendData	<= {16'h0000, SendLength[7:0], SendLength[15:8]};
					SendLength  <= SendLength -16'd20;
				end
				S_SEND6: begin  // Send Protocol, Time to Live, Flagmentation
					TxState	   <= S_SEND7;
					SendWe	  <= 1'b1;
					SendData	<= {8'h11, 8'hFF, 16'h0000};
				end
				S_SEND7: begin  // Send Source IP Address, CheckSum
					TxState	   <= S_SEND8;
					SendWe	  <= 1'b1;
					SendData	<= {UDP_MY_IP_ADDRESS[15:0], 16'h0000};
				end
				S_SEND8: begin  // Send Destination IP Address, Source IP Address
					TxState	   <= S_SEND9;
					SendWe	  <= 1'b1;
					SendData	<= {UDP_PEER_IP_ADDRESS[15:0], UDP_MY_IP_ADDRESS[31:16]};
				end
				S_SEND9: begin  // Send UDP Header(Source Port), Send Destination IP Address
					TxState	   <= S_SEND10;
					SendWe	  <= 1'b1;
//					SendData	<= {UDP_SEND_SRCPORT, UDP_PEER_IP_ADDRESS[31:16]};
					SendData	<= {RX_DATA[31:16], UDP_PEER_IP_ADDRESS[31:16]};
				end
				S_SEND10: begin  // Send Length, Destination Port
					TxState	   <= S_SEND11;
					SendWe	  <= 1'b1;
//					SendData	<= {SendLength[7:0], SendLength[15:8], UDP_SEND_DSTPORT};
					SendData	<= {SendLength[7:0], SendLength[15:8], RX_DATA[15:0]};
					SendLength  <= SendLength -16'd8;
					UdpSendRead	 <= 1'b1;
				end
				S_SEND11: begin  // Send Data, CheckSum
//					if(UDP_SEND_DATA_VALID) begin
						TxState	   <= S_SEND12;
						SendWe	  <= 1'b1;
//						SendData	<= {UDP_SEND_DATA[15:0], 16'h0000};
						SendData	<= {RX_DATA[31:16], 16'h0000};
						SendLength  <= SendLength -16'd2;
//						SendLength  <= SendLength -16'd4;
//					end else begin
//						SendWe	  <= 1'b0;
//					end
				end
				S_SEND12: begin
//					if(UDP_SEND_DATA_VALID) begin
						if(SendLength <= 16'd4) begin
							TxState <= S_END;
							SendEnd <= 1'b1;
							case(SendLength)
							16'd4: SendData	<= {RX_DATA[31:0]};
							16'd3: SendData	<= {8'd0, RX_DATA[23:0]};
							16'd2: SendData	<= {16'd0, RX_DATA[15:0]};
							16'd1: SendData	<= {24'd0, RX_DATA[7:0]};
							endcase
						end else begin
							SendLength <= SendLength -16'd4;
							SendData	<= {RX_DATA[31:0]};
						end
						SendWe	  <= 1'b1;
//					end else if(SendLength <= 16'd2) begin
//						TxState <= S_END;
//						SendEnd <= 1'b1;
//						SendWe	  <= 1'b1;
//						case(SendLength)
//							16'd2: SendData	<= {16'd0, RX_DATA[15:0]};
//							16'd1: SendData	<= {24'd0, RX_DATA[7:0]};
//						endcase
//					end else begin
//						SendWe	  <= 1'b0;
//					end
				end
				S_END: begin
					if(RX_LENGTH <= 4) begin
						TxState <= S_IDLE;
					end
					SendWe		  <= 1'b0;
					SendEnd		 <= 1'b0;
					SendData		<= 32'd00000000;
					UdpSendRead	 <= 1'b1;
				end
			endcase
//			if(UDP_SEND_DATA_VALID) begin
//				UdpSendDelay <= UDP_SEND_DATA;
//			end
		end
	end

	assign TX_WE	= SendWe;
	assign TX_START = SendStart;
	assign TX_END   = SendEnd;
	assign TX_DATA  = SendData;

	reg [4:0]	last_state;
	always @(posedge CLK or negedge RST) begin
		if(!RST) begin
			last_state <= 5'd0;
		end else begin
			if(!((TxState == S_IDLE) || (TxState == S_END))) begin
				last_state <= TxState;
			end
		end
	end

	assign RX_RE = (
					(TxState == S_SEND1) ||
					(TxState == S_SEND2) || (TxState == S_SEND3) ||
					(TxState == S_SEND4) || (TxState == S_SEND5) ||
					(TxState == S_SEND6) || (TxState == S_SEND7) ||
					(TxState == S_SEND8) || (TxState == S_SEND9) ||
					(TxState == S_SEND10) || (TxState == S_SEND11) ||
					(TxState == S_SEND12) || (TxState == S_END)
					)?1'b1:1'b0;

	assign STATUS[15:4] = 12'd0;
	assign STATUS[3:0] = last_state[3:0];
endmodule
