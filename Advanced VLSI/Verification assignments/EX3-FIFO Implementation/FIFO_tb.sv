module fifo_testbench;

// ---------------------- //
//    Clock and reset     //
//   Do not modify		  //
// ---------------------- //

	bit clk;
	bit rstn;
	
	// This initial block initializes clk, rstn, and 'turns on' the FIFO by driving 1 to rstn after 2 cycles.
	initial begin
		clk = 1'b0;
		rstn = 1'b0;
		
		@(posedge clk);
		@(posedge clk);
		rstn = 1'b1;
	end
	
	// This always block generates our clk
	always #5 clk = ~clk;
	
	// ---------------------- //
	//    Instantiations 	  //
	//  DO modify			  //
	// ---------------------- //
	
	// Interface Instantiation (2.2)
	fifo_if fifo_interface (.clk(clk), .rstn(rstn));

	
	// Design Module Instantiation (2.3)

	fifo u_fifo (
		.clk(clk),
		.rstn(rstn),
		.rd_req(fifo_interface.rd_req),
		.wr_req(fifo_interface.wr_req),
		.w_data(fifo_interface.wr_data),
		.r_data(fifo_interface.rd_data),
		.full_o(fifo_interface.full_o),
		.empty_o(fifo_interface.empty_o)
	);
	
	
	
	

	// ---------------------- //
	//  Testbench components
	// ---------------------- // 
	
	mailbox #(fifo_item) generator_to_driver_mailbox;
	mailbox #(fifo_item) monitor_to_model_mailbox;
	
	
	
	// 3. Generator
	task Generator();
     
		fifo_item item;  // Declare fifo_item variable
			
		repeat (1000) begin
			item = new();  // Instantiate fifo_item
			item.randomize();  // Randomize fifo_item properties
			generator_to_driver_mailbox.put(item);	
			
			// print the generated item
			$display("Generated item: wr_req=%b, rd_req=%b, wr_data=0x%h, delay=%d",
						item.wr_req, item.rd_req, item.wr_data, item.delay);
		end

	endtask : Generator
	
	
	
	// 4. Driver
	task Driver;
		
		fifo_item item;
		forever begin
			
		  generator_to_driver_mailbox.get(item);
			
		  repeat (item.delay) @(posedge clk);
				fifo_interface.wr_req<=item.wr_req;
				fifo_interface.rd_req<=item.rd_req;
				fifo_interface.wr_data<=item.wr_data; 
				
				@(posedge clk);
				fifo_interface.wr_req<=1'b0;
				fifo_interface.rd_req<=1'b0;
				fifo_interface.wr_data<='x; 
		end
		
	endtask : Driver
	
	
	
	
	
	

	// 5. Monitor
	task Monitor();
		
		fifo_item item;
		
		forever begin
			@(posedge clk);
			item=new();
			
			if (fifo_interface.wr_req) begin
				item.wr_req = fifo_interface.wr_req;
				item.wr_data = fifo_interface.wr_data;

				item.full_o = fifo_interface.full_o;
				monitor_to_model_mailbox.put(item);

				// Print transaction details for write requests
				$display("Write Request: wr_req=%b, wr_data=0x%0h, full_o=%b, Time:%0t", 
						 item.wr_req, item.wr_data, item.full_o, $time());
			end
			
			if (fifo_interface.rd_req) begin
				item.rd_req = fifo_interface.rd_req;
				// Wait one clock cycle before capturing rd_data


				item.empty_o = fifo_interface.empty_o;
				
				@(posedge clk);

				item.rd_data = fifo_interface.rd_data;
				
				monitor_to_model_mailbox.put(item);

				// Print transaction details for read requests
				$display("Read Request: rd_req=%b, rd_data=0x%0h, empty_o=%b, Time:%0t",
						 item.rd_req, item.rd_data, item.empty_o, $time());
			end
		
		end

	endtask : Monitor
	
	
	
	
	// 6. Model 
	task Model();
		fifo_item item;
		fifo_item temp_item;
		fifo_item reference_fifo [$:DEPTH];  // Dynamic array for reference FIFO

		forever begin
			monitor_to_model_mailbox.get(item);  // Get transaction from Monitor task

			// Handle write requests
			if (item.wr_req) begin
				if (reference_fifo.size() < DEPTH) begin  // Check if reference FIFO is not full
					if (item.full_o)  // Check if RTL full
						$error("Mismatch with Full signal - reference_fifo isn't full and full_o=1");
					else
						reference_fifo.push_back(item);  // Push the item to the reference FIFO
				end else if (!item.full_o)  // Check if RTL full
						     $error("Mismatch with Full signal - reference_fifo is full and full_o=0");
				end
			end


			// Handle read requests
			if (item.rd_req) begin
				if (reference_fifo.size() > 0) begin  // Check if reference FIFO is not empty
					if (item.empty_o)  // Check if RTL empty
						$error("Mismatch with Empty signal - reference_fifo isn't empty and empty_o=1");
					else begin
						temp_item = reference_fifo.pop_front();  // Pop the item from the reference FIFO
						if (item.rd_data !== temp_item.wr_data)  // Compare read data from RTL and reference FIFO
							$error("Mismatch with read data - reference_fifo data was written: 0x%h, data read from RTL: 0x%h", temp_item.wr_data, item.rd_data);
					end
				end else begin
					if (!item.empty_o)  // Check if RTL empty 
						$error("Mismatch with Empty signal - reference_fifo is empty and empty_o=0");
				end
			end
	endtask



	
	// ---------------------- //
	//    Simulation start    //
	//    Do not modify       // 
	// ---------------------- //
	initial begin
		
		// Testbench component instantiation
		generator_to_driver_mailbox = new();
		monitor_to_model_mailbox    = new();
		
		@(rstn == '1);
		@(posedge clk);
		
		fork
			Generator();
			Driver();
			Monitor();
			Model();
		join
		
	end
	
	initial begin
		#10000;
		$finish();
		
	end

endmodule

