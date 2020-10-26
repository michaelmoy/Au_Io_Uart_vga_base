`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/26/2020 10:30:01 AM
// Design Name: 
// Module Name: top_Au_Io_Uart_Vga_tb
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


module top_Au_Io_Uart_Vga_tb(
    );
    
 // from the system
reg clk;
reg  rst;   

// reset signal 
wire rst_n;
 
// wires for the Alchitry FPGA + Io board 7-SEG display setup
wire [7:0] io_seg;
wire [3:0] io_sel;
wire [3:0] val3; 
wire [3:0] val2;   
wire [3:0] val1;   
wire [3:0] val0;
wire [7:0] io_seg_int;
wire [3:0] io_sel_int;

// wire up the reset lines
assign rst_n = ~rst;

// wire up the segments as needed. Set DP off:1 for now
assign io_seg[0] = ~io_seg_int[6];
assign io_seg[1] = ~io_seg_int[5];
assign io_seg[2] = ~io_seg_int[4];
assign io_seg[3] = ~io_seg_int[3];
assign io_seg[4] = ~io_seg_int[2];
assign io_seg[5] = ~io_seg_int[1];
assign io_seg[6] = ~io_seg_int[0];
assign io_seg[7] = ~io_seg_int[7];
assign io_sel    =  io_sel_int;
 
IoBd_7segX4 IoBoard(
	.clk(clk),
	.reset(~rst_n),
	.seg3_hex(val3),
	.seg3_dp(1'b0),
	.seg3_ena(1'b1),
	.seg2_hex(val2),
	.seg2_dp(1'b0),
	.seg2_ena(1'b1),
	.seg1_hex(val1),
	.seg1_dp(1'b0),
	.seg1_ena(1'b1),
	.seg0_hex(val0),
	.seg0_dp(1'd0),
	.seg0_ena(1'b1),
	.bright(4'b0000),
	.seg_data(io_seg_int),
	.seg_select(io_sel_int)
	);   

// these are the controls that the TB uses to provide UART input.       
reg [511:0] rx_sim_data;
reg [7:0]   rx_sim_len;
reg         rx_sim_req;

wire [7:0] rx_data;
wire rx_avail;
wire rx_err;
wire [15:0] rx_counter;

reg [7:0] tx_data;
reg tx_send;
wire tx_empty;
wire tx_err;

// simulated UART for the TB so we can pump Test data in real fast and simple
IoBd_Uart_RX Uart_RX(
    .clk(clk),
    .rst(rst),
//    .data_sim_512(rx_sim_data),
//    .data_sim_len(rx_sim_len),
//    .data_sim_req(rx_sim_req),
    .data_out(rx_data),
    .data_avail(rx_avail),
    .data_error(rx_err)
    );

// assign tb_usb_rx = tb_usb_tx;
wire tb_usb_tx ;
//
IoBd_Uart_TX Uart_TX(
    .clk(clk),
    .rst(rst),
    .tx_out(tb_usb_tx),
    .tx_data(tx_data ),
    .tx_rdy(tx_empty),
    .tx_req(tx_send)
    );


// free running counter
reg [64:0] counter;
 
     
// keep a free running counter to use for Display Data			
always @(posedge clk) begin
	if(rst_n == 0) begin
		counter <= 0;
		tx_send <= 0;
		tx_data <= 8'h62;
		end
	else begin

tx_send <= (rx_avail | (counter[32:0] == 33'h0_0001_0000 ? 1 : 0) ) ;
if( rx_avail )
	tx_data <= rx_data ^ ( rx_data >= 8'h61 && rx_data <= (8'h61+26) ? 8'h20 : 0 );
	
	
		// do HEX counting
		counter[63:2] <= counter[63:2] + 1;  // fast enough
		end
	end



  
    
    initial begin

      $display(" ");
      $display("-----------------------------------------------------");
      $display("--                                                 --");
      $display("-- Testbench for Michael Moy                       --");
      $display("--                                                 --");
      $display("-----------------------------------------------------");
      $display("\n");
	  
//		rx_sim_data = 0;
//		rx_sim_len = 0;
//		rx_sim_req = 0;
//		tx_send = 0;
		tx_data = 8'h44;
        rst = 1;
        
        clk = 0;
        #50;
        clk = 1;
        #50;
        clk = 0;
        #50;
        clk = 1;
        #50;
        clk = 0;
        #50;
        clk = 1;
        rst = 0;
        #50;
        clk = 0;
//        rst = 0;
        #50;
        clk = 1;
        #50;
        clk = 0;
        #50;        

        repeat (60000) begin
/*        	if( counter[32:0] == 33'h0_0001_0000 )
        		tx_send = 1;
        	else
        		tx_send = 0; */
            clk =  ! clk;
            #50;
        	end  
 
        repeat (60000) begin
            clk =  ! clk;
            #50;
        	end         	
        	
 
 		$display( "Reset!" ) ;
        rst = 1;
        repeat (6) begin
            clk =  ! clk;
            #50;
        	end  
        rst = 0;
        repeat (6) begin
            clk =  ! clk;
            #50;
        	end  
        	       	
 
        repeat (60000) begin
            clk =  ! clk;
            #50;
        	end         	
        	
        	
        	
 
 //		$display( "Send!" ) ;
 /*		
		tx_send = 1;
        clk = 1;
        #50;
        clk = 0;
        #50;   
		tx_send = 0;
*/
        repeat (60000) begin
            clk =  ! clk;
            #50;
        	end
 
 // $display("First Sent now.  tx_empty: %d", tx_empty ) ;
      
 /*       
		tx_send = 1;
        clk = 1;
        #50;
        clk = 0;
        #50;   
		tx_send = 0;
*/
        repeat (60000) begin
            clk =  ! clk;
            #50;
        	end
 
 	
 
		$display("Done\n");	
        
        
        repeat (10000) begin
            clk =  ! clk;
            #50;
			end
        #200;
        clk =  ! clk;
		
		$display(" ");
		$display("-----------------------------------------------------");
		$display("--                                                 --");
		$display("-- Testbench Done                                  --");
		$display("--                                                 --");
		$display("-----------------------------------------------------");  
	  
        end
  
   
    
endmodule
