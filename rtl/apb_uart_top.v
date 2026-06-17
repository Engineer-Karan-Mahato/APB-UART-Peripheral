`timescale 1ns/1ps

module apb_uart_top #(     parameter CLOCK_FREQ = 25000000, 
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

			   output [31:0] PRDATA,
			   output PREADY,

			   input rx,
			   output tx
			);
	// APB-UART Bridge Instance
	apb_uart_bridge #(
    			.CLOCK_FREQ(CLOCK_FREQ),
    			.BAUD_RATE(BAUD_RATE),
    			.DATA_WIDTH(DATA_WIDTH)
		)
	apb_uart_bridge_inst (
    			.clk(clk),
    			.rst(rst),

    			.PADDR(PADDR),
    			.PWDATA(PWDATA),
    			.PWRITE(PWRITE),
    			.PSEL(PSEL),
    			.PENABLE(PENABLE),

    			.PRDATA(PRDATA),
    			.PREADY(PREADY),

			.rx(rx),
			.tx(tx)
		);
endmodule