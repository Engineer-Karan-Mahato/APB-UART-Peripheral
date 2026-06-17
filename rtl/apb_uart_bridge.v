`timescale 1ns/1ps

module apb_uart_bridge #(  parameter CLOCK_FREQ = 25000000, 
			   parameter BAUD_RATE = 115200,
			   parameter DATA_WIDTH = 8
			)
			(
			   input clk,
			   input rst,

			   input PSEL,
			   input PENABLE,
			   input PWRITE,
			   input [31:0] PADDR,
			   input [31:0] PWDATA,

			   output reg [31:0] PRDATA,
			   output PREADY,

			   input rx,
			   output tx
			);


	/////////////////
	// Registers
	/////////////////
	reg [DATA_WIDTH-1 : 0] tx_data_reg; 
	reg [DATA_WIDTH-1 : 0] rx_data_reg; 
	wire [3 : 0] status_reg; 


	///////////////////
	// UART Signals
	///////////////////
	reg tx_start;

	wire tx_busy;
	wire tx_done;
	wire rx_ready;
	wire frame_error;
	wire [DATA_WIDTH-1 : 0] rx_data;


	////////////////////////////////////
	// APB Transfer Detection Signals
	////////////////////////////////////
	wire apb_write;
	wire apb_read;

	assign apb_write = PSEL && PENABLE && PWRITE;
	assign apb_read  = PSEL && PENABLE && ~PWRITE;

	assign PREADY = 1'b1;


	//////////////////////
	// UART Instance
	//////////////////////
	uart #(
		.CLOCK_FREQ(CLOCK_FREQ),
		.BAUD_RATE(BAUD_RATE),
		.DATA_WIDTH(DATA_WIDTH)
	      )
	   uart_inst(
			.clk(clk), 
			.rst(rst), 

			.tx_start(tx_start), 
			.tx_data(tx_data_reg), 

			.rx(rx), 

			.tx(tx), 
			.tx_busy(tx_busy),
			.tx_done(tx_done),

			.rx_ready(rx_ready),
			.frame_error(frame_error),
			.rx_data(rx_data)
		);


	///////////////////////
	// Write Logic
	///////////////////////
	always @(posedge clk or negedge rst) begin
		// Reset Logic 
		if (!rst) begin
			tx_data_reg <= {(DATA_WIDTH){1'b0}};
			tx_start <= 1'b0;
		end

		// Write Logic
		else begin
			tx_start <= 1'b0;
			if (apb_write) begin
				case(PADDR[7:0])
					8'h00: begin
						tx_data_reg <= PWDATA[DATA_WIDTH-1 : 0];
						tx_start <= 1'b1;
					end
					default: ;
				endcase
			end
		end
	end


	///////////////////////////
	// RX Data Register Logic
	///////////////////////////
	always @(posedge clk or negedge rst) begin
		// Reset Logic 
		if (!rst) begin
			rx_data_reg <= {(DATA_WIDTH){1'b0}};
		end

		// RX Data Register Logic
		else if (rx_ready) begin
			rx_data_reg <= rx_data;
		end
	end


	///////////////////////////
	// Status Register Logic
	///////////////////////////
		assign status_reg[0] = tx_busy;
		assign status_reg[1] = tx_done;
		assign status_reg[2] = rx_ready;
		assign status_reg[3] = frame_error;


	/////////////////////////////
	// Read Logic
	/////////////////////////////
	always @(*) begin
		if (apb_read) begin
				case(PADDR[7:0])
					// RX Data Register Read
					8'h04: PRDATA = { {(32 - DATA_WIDTH){1'b0}} , rx_data_reg };

					// Status Register Read
					8'h08: PRDATA = { 28'b0, status_reg };

					// Default Condition
					default: PRDATA = 32'h00;
				endcase
		end
		else 
			PRDATA = 32'h00;
	end
endmodule