//Author : George

//Project 2


module matvec8_part4(clk, reset, input_valid, input_ready, input_data,new_matrix, output_valid, output_ready, output_data);
	input 				 		clk, reset, input_valid, new_matrix;				
	input signed [13:0]  		input_data;
	logic signed [27:0] 	    output_data1,output_data2,output_data3,output_data4,output_data5,output_data6,output_data7,output_data8;
	output 		 				output_valid, input_ready;
	output logic signed [27:0]	output_data;
	parameter 					WIDTH=14; 
	parameter                   SIZE_X=8;
	parameter                   SIZE_W=8;
	parameter                   SIZE_X_r=8;
	parameter                   SIZE_W_r=64;
	localparam          		LOGSIZE_x=$clog2(SIZE_X);
	localparam 					LOGSIZE_w=$clog2(SIZE_W);
	localparam          		LOGSIZE_x_r=$clog2(SIZE_X_r);
	localparam 					LOGSIZE_w_r=$clog2(SIZE_W_r);
	logic [LOGSIZE_w-1:0] 		addr_w_p;
	logic [LOGSIZE_x_r-1:0] 		addr_x;
	logic [LOGSIZE_w_r-1:0] 		addr_w;
	logic clear_acc, en_acc;
	logic wr_en_x;
	logic wr_en_w1,wr_en_w2,wr_en_w3,wr_en_w4,wr_en_w5,wr_en_w6,wr_en_w7,wr_en_w8;
	logic [13:0] mem_x_r1,mem_x_r2,mem_x_r3,mem_x_r4,mem_x_r5,mem_x_r6,mem_x_r7,mem_x_r8, mem_w_r1,mem_w_r2,mem_w_r3,mem_w_r4,mem_w_r5,mem_w_r6,mem_w_r7,mem_w_r8;
	input output_ready;
	logic [27:0] mult_x_r_w_r1, mult_x_r_w_r_delay1, mult_x_r_w_r2, mult_x_r_w_r_delay2, mult_x_r_w_r3, mult_x_r_w_r_delay3, mult_x_r_w_r4, mult_x_r_w_r_delay4, mult_x_r_w_r5, mult_x_r_w_r_delay5, mult_x_r_w_r6, mult_x_r_w_r_delay6, mult_x_r_w_r7, mult_x_r_w_r_delay7, mult_x_r_w_r8, mult_x_r_w_r_delay8;
	logic [3:0] y;
	
	
	always_comb begin
		output_data = 0;
		if (y == 0)
			output_data = output_data1;
		else if (y == 1)
			output_data = output_data2;
		else if (y == 2)
			output_data = output_data3;
		else if (y == 3)
			output_data = output_data4; 
		else if (y == 4)
			output_data = output_data5;
		else if (y == 5)
			output_data = output_data6;
		else if (y == 6)
			output_data = output_data7;
		else if (y == 7)
			output_data = output_data8;
		else 
			output_data = 0;
	end
	
control_path #(LOGSIZE_x, LOGSIZE_w, LOGSIZE_x_r, LOGSIZE_w_r) cntrl(clk,reset,input_valid,output_ready, wr_en_x, addr_w_p, wr_en_w1,wr_en_w2,wr_en_w3,wr_en_w4,wr_en_w5,wr_en_w6,wr_en_w7,wr_en_w8, clear_acc, en_acc, input_ready, output_valid,new_matrix,y,addr_w,addr_x);


