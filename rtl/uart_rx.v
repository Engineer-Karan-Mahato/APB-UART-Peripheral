`timescale 1ns/1ps

module uart_rx #(	parameter CLOCK_FREQ = 25000000 , 
			parameter BAUD_RATE = 115200, 
			parameter DATA_WIDTH = 8
		)
		(	input clk, 
			input rst, 
			input rx, 
			output reg rx_ready, 
			output reg frame_error,
			output reg [DATA_WIDTH-1 : 0] rx_data 
		);

	localparam CLK_PER_BIT = CLOCK_FREQ/BAUD_RATE;
	localparam COUNT_WIDTH = $clog2(CLK_PER_BIT+1);
	localparam BIT_WIDTH = (DATA_WIDTH <= 1) ? 1 : $clog2(DATA_WIDTH);

	// Different States
	localparam IDLE  = 2'b00, 
		   START = 2'b01,
		   RECV  = 2'b10,
		   STOP  = 2'b11;

	reg [COUNT_WIDTH-1 : 0] clk_count;
	reg [BIT_WIDTH-1 : 0] bit_count;
	reg [DATA_WIDTH-1 : 0] data_reg;
	reg [1:0] state;

	reg rx_meta;
	reg rx_sync;

	always @(posedge clk or negedge rst) begin
		// Reset Logic
		if (!rst) begin
			rx_meta <= 1'b1;
			rx_sync <= 1'b1;

			clk_count <= 0;
			bit_count <= 0;
			data_reg <= 0;
			rx_data <= 0;
			rx_ready <= 1'b0;
			frame_error <= 1'b0;
			state <= IDLE;
		end

		else begin
			rx_ready <= 1'b0;
			frame_error <= 1'b0;

			rx_meta <= rx;
			rx_sync <= rx_meta;

			// Transition Batween States and Data Recieved
			case(state)
			IDLE: 	begin
				clk_count <= 0;
				bit_count <= 0;

				if(!rx_sync) begin
					state <= START;
				end
				end


			START:  begin
				if (clk_count == (CLK_PER_BIT >> 1)) begin
					clk_count <= 0;

					if (!rx_sync)
						state <= RECV;
					
					else
						state <= IDLE;
				end

				else begin
					clk_count <= clk_count + 1;
				end
				end


			RECV:   begin
				if (clk_count < CLK_PER_BIT - 1) begin
					clk_count <= clk_count + 1;
				end

				else begin
					clk_count <= 0;
					data_reg[bit_count] <= rx_sync;

					if (bit_count < DATA_WIDTH - 1) begin
						bit_count <= bit_count + 1;
					end

					else begin
						bit_count <= 0;
						state <= STOP;
					end
				end
				end

			STOP:   begin

				if (clk_count < CLK_PER_BIT - 1) begin
					clk_count <= clk_count + 1;
				end

				else begin
					clk_count <= 0;

					if (rx_sync) begin
						rx_data <= data_reg;
						rx_ready <= 1'b1;
					end

					else
						frame_error <= 1'b1;

					state <= IDLE;
				end
				end

			// Default Condition
			default: begin
				state <= IDLE;
				clk_count <= 0;
				bit_count <= 0;
				rx_ready <= 0;
				frame_error <= 0;
			end
			endcase
		end
	end
endmodule
