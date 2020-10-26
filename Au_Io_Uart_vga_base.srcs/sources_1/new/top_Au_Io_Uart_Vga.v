`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: MoySys, LLC
// Engineer: Michael Moy
// 
// Create Date: 10/25/2020 08:20:43 PM
// Design Name: 
// Module Name: top_Au_Io_Uart_Vga
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// `define USE_BCD
// `define SYNCRONOUS_TX_TEST		// SYNC A -> a    A-SYNC a -> A

module top_Au_Io_Uart_Vga(
	input clk,
	input rst_n,
	input moyrx,		   // USB->Serial input
	output moytx,		   // USB->Serial output
	output [7:0] led,	   // 8 user controllable LEDs
	output wire [7:0] io_seg,
	output wire [3:0] io_sel
	);

wire rst;
assign rst = ~rst_n;

// internal segment data. The Display Controller drives this
wire [7:0] io_seg_int;

// digit values to display    
wire [3:0] val3; 
wire [3:0] val2;   
wire [3:0] val1;   
wire [3:0] val0;    

// digit enable flags
wire ena_3 = ( val3 != 0 ? 1 : ~counter[28] ); // Turn this display On and Off  
wire ena_2 = 1;
wire ena_1 = 1;  
wire ena_0 = 1;  

// free running counter
reg [64:0] counter;

// load the 7seg digit values from the free running counter
assign val3 = counter[39:36];
assign val2 = counter[35:32];
assign val1 = counter[31:28];
assign val0 = counter[27:24];

// load the Au LED's from the free running counter
assign led[7:0] = counter[27:20];

// wire up the segments as needed. Set DP off:1 for now
assign io_seg[0] = ~io_seg_int[6];
assign io_seg[1] = ~io_seg_int[5];
assign io_seg[2] = ~io_seg_int[4];
assign io_seg[3] = ~io_seg_int[3];
assign io_seg[4] = ~io_seg_int[2];
assign io_seg[5] = ~io_seg_int[1];
assign io_seg[6] = ~io_seg_int[0];
assign io_seg[7] = ~io_seg_int[7];

// wire up the Io Board 4 Digit 7seg Display Controller
IoBd_7segX4 IoBoard7segDisplay(
	.clk(clk),
	.reset(rst),
	
	.seg3_hex(val3),
	.seg3_dp(rx_avail),			// turn this digit's DP On, solid
	.seg3_ena(ena_3),
	
	.seg2_hex(val2),
	.seg2_dp(rx_err),			// turn this DP Off
	.seg2_ena(ena_2),
	
	.seg1_hex(val1),
	.seg1_dp(tx_send),	// blink this digit's DP fast
	.seg1_ena(ena_1),
	
	.seg0_hex(val0),
	.seg0_dp(tx_err),	// blink this digit's DP faster
	.seg0_ena(ena_0),
	
	.bright(val1),
	.seg_data(io_seg_int),
	.seg_select(io_sel)
	);  
	
// UART Signals
wire [7:0] rx_data;
wire rx_avail;
wire rx_err;
wire [15:0] rx_counter;

wire tx_empty;
wire tx_err;
`ifdef SYNCRONOUS_TX_TEST
	reg [7:0] tx_data;
	reg tx_send;
`else // `ifdef SYNCRONOUS_TX_TEST
	wire [7:0] tx_data;
	wire tx_send;
	// echo back lower case A - Z as a test
	assign tx_send = rx_avail;
	assign tx_data = (rx_data ^ ( rx_data >= 8'h41 && rx_data < (8'h41+26) ? 8'h20 : 0 ));
`endif // `ifdef SYNCRONOUS_TX_TEST
		
// RX UART wiring
IoBd_Uart_RX Uart_RX(
	.clk(clk),
	.rst(rst),
	.rx_in(moyrx),
	.data_out(rx_data),
	.data_avail(rx_avail),
	.end_counter(rx_counter),
	.data_error(rx_err)
	);

// TX UART wiring
IoBd_Uart_TX Uart_TX(
	.clk(clk),
	.rst(rst),
	.tx_out(moytx),
	.tx_data(tx_data),
	.tx_rdy(tx_empty),
	.tx_req(tx_send)
	);
	
    
// keep a free running counter to use for Display Data			
always @(posedge clk) begin
	if(rst_n == 0) begin
		counter <= 0;
		
`ifdef SYNCRONOUS_TX_TEST
		tx_send <= 0;
		tx_data <= 8'h42;
`endif // `ifdef SYNCRONOUS_TX_TEST

		end
	else begin
	
`ifdef SYNCRONOUS_TX_TEST
		tx_send <= rx_avail;
		if( rx_avail ) begin
			// echo back upper case A - Z as a test
			tx_data <= rx_data ^ ( rx_data >= 8'h61 && rx_data <= (8'h61+26) ? 8'h20 : 0 );
			end
`endif // `ifdef SYNCRONOUS_TX_TEST	

`ifndef USE_BCD	
		// do HEX counting
		counter[63:2] <= counter[63:2] + 1;  // fast enough
		
`else // `ifndef USE_BCD
		// do BCD counting
		counter[23:2] <= counter[23:2] + 1;  // fast enough
		if( counter[23:2] == 0 ) begin
			if( counter[27:24] != 9 )
				counter[27:24] <= counter[27:24] + 1;
			else begin
				counter[27:24] <= 0;
				if( counter[31:28] != 9 )
					counter[31:28] <= counter[31:28] + 1;
				else begin
					counter[31:28] <= 0;
					if( counter[35:32] != 9 )
						counter[35:32] <= counter[35:32] + 1;
					else begin
						counter[35:32] <= 0;
						if( counter[39:36] != 9 )
							counter[39:36] <= counter[39:36] + 1;
						else begin
							counter[39:36] <= 0;
							end
						end
					end
				end
			end
`endif // `ifndef USE_BCD

		end
	end
	 	
	
endmodule