//8 MACs run in parallel to produce 8 output values parallelly
data_path data1(input_data, clk, reset, addr_x, wr_en_x, addr_w_p, wr_en_w1, clear_acc, en_acc, output_data1, mem_x_r1, mem_w_r1, mult_x_r_w_r1, mult_x_r_w_r_delay1);
data_path data2(input_data, clk, reset, addr_x, wr_en_x, addr_w_p, wr_en_w2, clear_acc, en_acc, output_data2, mem_x_r2, mem_w_r2, mult_x_r_w_r2, mult_x_r_w_r_delay2);
data_path data3(input_data, clk, reset, addr_x, wr_en_x, addr_w_p, wr_en_w3, clear_acc, en_acc, output_data3, mem_x_r3, mem_w_r3, mult_x_r_w_r3, mult_x_r_w_r_delay3);
data_path data4(input_data, clk, reset, addr_x, wr_en_x, addr_w_p, wr_en_w4, clear_acc, en_acc, output_data4, mem_x_r4, mem_w_r4, mult_x_r_w_r4, mult_x_r_w_r_delay4);
data_path data5(input_data, clk, reset, addr_x, wr_en_x, addr_w_p, wr_en_w5, clear_acc, en_acc, output_data5, mem_x_r5, mem_w_r5, mult_x_r_w_r5, mult_x_r_w_r_delay5);
data_path data6(input_data, clk, reset, addr_x, wr_en_x, addr_w_p, wr_en_w6, clear_acc, en_acc, output_data6, mem_x_r6, mem_w_r6, mult_x_r_w_r6, mult_x_r_w_r_delay6);
data_path data7(input_data, clk, reset, addr_x, wr_en_x, addr_w_p, wr_en_w7, clear_acc, en_acc, output_data7, mem_x_r7, mem_w_r7, mult_x_r_w_r7, mult_x_r_w_r_delay7);
data_path data8(input_data, clk, reset, addr_x, wr_en_x, addr_w_p, wr_en_w8, clear_acc, en_acc, output_data8, mem_x_r8, mem_w_r8, mult_x_r_w_r8, mult_x_r_w_r_delay8);
	
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
module data_path(input_data, clk, reset, addr_x, wr_en_x, addr_w, wr_en_w, clear_acc, en_acc, output_data,mem_x_r, mem_w_r, mult_x_r_w_r, mult_x_r_w_r_delay);
	input signed [13:0] 		input_data;
	input 						clk, reset,clear_acc,en_acc, wr_en_x, wr_en_w;
	output logic signed [27:0]	output_data;
	parameter 					WIDTH=14; 
	parameter                   SIZE_X=8;
	parameter                   SIZE_W=8;
	localparam          		LOGSIZE_x=$clog2(SIZE_X);
	localparam 					LOGSIZE_w=$clog2(SIZE_W);
	input [LOGSIZE_x-1:0] 		addr_x;
	input [LOGSIZE_w-1:0] 		addr_w;
	
	output logic signed [13:0] mem_x_r, mem_w_r; 
    logic signed [27:0] f_wire; 
	output logic signed [27:0] mult_x_r_w_r, mult_x_r_w_r_delay;
	
	// Instantiate memory xaddr_w_p
	memory #(WIDTH,SIZE_X,LOGSIZE_x) mem_x(.clk(clk),.data_in(input_data),.data_out(mem_x_r),.addr(addr_x),.wr_en(wr_en_x));
	
	//Instantiate memory W
	memory #(WIDTH,SIZE_W,LOGSIZE_w) mem_w(.clk(clk),.data_in(input_data),.data_out(mem_w_r),.addr(addr_w),.wr_en(wr_en_w));
	
	// Output register f
	always_ff @(posedge clk) begin
		mult_x_r_w_r_delay <= mult_x_r_w_r;
		if (reset == 1 || clear_acc == 1) begin
			output_data   <= 0;
			mult_x_r_w_r_delay <= 0;
        end
        else begin
			if (en_acc == 1) begin
				output_data <= f_wire;
			end
        end
    end
	DW02_mult_6_stage #(14, 14) multinstance(mem_x_r, mem_w_r, 1'b1, clk, mult_x_r_w_r); // multiplying through designware component
	// Multiply and accumulate with satuaration functionality
	always_comb begin
		f_wire = output_data + mult_x_r_w_r_delay;
		if (~(output_data[27] ^ mult_x_r_w_r_delay[27]) & (output_data[27]^f_wire[27])) begin
			if(output_data[27] == 0)
				f_wire = 134217727;
			else
				f_wire = -134217728;
		end
		else begin
			f_wire = output_data + mult_x_r_w_r_delay;
		end
		
	end
