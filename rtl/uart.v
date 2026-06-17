`timescale 1ns/1ps

module uart #(	parameter CLOCK_FREQ = 25000000, 
		parameter BAUD_RATE = 115200,
		parameter DATA_WIDTH = 8
	)
	(	input clk, 
		input rst, 

		input tx_start, 
		input [DATA_WIDTH-1 : 0] tx_data, 

		input rx, 

		output reg tx, 
		output reg tx_busy,
		output reg tx_done,

		output reg rx_ready, 
		output reg frame_error,
		output reg [DATA_WIDTH-1 : 0] rx_data 
	);


		// UART Transmitter Instance
		uart_tx #(
				.CLOCK_FREQ(CLOCK_FREQ),
				.BAUD_RATE(BAUD_RATE),
				.DATA_WIDTH(DATA_WIDTH)
			)
		  tx_inst(
				.clk(clk), 
				.rst(rst), 

				.tx_start(tx_start), 
				.tx_data(tx_data), 

				.tx(tx), 
				.tx_busy(tx_busy),
				.tx_done(tx_done)
			); 


		// UART Receiver Instance
		uart_rx #(
				.CLOCK_FREQ(CLOCK_FREQ),
				.BAUD_RATE(BAUD_RATE),
				.DATA_WIDTH(DATA_WIDTH)
			)
		  rx_inst(
				.clk(clk), 
				.rst(rst), 

				.rx(rx), 

				.rx_ready(rx_ready),
				.frame_error(frame_error),
				.rx_data(rx_data)
			);
endmodule