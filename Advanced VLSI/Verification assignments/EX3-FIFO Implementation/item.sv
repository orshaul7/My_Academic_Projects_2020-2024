class fifo_item;
	// 1. Transaction Definition

    rand logic wr_req;
    rand logic rd_req;
	rand logic [WIDTH-1:0] wr_data ;
	logic [WIDTH-1:0] rd_data ; 
	logic full_o;
	logic empty_o; 	
	rand bit [2:0] delay;

	// Constraint to ensure rd_req and wr_req are not both high at the same time
	constraint no_parallel_read_write {(rd_req ^ wr_req);}

	// Constraint to ensure a delay after a read request
	constraint delay_after_read {rd_req -> delay >= 1;solve rd_req before delay;}
	
endclass : fifo_item