endmodule

//control path designed using FSM
module control_path(clk,reset,input_valid,output_ready, wr_en_x, addr_w_p, wr_en_w1,wr_en_w2,wr_en_w3,wr_en_w4,wr_en_w5,wr_en_w6,wr_en_w7,wr_en_w8, clear_acc, en_acc, input_ready, output_valid, new_matrix,y,addr_w,addr_x);
	parameter LOGSIZE_x=3, LOGSIZE_w=9, LOGSIZE_x_r =3, LOGSIZE_w_r = 9;
	input clk, reset, input_valid, output_ready, new_matrix;
	output logic clear_acc, en_acc, input_ready, output_valid;
	
	output logic wr_en_x;
	output logic wr_en_w1,wr_en_w2,wr_en_w3,wr_en_w4,wr_en_w5,wr_en_w6,wr_en_w7,wr_en_w8;
	output logic [LOGSIZE_x_r-1:0] addr_x;
	output logic [LOGSIZE_w_r-1:0] addr_w;
	output logic [LOGSIZE_w-1:0] addr_w_p;
	logic output_ready_r;
	logic clr_cntr, incr_delay_cntr, clr1, incr_w_addr, clr2, incr_x_addr;
	logic dec_delay_cntr;
	logic [3:0]delay_cntr;
	parameter [2:0] RESET = 3'b000, LOAD_W = 3'b001, LOAD_X = 3'b010, EXEC = 3'b011, STALL1 = 3'b100,STALL = 3'b101; 
	logic [2:0] state, next_state; 
	output logic [3:0] y;
	
	// Output logic
    always_comb begin
		clr_cntr 		= 0;
		incr_delay_cntr = 0;
		dec_delay_cntr = 0;
		clr1 		 = 0;
		clr2		 = 0;
        incr_w_addr  = 0;
		incr_x_addr	 = 0;
		wr_en_w1		 = 0;
		wr_en_w2		 = 0;
		wr_en_w3		 = 0;
		wr_en_w4		 = 0;
		wr_en_w5		 = 0;
		wr_en_w6		 = 0;
		wr_en_w7		 = 0;
		wr_en_w8		 = 0;
		wr_en_x = 0;
		en_acc		 = 0;
		clear_acc 	 = 0;
		input_ready  = 0;
		output_valid = 0;
		addr_w_p 	 = 0;
		y = 0;
		
		if (state == RESET) begin // These signals will be sampled on the second clock cycle after reset 
			clr_cntr 		= 0;
			incr_delay_cntr = 0;	
			// counter w
			clr1 		= 0;
			if (input_valid == 1)begin
				if ( new_matrix == 1)begin							//memory_w modules written one after the other
					incr_w_addr = 1;
					if(addr_w >= 0 && addr_w <=7)begin
						wr_en_w1 = 1;
						addr_w_p = addr_w;
					end
					else if(addr_w >= 8&& addr_w <=15)begin
						wr_en_w2 = 1;
						addr_w_p = addr_w - 8;
					end
					else if(addr_w >= 16 && addr_w <=23)begin
						wr_en_w3 = 1;
						addr_w_p = addr_w - 16;
					end
					else if(addr_w >= 24 && addr_w <=31)begin
						wr_en_w4 = 1;
						addr_w_p = addr_w - 24;
					end
					else if(addr_w >= 32 && addr_w <=39)begin
						wr_en_w5 = 1;
						addr_w_p = addr_w - 32;
					end
					else if(addr_w >= 40 && addr_w <=47)begin
						wr_en_w6 = 1;
						addr_w_p = addr_w - 40;
					end
					else if(addr_w >= 48 && addr_w <=55)begin
						wr_en_w7 = 1;
						addr_w_p = addr_w - 48;
					end
					else if(addr_w >= 56 && addr_w <=63)begin
						wr_en_w8 = 1;
						addr_w_p = addr_w - 56;
					end
				end
				else begin
					incr_x_addr = 1;
					wr_en_x = 1;
				end
			end
			else begin
				incr_w_addr      = 0;
				wr_en_w1		 = 0;
				wr_en_w2		 = 0;
				wr_en_w3		 = 0;
				wr_en_w4		 = 0;
				wr_en_w5		 = 0;
				wr_en_w6		 = 0;
				wr_en_w7		 = 0;
				wr_en_w8		 = 0;
				incr_x_addr 	 = 0;
				wr_en_x			 = 0;
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
			input_ready = 1;
			//Counter x
			clr2		= 0;

			incr_x_addr = 0;
	
			en_acc		= 0;
			clear_acc 	= 1;
			output_valid = 0;
			if (input_valid == 1) begin
				incr_w_addr = 1;
				if((addr_w >= 0)&& (addr_w <=7))begin
					wr_en_w1 = 1;
					addr_w_p = addr_w;
				end
				else if((addr_w >= 8) && (addr_w <=15))begin
					wr_en_w2 = 1;
					addr_w_p = addr_w - 8;
				end
				else if((addr_w >= 16) && (addr_w <=23))begin
					wr_en_w3 = 1;
					addr_w_p = addr_w - 16;
				end
				else if((addr_w >= 24) && (addr_w <=31))begin
					wr_en_w4 = 1;
					addr_w_p = addr_w - 24;
				end
				else if(addr_w >= 32 && addr_w <=39)begin
					wr_en_w5 = 1;
					addr_w_p = addr_w - 32;
				end
				else if(addr_w >= 40 && addr_w <=47)begin
					wr_en_w6 = 1;
					addr_w_p = addr_w - 40;
				end
				else if(addr_w >= 48 && addr_w <=55)begin
					wr_en_w7 = 1;
					addr_w_p = addr_w - 48;
				end
				else if(addr_w >= 56 && addr_w <=63)begin
					wr_en_w8 = 1;
					addr_w_p = addr_w - 56;
				end		
			end
			else begin
				incr_w_addr = 0;
				wr_en_w1		 = 0;
				wr_en_w2		 = 0;
				wr_en_w3		 = 0;
				wr_en_w4		 = 0;
				wr_en_w5		 = 0;
				wr_en_w6		 = 0;
				wr_en_w7		 = 0;
				wr_en_w8		 = 0;
			end
		end	
        else if (state == LOAD_W && addr_w == 63) begin // MOVE to LOADX state
            //Counter w
			incr_w_addr = 0;
			clr1 		= 0; // Keep the counter w value 8 and clear it together with counter x when it becomes 2
			if (input_valid == 1) begin
				if(addr_w >= 0 && addr_w <=7)begin
					wr_en_w1 = 1;
					addr_w_p = addr_w;
				end
				else if(addr_w >= 8 && addr_w <=15)begin
					wr_en_w2 = 1;
					addr_w_p = addr_w - 8;
				end
				else if(addr_w >= 16 && addr_w <=23)begin
					wr_en_w3 = 1;
					addr_w_p = addr_w - 16;
				end
				else if(addr_w >= 24 && addr_w <=31)begin
					wr_en_w4 = 1;
					addr_w_p = addr_w - 24;
				end
				else if(addr_w >= 32 && addr_w <=39)begin
					wr_en_w5 = 1;
					addr_w_p = addr_w - 32;
				end
				else if(addr_w >= 40 && addr_w <=47)begin
					wr_en_w6 = 1;
					addr_w_p = addr_w - 40;
				end
				else if(addr_w >= 48 && addr_w <=55)begin
					wr_en_w7 = 1;
					addr_w_p = addr_w - 48;
				end
				else if(addr_w >= 56 && addr_w <=63)begin
					wr_en_w8 = 1;
					addr_w_p = addr_w - 56;
				end
			end
			else begin
				wr_en_w1		 = 0;
				wr_en_w2		 = 0;
				wr_en_w3		 = 0;
				wr_en_w4		 = 0;
				wr_en_w5		 = 0;
				wr_en_w6		 = 0;
				wr_en_w7		 = 0;
				wr_en_w8		 = 0;
			end
			input_ready = 1;
			//Counter x
			clr2		= 0;
			incr_x_addr = 0;
			en_acc		= 0;
			clear_acc 	= 1;
			output_valid = 0;
		end
				// For making wr_en_w to 0 so that w memory's 8th index is not over written to
		else if (state == LOAD_X && addr_x == 0)begin 
			//Counter w
			clr1 		= 0;
			incr_w_addr = 0;
			//Counter x
			clr2		= 0;
			if (input_valid == 1) begin
				incr_x_addr = 1;
				wr_en_x = 1;
			end
			else begin
				incr_x_addr = 0;
				wr_en_x     = 0;
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
			//Counter x
			clr2		= 0;
			if (input_valid == 1) begin
				incr_x_addr = 1;
				wr_en_x = 1;
			end
			else begin
				incr_x_addr = 0;
				wr_en_x		= 0;
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
			//Counter x
			incr_x_addr	= 0;
			if (input_valid == 1) begin
				clr1 		= 1;
				clr2		= 1;
				wr_en_x = 1;
			end
			else begin
				clr1 		= 0;
				clr2		= 0;
				wr_en_x   = 0;
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
			//Counter x
			clr2		= 0;// Perform clr in the next cycle
			incr_x_addr	= 1;
			
			en_acc		= 0;
			clear_acc 	= 1;
			input_ready = 0;
			output_valid = 0;
			addr_w_p = 0;
		end
		else if(state == EXEC && addr_w == 0 && addr_x == 0) begin // Only first cycle after entering the execution mode
			//Counter w
			clr1 		= 0; 
			incr_w_addr = 1;
			//Counter x
			clr2		= 0;
			incr_x_addr	= 1;
			
			en_acc		= 1; 
			clear_acc 	= 0;
			input_ready = 0;
			output_valid = 0;

			addr_w_p = addr_x;
	
		end
		else if(state == EXEC && addr_x == 5) begin
			//Counter w
			clr1 		= 0;
			incr_w_addr = 1;
			//Counter x
			clr2		= 0;
			incr_x_addr	= 1;
			
			en_acc		= 0;
			clear_acc 	= 1;
			input_ready = 0;
			output_valid = 0;
			
			addr_w_p = addr_x;
		
		end
		else if(state == EXEC && addr_x == 6) begin //accumulator enabled when mult_x_r_w_r_delay finally reaches output_reg
			//Counter w
			clr1 		= 0;
			incr_w_addr = 1;
			//Counter x
			clr2		= 0;
			incr_x_addr	= 1;
			
			en_acc		= 1;
			clear_acc 	= 0;
			input_ready = 0;
			output_valid = 0;	
			
			addr_w_p = addr_x;	
			
		end
		else if(state == EXEC && ~(addr_x == 7)) begin
			//Counter w
			clr1 		= 0;
			incr_w_addr = 1;
			//Counter x
			clr2		= 0;
			incr_x_addr	= 1;
			
			en_acc		= 0;
			clear_acc 	= 1;
			input_ready = 0;
			output_valid = 0;
			
			
			addr_w_p = addr_x;
          			
		end
		else if(state == EXEC && addr_x == 7) begin
			//start delay counter in the next clock
			clr_cntr 		= 0;
			incr_delay_cntr = 1;
			
			//Counter w
			clr1 		= 0;

			incr_w_addr = 0; // stop counting this counter 

			//Counter x
			clr2		= 1;// Perform clr in the next cycle
			incr_x_addr = 0;//  stop counting this counter.

			
			en_acc		= 1;
			clear_acc 	= 0;
			input_ready = 0;
			output_valid = 0;
			
			
			addr_w_p = addr_x;
		
		end
		else if(state == STALL && delay_cntr == 1) begin
			//Keep the delay counter running until mult_x_r_w_r_delay reaches the final register
			clr_cntr 		= 0;
			incr_delay_cntr = 1;
			
			//Now stall the counter till the row MAC result is read by the output stream
			//Counter w
			clr1 		= 0;
			incr_w_addr = 0;
			//Counter x
			clr2		= 0;
			incr_x_addr	= 0;
			
			en_acc		= 1;
			clear_acc 	= 0;
			input_ready = 0;
			output_valid = 0;
			addr_w_p = addr_x;
		
		end
		
		else if(state == STALL && delay_cntr == 2) begin
			//Keep the delay counter running
			clr_cntr 		= 0;
			incr_delay_cntr = 1;
			
			//Now stall the counter till the row MAC result is read by the output stream
			//Counter w
			clr1 		= 1;
			incr_w_addr = 0;
			//Counter x
			clr2		= 0;
			incr_x_addr	= 0;
			
			en_acc		= 1;
			clear_acc 	= 0;
			input_ready = 0;
			output_valid = 0;
			addr_w_p = addr_x;
		
		end
		else if(state == STALL && delay_cntr == 3) begin
			//Keep the delay counter running
			clr_cntr 		= 0;
			incr_delay_cntr = 1;
			
			//Now stall the counter till the row MAC result is read by the output stream
			//Counter w
			clr1 		= 1;
			incr_w_addr = 0;
			//Counter x
			clr2		= 0;
			incr_x_addr	= 0;
			
			en_acc		= 1;
			clear_acc 	= 0;
			input_ready = 0;
			output_valid = 0;
			addr_w_p = addr_x;
		
		end
		else if(state == STALL && delay_cntr == 4) begin
			//Keep the delay counter running
			clr_cntr 		= 0;
			incr_delay_cntr = 1;
			
			//Now stall the counter till the row MAC result is read by the output stream
			//Counter w
			clr1 		= 1;
			incr_w_addr = 0;
			//Counter x
			clr2		= 0;
			incr_x_addr	= 0;
			
			en_acc		= 1;
			clear_acc 	= 0;
			input_ready = 0;
			output_valid = 0;
			addr_w_p = addr_x;
		
		end
		else if(state == STALL && delay_cntr == 5) begin
			//Keep the delay counter running
			clr_cntr 		= 0;
			incr_delay_cntr = 1;
			
			//Now stall the counter till the row MAC result is read by the output stream
			//Counter w
			clr1 		= 1;
			incr_w_addr = 0;
			//Counter x
			clr2		= 0;
			incr_x_addr	= 0;
			
			en_acc		= 1;
			clear_acc 	= 0;
			input_ready = 0;
			output_valid = 0;
			addr_w_p = addr_x;
		
		end
		else if(state == STALL && delay_cntr == 6) begin
			//Keep the delay counter running
			clr_cntr 		= 0;
			incr_delay_cntr = 1;
			
			//Now stall the counter till the row MAC result is read by the output stream
			//Counter w
			clr1 		= 1;
			incr_w_addr = 0;
			//Counter x
			clr2		= 0;
			incr_x_addr	= 0;
			
			en_acc		= 1;
			clear_acc 	= 0;
			input_ready = 0;
			output_valid = 0;
			addr_w_p = addr_x;

		end
		else if(state == STALL && delay_cntr == 7) begin
			//Keep the delay counter running
			clr_cntr 		= 0;
			incr_delay_cntr = 1;
			
			//Now stall the counter till the row MAC result is read by the output stream
			//Counter w
			clr1 		= 1;
			incr_w_addr = 0;
			//Counter x
			clr2		= 0;
			incr_x_addr	= 0;
			
			en_acc		= 1;
			clear_acc 	= 0;
			input_ready = 0;
			output_valid = 0;
			addr_w_p = addr_x;

		end
		// Keep executing this until output is read by the dest port
		else if(state == STALL && delay_cntr == 8) begin 
			//stop the delay counter in the next clock cycle, but don't clear the value of 2, because we will be stuck in this loop till we get out_put ready
			clr_cntr 	= 0;
			clr1 		= 0;
			incr_x_addr = 0; 
			clr2		= 0;
			en_acc      = 0;
			input_ready = 0;
			//Keep stalling the counter till the row MAC result is read by the output stream
			//Counter w
			output_valid = 1;
			incr_delay_cntr = 1;
			clear_acc     = 0;
			addr_w_p = addr_w;
			y = addr_w_p;
			if(addr_w == 8) begin
				output_valid = 0;
			end
		end
		
		// Keep executing this until output is read by the dest port
		else if(state == STALL && delay_cntr == 9) begin //Change this two for pipelining
			//stop the delay counter in the next clock cycle, but don't clear the value of 2, because we will be stuck in this loop till we get out_put ready
			clr_cntr 	= 0;		
			clr1 		= 0;
			addr_w_p = addr_w;
			y = addr_w_p;
			if(addr_w == 63)begin
				incr_x_addr = 0; 
			end
			else begin
				//incr_x_addr = 1;
			end
			clr2		= 0;
			en_acc      = 0;
			input_ready = 0;
			//Keep stalling the counter till the row MAC result is read by the output stream
			//Counter w
			if( output_ready_r == 1) begin
				if(addr_w <= 7) begin
					dec_delay_cntr = 1;
					incr_w_addr = 1;
				end
				else begin
					clear_acc = 0;  
					incr_delay_cntr = 1;// Increment the delay counter one last time
				end
				clear_acc 	= 0; 
				output_valid = 0;
			end 
			else begin
			    if (addr_w == 8) begin
					output_valid = 0;       //added for output to not read junk values
				end
				else begin
					output_valid = 1;
					incr_delay_cntr = 0;
					clear_acc     = 0;
					incr_w_addr = 0;
					incr_x_addr = 0;
				end
			end
		end
		// Here we are just bringing the clear_acc to 0, so that next cycle onwards the row mac result will be passed through
		else if(state == STALL && delay_cntr == 10) begin  
			//Keep the delay counter running
			clr_cntr 		= 1;// Clear the delay counter because next cycle we start counting
			incr_delay_cntr = 0;
			dec_delay_cntr = 0;
			
			// Next state is RESET
			//Counter w
			clr1 		= 1;
			incr_w_addr = 0;
			//Counter x
			clr2		= 1;
			incr_x_addr	= 0;
			
			en_acc		= 0;
			clear_acc 	= 1; //all outputs are read so clear acc
			input_ready = 0;
			output_valid = 0;
			addr_w_p = addr_w;
			y = addr_w_p;

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
			if(input_valid ==1 && addr_w  == 63)
				next_state = LOAD_X;
		end
		else if (state == LOAD_X) begin	
			next_state = LOAD_X;
		if(input_valid == 1 && addr_x == 7 && (addr_w == 63 || addr_w == 0))
				next_state = STALL1;
		end
		else if (state == STALL1) begin 
			next_state = STALL1;
			if(addr_x == 0 && addr_w == 0)
				next_state = EXEC;
		end
		else if (state == EXEC) begin
			next_state = EXEC;
			if(addr_x == 7)
				next_state = STALL;
		end
		else if(state == STALL) begin
			next_state = STALL;
			if(delay_cntr == 10)
				next_state = RESET;
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
		else if(dec_delay_cntr == 1) begin		
			delay_cntr <= delay_cntr - 1;
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




