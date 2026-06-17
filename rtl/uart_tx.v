`timescale 1ns/1ps

module uart_tx #(	parameter CLOCK_FREQ = 25000000, 
			parameter BAUD_RATE = 115200,
			parameter DATA_WIDTH = 8
		)
		(	input clk, 
			input rst, 
			input tx_start, 
			input [DATA_WIDTH-1 : 0] tx_data, 
			output reg tx, 
			output reg tx_busy,
			output reg tx_done
		);

	localparam CLK_PER_BIT = CLOCK_FREQ / BAUD_RATE;
	localparam COUNT_WIDTH = $clog2(CLK_PER_BIT+1);
	localparam BIT_WIDTH = (DATA_WIDTH <= 1) ? 1 : $clog2(DATA_WIDTH);

	reg [COUNT_WIDTH-1 : 0] clk_count;
	reg [BIT_WIDTH-1 : 0]  bit_count;
	reg [DATA_WIDTH-1 : 0]  data_reg;
	reg [1:0]  state;

	// Different States
	localparam IDLE  = 2'b00, 
		   START = 2'b01,
		   DATA  = 2'b10,
		   STOP  = 2'b11;

	always @( posedge clk or negedge rst) begin
		// Reset Logic
		if (!rst) begin
			tx <= 1'b1;
			tx_busy <= 1'b0;
			tx_done <= 1'b0;
			clk_count <= 0;
			bit_count <= 0;
			state <= IDLE;
			data_reg <= 0;
		end

		else begin
			tx_done <= 1'b0;
		// State Transition and Data Transfer Logic
		case(state)
			IDLE:   begin
				tx <= 1'b1;
				tx_busy <= 1'b0;
				clk_count <= 0;
				bit_count <= 0;

				if (tx_start) begin
					state <= START; 
					data_reg <= tx_data;
					tx_busy <= 1'b1; 
				end
				end


			START:  begin
				tx <= 1'b0;
				tx_busy <= 1'b1;

				if (clk_count < CLK_PER_BIT-1)
					clk_count <= clk_count + 1'b1;

				else begin
					clk_count <= 0;
					state <= DATA;
				end
				end


			DATA:   begin
				tx <= data_reg[bit_count];
				tx_busy <= 1'b1;

				if (clk_count < CLK_PER_BIT-1)
					clk_count <= clk_count + 1'b1;

				else begin
					clk_count <= 0;

					if(bit_count < DATA_WIDTH-1)
						bit_count <= bit_count + 1;

					else begin
						bit_count <= 0;
						state <= STOP;
					end
				end
				end


			STOP:   begin
				tx <= 1'b1;
				tx_busy <= 1'b1;

				if (clk_count < CLK_PER_BIT-1)
					clk_count <= clk_count + 1'b1;

				else begin
					clk_count <= 0;
					tx_done <= 1'b1;
					state <= IDLE;
				end
				end
			
			// Default Condition
			default: begin
				state <= IDLE;
				tx <= 1'b1;
				tx_busy <= 1'b0;
				tx_done <= 1'b0;
				clk_count <= 0;
				bit_count <= 0;
				end
		endcase
		end
	end
endmodule
