//Author : George

//Project 2


module matvec8_part3(clk, reset, input_valid, input_ready, input_data,new_matrix, output_valid, output_ready, output_data);
	input 				 		clk, reset, input_valid, output_ready, new_matrix;
	input signed [13:0]  		input_data;
	output logic signed [27:0] 	output_data;
	output 		 				output_valid, input_ready;
	parameter 					WIDTH=14; 
	parameter                   SIZE_X=8;
	parameter                   SIZE_W=64;
	localparam          		LOGSIZE_x=$clog2(SIZE_X);//Removed inorder to have one counter for address incrementing
	localparam 					LOGSIZE_w=$clog2(SIZE_W);
	logic [LOGSIZE_x-1:0] 		addr_x;
	logic [LOGSIZE_w-1:0] 		addr_w;
	logic wr_en_x, wr_en_w, clear_acc, en_acc;
	
	logic [13:0] mem_x_r, mem_w_r;
	

	
control_path #(LOGSIZE_x, LOGSIZE_w) cntrl(clk,reset,input_valid,output_ready,addr_x, wr_en_x, addr_w, wr_en_w, clear_acc, en_acc, input_ready, output_valid,new_matrix);
data_path data(input_data, clk, reset, addr_x, wr_en_x, addr_w, wr_en_w, clear_acc, en_acc, output_data, mem_x_r, mem_w_r);
	
endmodule	


//Memory module
module memory(clk, data_in, data_out,addr, wr_en);
	parameter 			WIDTH=16, SIZE=64, ADDR_SIZE = $clog2(SIZE);
	localparam          LOGSIZE=$clog2(SIZE);
	input [WIDTH-1:0]	data_in;
	output logic [WIDTH-1:0] data_out;
	input [ADDR_SIZE-1:0] addr;
	input				clk,wr_en;
	
	logic [SIZE-1:0][WIDTH-1:0] mem;
	always_ff @(posedge clk) begin
		data_out<=mem[addr];
		if(wr_en)
			mem[addr]<=data_in;
	end
endmodule

//Based of part3_mac
module data_path(input_data, clk, reset, addr_x, wr_en_x, addr_w, wr_en_w, clear_acc, en_acc, output_data,mem_x_r, mem_w_r);
	input signed [13:0] 		input_data;
	input 						clk, reset, wr_en_x,wr_en_w,clear_acc,en_acc;// is clear_acc same as reset?
	output logic signed [27:0] 	output_data;
	parameter 					WIDTH=14; 
	parameter                   SIZE_X=8;
	parameter                   SIZE_W=64;
	localparam          		LOGSIZE_x=$clog2(SIZE_X);//Removed inorder to have one counter for address incrementing
	localparam 					LOGSIZE_w=$clog2(SIZE_W);
	input [LOGSIZE_x-1:0] 		addr_x;
	input [LOGSIZE_w-1:0] 		addr_w;
	
	output logic signed [13:0] mem_x_r, mem_w_r; //remove debug:output word added
    logic signed [27:0] f_wire, mult_x_r_w_r;
	
	// Instantiate memory x
	// Here WIDTH is the Width, SIZE_X is the size of the 2D memory array
	memory #(WIDTH,SIZE_X,LOGSIZE_x) mem_x(.clk(clk),.data_in(input_data),.data_out(mem_x_r),.addr(addr_x),.wr_en(wr_en_x));
	
	//Instantiate memory W
	// Here WIDTH is the Width, SIZE_W is the size of the 2D memory array
	memory #(WIDTH,SIZE_W,LOGSIZE_w) mem_w(.clk(clk),.data_in(input_data),.data_out(mem_w_r),.addr(addr_w),.wr_en(wr_en_w));
	
	// Output register f
	always_ff @(posedge clk) begin
		if (reset == 1 || clear_acc == 1) begin
			output_data   <= 0;
        end
        else begin
			if (en_acc == 1) begin
				output_data <= f_wire;
			end
        end
    end
		
	// Multiply and accumulate with satuaration functionality
	always_comb begin
		mult_x_r_w_r = mem_x_r*mem_w_r;
		f_wire = output_data + mult_x_r_w_r;
		if (~(output_data[27] ^ mult_x_r_w_r[27]) & (output_data[27]^f_wire[27])) begin
			if(output_data[27] == 0)
				f_wire = 134217727;
			else
				f_wire = -134217728;
		end
		else begin
			f_wire = output_data + mult_x_r_w_r;
		end
		
	end 
