`timescale 1ns/1ps

module apb_uart_tb;

	// Different Parameters 
	parameter CLOCK_FREQ = 25000000; 
	parameter BAUD_RATE = 115200;
	parameter DATA_WIDTH = 8;


	// APB Signals
	reg clk;
	reg rst;

	reg PSEL;
	reg PENABLE;
	reg PWRITE;
	reg [31:0] PADDR;
	reg [31:0] PWDATA;

	wire [31:0] PRDATA;
	wire PREADY;

	wire rx;
	wire tx;

	// Loopback connection
	assign rx = tx;

	// Test Variables
	integer i;
	reg [DATA_WIDTH-1 : 0] random_data;
	integer total_count;
	integer pass_count;
	integer fail_count;


	/////////////////////////////
	// APB-UART Top Instance
	/////////////////////////////
	apb_uart_top #(
    		.CLOCK_FREQ(CLOCK_FREQ),
    		.BAUD_RATE(BAUD_RATE),
    		.DATA_WIDTH(DATA_WIDTH)
		)
	dut (
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

	
	//////////////////////////
	// Clock Generation
	//////////////////////////
	always #(1000000000/(2*CLOCK_FREQ)) clk = ~clk;


	////////////////////////////////
	// APB Write task
	////////////////////////////////
	task apb_write (input [31:0] addr, input [DATA_WIDTH-1 : 0] data);
		begin
			@(posedge clk);
			PADDR   = addr;
			PWDATA  = {{(32-DATA_WIDTH){1'b0}}, data};
			PSEL    = 1'b1;
			PWRITE  = 1'b1;
			PENABLE = 1'b0;

			@(posedge clk);
			PENABLE = 1'b1;

			@(posedge clk);
			PSEL    = 1'b0;
			PWRITE  = 1'b0;
			PENABLE = 1'b0;

			$display("[%0t]APB WRITE ADDRESS = %h DATA = %h", $time, addr, data);
		end
	endtask


	////////////////////////////////
	// APB Read task
	////////////////////////////////
	task apb_read (input [31:0] addr);
		begin
			@(posedge clk);
			PADDR   = addr;
			PSEL    = 1'b1;
			PWRITE  = 1'b0;
			PENABLE = 1'b0;

			@(posedge clk);
			PENABLE = 1'b1;

			@(posedge clk);
			$display("[%0t]APB READ ADDRESS = %h DATA = %h", $time, addr, PRDATA);

			PSEL    = 1'b0;
			PENABLE = 1'b0;
		end
	endtask


	////////////////////////////////
	// RX Ready Wait task
	////////////////////////////////
	task wait_rx_ready;
		integer timeout;
		begin
			timeout = 0;
			apb_read(32'h08);       // Read Status Register

			// wait for complete UART transmission + reception
			while(!PRDATA[2] && (timeout < 5000)) begin
				apb_read(32'h08);
				timeout = timeout + 1;
			end

			if (timeout == 5000)
				$display("[%0t] ERROR: RX_READY TIMEOUT", $time);
		end
	endtask


	/////////////////////////////////
	// Run Test Task
	/////////////////////////////////
	task run_test (input [DATA_WIDTH-1 : 0]expected_data);
		begin
			apb_write(32'h00, expected_data);   // Write Data

			wait_rx_ready();
			@(posedge clk);          // Extra One CLK Wait

			apb_read(32'h04);       // Read RX Data Register

			// Update Total Test Count
			total_count = total_count +1;

			// Self Checking
			if(PRDATA[DATA_WIDTH-1 : 0] == expected_data) begin
				pass_count = pass_count + 1;
				$display("[%0t] PASS: Expected = %h Received = %h", $time, expected_data, PRDATA[DATA_WIDTH-1 : 0]);
			end
			else begin
				fail_count = fail_count + 1;
				$display("[%0t] FAIL: Expected = %h Received = %h", $time, expected_data, PRDATA[DATA_WIDTH-1 : 0]);
			end
		end
	endtask


	/////////////////////////////////
	// Run Directed Tests Task
	/////////////////////////////////
	task run_directed_tests;
		begin
			$display("----------Directed Test----------");
			run_test(8'h00); // all zeros
			run_test(8'hFF); // all ones
			run_test(8'h55); // alternating
			run_test(8'hAA); // alternating
			run_test(8'h7F);
			run_test(8'h80);
			run_test(8'hA5);
			run_test(8'h3C);
			run_test(8'hB8);
			run_test(8'h1C);
		end
	endtask


	/////////////////////////////////
	// Run Random Tests Task
	/////////////////////////////////
	task run_random_tests( input integer num_test);
		begin
			$display("----------Random Test----------");
			for (i=0; i<num_test; i=i+1) begin
				random_data = $random;
				run_test(random_data);
			end
		end
	endtask


	////////////////////////////////
	// Print Summary task
	////////////////////////////////
	task print_summary;
		begin
			$display("-----------------------------------");
			$display("TOTAL TEST = %0d", total_count);
			$display("TOTAL PASS = %0d", pass_count);
			$display("TOTAL FAIL = %0d", fail_count);
			$display("-----------------------------------");

			if (fail_count == 0)
				$display("********* ALL TESTS PASSED *********");
			else
				$display("********* TEST FAILED *********");

		end
	endtask


	//////////////////////////////////
	// Stimulus
	//////////////////////////////////
	initial begin
		clk = 1'b0;
		rst = 1'b0;
		PADDR   = 0;
		PWDATA  = 0;
		PSEL    = 1'b0;
		PWRITE  = 1'b0;
		PENABLE = 1'b0;

		total_count = 0;
		pass_count = 0;
		fail_count = 0;

		#100;
		rst = 1'b1;


		run_directed_tests();

		run_random_tests(20);

		print_summary();

		#200;
		$finish;
	end


	initial begin
		$dumpfile("apb_uart_dump.vcd");
		$dumpvars(0, apb_uart_tb);
	end
endmodule