endmodule




module control_path(clk,reset,input_valid,output_ready,addr_x, wr_en_x, addr_w, wr_en_w, clear_acc, en_acc, input_ready, output_valid, new_matrix);
	parameter LOGSIZE_x=3, LOGSIZE_w=9;
	input clk, reset, input_valid, output_ready, new_matrix;
	output logic wr_en_x, wr_en_w, clear_acc, en_acc, input_ready, output_valid;
	output logic [LOGSIZE_x-1:0] addr_x;
	output logic [LOGSIZE_w-1:0] addr_w;
	logic output_ready_r;
	logic clr_cntr, incr_delay_cntr, clr1, incr_w_addr, clr2, incr_x_addr;
	logic [2:0]delay_cntr;
	parameter [2:0] RESET = 3'b000, LOAD_W = 3'b001, LOAD_X = 3'b010, EXEC = 3'b011, STALL1 = 3'b100,STALL = 3'b101; //remove debug and add enums
	logic [2:0] state, next_state; 
	
	// Output logic
    always_comb begin
		clr_cntr 		= 0;
		incr_delay_cntr = 0;
		clr1 		 = 0;
		clr2		 = 0;
        incr_w_addr  = 0;
		incr_x_addr	 = 0;
		wr_en_w		 = 0;
		wr_en_x		 = 0;
		en_acc		 = 0;
		clear_acc 	 = 0;
		input_ready  = 0;
		output_valid = 0;
		
		if (state == RESET) begin // These signals will be sampled on the second clock cycle after reset 
			clr_cntr 		= 0;
			incr_delay_cntr = 0;	
			// counter w
			clr1 		= 0;
			if (input_valid == 1)begin
				if ( new_matrix == 1)begin
					incr_w_addr = 1;
					wr_en_w		= 1;
				end
				else begin
					incr_x_addr = 1;
					wr_en_x		= 1;
				end
			end
			else begin
				incr_w_addr = 0;
				wr_en_w		= 0;
				incr_x_addr = 0;
				wr_en_x		= 0;
			end
			input_ready = 1;
			//Counter x
			clr2		= 0;
			
			en_acc		= 0;
			clear_acc 	= 1;
			output_valid = 0;
		
		end
		else if (state == LOAD_W && ~(addr_w == 63)) begin // MOVE to LOADX state
            //Counter w
			clr1 		= 0;
			if (input_valid == 1) begin
				incr_w_addr = 1;
				wr_en_w		= 1;// Wait for next cycle to make it 0 because memory block takes this in next cycle
				//input_ready = 0;				
			end
			else begin
				incr_w_addr = 0;
				wr_en_w		= 0;// Wait for next cycle to make it 0 because memory block takes this in next cycle
				//input_ready = 1;
			end
			input_ready = 1;
			//Counter x
			clr2		= 0;

			incr_x_addr = 0;
			wr_en_x		= 0;// Counter x is 0 at this point
	
			en_acc		= 0;
			clear_acc 	= 1;
			output_valid = 0;
		end	
        else if (state == LOAD_W && addr_w == 63) begin // MOVE to LOADX state
            //Counter w
			incr_w_addr = 0;
			clr1 		= 0; // Keep the counter w value 8 and clear it together with counter x when it becomes 2
			if (input_valid == 1) begin
				wr_en_w		= 1;// Wait for next cycle to make it 0 because memory block takes this in next cycle
				//input_ready = 0;
			end
			else begin
				wr_en_w		= 0;// Wait for next cycle to make it 0 because memory block takes this in next cycle
				//input_ready = 1;
			end
			input_ready = 1;
			//Counter x
			clr2		= 0;
			incr_x_addr = 0;
			wr_en_x		= 0;// Counter x is 0 at this point
			en_acc		= 0;
			clear_acc 	= 1;
			output_valid = 0;
		end
				// For making wr_en_w to 0 so that w memory's 8th index is not over written to
		else if (state == LOAD_X && addr_x == 0)begin 
			//Counter w
			clr1 		= 0;
			incr_w_addr = 0;
			wr_en_w		= 0;
			//Counter x
			clr2		= 0;
			if (input_valid == 1) begin
				incr_x_addr = 1;
				wr_en_x		= 1;
				//input_ready = 0;
			end
			else begin
				incr_x_addr = 0;
				wr_en_x		= 0;
				//input_ready = 1;
			end
			input_ready = 1;
			en_acc		= 0;
			clear_acc 	= 1;
			output_valid = 0;
		end
		// For making wr_en_w to 0 so that w memory's 8th index is not over written to
		else if (state == LOAD_X && ~(addr_x == 7))begin 
			//Counter w
			clr1 		= 0;
			incr_w_addr = 0;
			wr_en_w		= 0;
			//Counter x
			clr2		= 0;
			if (input_valid == 1) begin
				incr_x_addr = 1;
				wr_en_x		= 1;
				//input_ready = 0;
			end
			else begin
				incr_x_addr = 0;
				wr_en_x		= 0;
				//input_ready = 1;
			end
			input_ready = 1;
			en_acc		= 0;
			clear_acc 	= 1;
			output_valid = 0;
		end																
		// Here when addr_x == 2 && addr_w == 8 means we gave loaded both x and w
		// Here when addr_x == 2 && addr_w == 0 means only x is loaded, and addr_w reused.
		else if (state == LOAD_X && addr_x == 7 && (addr_w == 63 || addr_w == 0)) begin // Next cycle move to STALL state.
			//Counter w
			incr_w_addr = 0;
			wr_en_w		= 0;
			//Counter x
			incr_x_addr	= 0;
			if (input_valid == 1) begin
				clr1 		= 1;
				clr2		= 1;
				wr_en_x		= 1;//Wait for next cycle to make it 0 because memory block takes this in next cycle
				//input_ready = 0;
			end
			else begin
				clr1 		= 0;
				clr2		= 0;
				wr_en_x		= 0;
				//input_ready = 1;
			end
			input_ready = 1;
			en_acc		= 0;
			clear_acc 	= 1;
			output_valid = 0;
		end
		// This STALL state is for waiting a state so that memory X's previous value(2nd index locations write) of x is not used for execution
		else if(state == STALL1 && addr_x == 0) begin
			clr_cntr 		= 0;
			incr_delay_cntr = 0;
			
			//Counter w
			clr1 		= 0;
			incr_w_addr = 1;
			wr_en_w		= 0;
			//Counter x
			clr2		= 0;// Perform clr in the next cycle
			incr_x_addr	= 1;
			wr_en_x		= 0;
			
			en_acc		= 0;
			clear_acc 	= 1;
			input_ready = 0;
			output_valid = 0;
		end
		else if(state == EXEC && addr_w == 0 && addr_x == 0) begin // Only first cycle after entering the execution mode
			//Counter w
			clr1 		= 0; 
			incr_w_addr = 1;
			wr_en_w		= 0;
			//Counter x
			clr2		= 0;
			incr_x_addr	= 1;
			wr_en_x		= 0;
			
			en_acc		= 1;// Next cycle will have mac result of 0th index of w and 2nd index of x. We need to wait for index 0 of w and x, to enable the acc
			clear_acc 	= 0;// will have mac result of 8th index of w and 2nd index of x. So only in next cycle make this 1.
			input_ready = 0;
			output_valid = 0;			
		end
		else if(state == EXEC && ~(addr_x == 7)) begin
			//Counter w
			clr1 		= 0;
			incr_w_addr = 1;
			wr_en_w		= 0;
			//Counter x
			clr2		= 0;
			incr_x_addr	= 1;
			wr_en_x		= 0;
			
			en_acc		= 1;
			clear_acc 	= 0;
			input_ready = 0;
			output_valid = 0;
		end
		else if(state == EXEC && addr_x == 7) begin
			//start delay counter in the next clock
			clr_cntr 		= 0;
			incr_delay_cntr = 1;
			
			//Counter w
			clr1 		= 0;
			if(addr_w == 63)begin
				incr_w_addr = 0; // Stop counting when addr_w = 8 and addr_x == 2, this means that after delay =3 , we move to reset state
			end
			else begin
				incr_w_addr = 1;
			end
			wr_en_w		= 0;
			//Counter x
			clr2		= 1;// Perform clr in the next cycle
			if(addr_w == 63)begin
				incr_x_addr = 0;
			end
			else begin
				incr_x_addr = 1;
			end
			wr_en_x		= 0;
			
			en_acc		= 1;
			clear_acc 	= 0;
			input_ready = 0;
			output_valid = 0;
		end
		else if(state == STALL && delay_cntr == 1) begin
			//Keep the delay counter running
			clr_cntr 		= 0;
			incr_delay_cntr = 1;
			
			//Now stall the counter till the row MAC result is read by the output stream
			//Counter w
			clr1 		= 0;
			incr_w_addr = 0;
			wr_en_w		= 0;
			//Counter x
			clr2		= 0;
			incr_x_addr	= 0;
			wr_en_x		= 0;
			
			en_acc		= 1;
			clear_acc 	= 0;
			input_ready = 0;
			output_valid = 0;
		end
		// Keep executing this until output is read by the dest port
		else if(state == STALL && delay_cntr == 2) begin //Change this two for pipelining
			//stop the delay counter in the next clock cycle, but don't clear the value of 2, because we will be stuck in this loop till we get out_put ready
			clr_cntr 	= 0;
			
			clr1 		= 0;
			if(addr_w == 63)begin
				incr_w_addr = 0; // Stop counting when addr_w = 8 and addr_x == 2, this means that after delay =3 , we move to reset state
			end
			else begin
				incr_w_addr = 0;
			end
			wr_en_w		= 0;
			
			if(addr_w == 63)begin
				incr_x_addr = 0; // Stop counting when addr_w = 8 and addr_x == 2, this means that after delay =3 , we move to reset state
			end
			else begin
				incr_x_addr = 0;
			end
			wr_en_x		= 0;
			clr2		= 0;
			en_acc      = 0;
			input_ready = 0;
			//Keep stalling the counter till the row MAC result is read by the output stream
			//Counter w
			output_valid = 1;
			incr_delay_cntr = 1;
			clear_acc     = 0;
		end
		
		// Keep executing this until output is read by the dest port
		else if(state == STALL && delay_cntr == 3) begin //Change this two for pipelining
			//stop the delay counter in the next clock cycle, but don't clear the value of 2, because we will be stuck in this loop till we get out_put ready
			clr_cntr 	= 0;		
			clr1 		= 0;
			wr_en_w		= 0;
			
			if(addr_w == 63)begin
				incr_x_addr = 0; // Stop counting when addr_w = 8 and addr_x == 2, this means that after delay =3 , we move to reset state
			end
			else begin
				//incr_x_addr = 1;
			end
			wr_en_x		= 0;
			clr2		= 0;
			en_acc      = 0;
			input_ready = 0;
			//Keep stalling the counter till the row MAC result is read by the output stream
			//Counter w
			if( output_ready_r == 1) begin
				incr_delay_cntr = 1;// Increment the delay counter one last time
				clear_acc 	= 1; //Clear the acc value in the next cycle since we are starting the acc for the next row in next to next cycle
				output_valid = 0;
				if(addr_w == 63)begin
					incr_w_addr = 0; // Stop counting when addr_w = 8 and addr_x == 2, this means that after delay =3 , we move to reset state
					incr_x_addr = 0;
				end
				else begin
					incr_w_addr = 1;
					incr_x_addr = 1;
				end
			end 
			else begin
				output_valid = 1;
				incr_delay_cntr = 0;
				clear_acc     = 0;
				incr_w_addr = 0;
				incr_x_addr = 0;				
			end
		end
		// Here we are just bringing the clear_acc to 0, so that next cycle onwards the row mac result will be passed through
		else if(state == STALL && delay_cntr == 4) begin  
			//Keep the delay counter running
			clr_cntr 		= 1;// Clear the delay counter because next cycle we start counting
			incr_delay_cntr = 0;
			
			// Next state is RESET
			if(addr_w == 63) begin
				//Now stall the counter till the row MAC result is read by the output stream
				//Counter w
				clr1 		= 1;
				incr_w_addr = 0;
				wr_en_w		= 0;
				//Counter x
				clr2		= 1;
				incr_x_addr	= 0;
				wr_en_x		= 0;
				
				en_acc		= 0;
				clear_acc 	= 0;
				input_ready = 0;
				output_valid = 0;
			end
			// Next state is EXEC
			else begin
				//Counter w
				clr1 		= 0;
				incr_w_addr = 1;
				wr_en_w		= 0;
				//Counter x
				clr2		= 0;
				incr_x_addr	= 1;
				wr_en_x		= 0;
				
				en_acc		= 1;
				clear_acc 	= 0;
				input_ready = 0;
				output_valid = 0;
			end
		end
	end

	// FSM next state logic
	always_comb begin
		next_state = 0;
        if (state == RESET )begin
			next_state = RESET;
			if(input_valid == 1)
				next_state = LOAD_X;
				if(new_matrix ==1)
				next_state = LOAD_W;
		end
		else if (state == LOAD_W)begin
			next_state = LOAD_W;
			if(input_valid ==1 && addr_w == 63)
				next_state = LOAD_X;
		end
		else if (state == LOAD_X) begin	
			next_state = LOAD_X;
			if(input_valid == 1 && addr_x == 7 && (addr_w == 63 || addr_w == 0))
				next_state = STALL1;
		end
		else if (state == STALL1)begin
			next_state = STALL1;
			if(addr_x == 0 && addr_w == 0)
				next_state = EXEC;
		end
		else if (state == EXEC)begin
			next_state = EXEC;
			if(addr_x == 7)
				next_state = STALL;
		end
		else if(state == STALL) begin
			next_state = STALL;
			if(delay_cntr == 4) begin
				if(addr_w == 63)
				next_state = RESET;
				else
				next_state = EXEC;
			end
		end
	end	
	
	// FSM resgister
	always_ff @(posedge clk) begin
        if (reset == 1)
            state <= RESET;
        else
            state <= next_state;
    end 
	
	// Counter for incrementing address for memory array used to store matrix W
	always_ff @(posedge clk) begin
		if (reset == 1 || clr1 == 1) begin
			addr_w 	  <= 0;	
		end
		else if(incr_w_addr ==1) begin	
				addr_w <= addr_w + 1;
		end	
	end
	
	// Counter for incrementing address for memory array used to store vector x
	always_ff @(posedge clk) begin
		if (reset == 1 || clr2 == 1) begin
			addr_x <= 0;	
		end
		else if(incr_x_addr ==1) begin		
			addr_x <= addr_x + 1;
		end
	end
	
	
	// Counter for incrementing address for memory array used to store vector x
	always_ff @(posedge clk) begin
		if (reset == 1 || clr_cntr == 1) begin
			delay_cntr <= 0;	
		end
		else if(incr_delay_cntr == 1) begin		
			delay_cntr <= delay_cntr + 1;
		end
	end
	
	//output_ready is made synchronous
	always_ff @(posedge clk) begin
		if (reset == 1) 
			output_ready_r <= 0;
		else
			output_ready_r <= output_ready;
	end
	
endmodule

 
