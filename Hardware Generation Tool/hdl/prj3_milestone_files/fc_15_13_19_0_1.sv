//Author: George
//Project 2


module fc_15_13_19_0_1(clk, reset, input_valid, input_ready, input_data, output_valid, output_ready, output_data);
	input 				 		clk, reset, input_valid, output_ready;
	input signed [19-1:0]  		input_data;
	output logic signed [19-1:0] 	output_data;
	output 		 				output_valid, input_ready;
	parameter                   SIZE_X= 13;
	parameter                   SIZE_W= 15*13;
	localparam          		LOGSIZE_x=$clog2(SIZE_X);
	localparam 					LOGSIZE_w=$clog2(SIZE_W);
	logic [LOGSIZE_x-1:0] 		addr_x;
	logic [LOGSIZE_w-1:0] 		addr_w;
	logic wr_en_x, wr_en_w, clear_acc, en_acc, output_valid_r;
	
	logic [19-1:0] mem_x_r, mem_w_r;
	

	
control_path #(LOGSIZE_x, LOGSIZE_w) cntrl(clk,reset,input_valid,output_ready,addr_x, wr_en_x, addr_w, wr_en_w, clear_acc, en_acc, input_ready, output_valid, output_valid_r);
data_path data(input_data, clk, reset, addr_x, wr_en_x, addr_w, wr_en_w, clear_acc, en_acc, output_valid_r, output_data, mem_x_r, mem_w_r);
	
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
module data_path(input_data, clk, reset, addr_x, wr_en_x, addr_w, wr_en_w, clear_acc, en_acc, output_valid_r, output_data,mem_x_r, mem_w_r);
	input signed [19-1:0] 		input_data;
	input 						clk, reset, wr_en_x,wr_en_w,clear_acc,en_acc,output_valid_r;
	output logic signed [19-1:0] 	output_data;
	parameter 					WIDTH= 19; 
	parameter                   SIZE_X= 13;
	parameter                   SIZE_W= 15*13;
	localparam          		LOGSIZE_x=$clog2(SIZE_X);
	localparam 					LOGSIZE_w=$clog2(SIZE_W);
	input [LOGSIZE_x-1:0] 		addr_x;
	input [LOGSIZE_w-1:0] 		addr_w;
	logic signed [2*19-1:0] 		mult;
	
	output logic signed [19-1:0] mem_x_r, mem_w_r;
    logic signed [19-1:0] f_wire, mult_x_r_w_r,mult_x_r_w_r_delay;
	
	// Instantiate memory x
	// Here WIDTH is the Width, SIZE_X is the size of the 2D memory array
	memory #(WIDTH,SIZE_X,LOGSIZE_x) mem_x(.clk(clk),.data_in(input_data),.data_out(mem_x_r),.addr(addr_x),.wr_en(wr_en_x));
	
	//Instantiate memory W
	fc_15_13_19_0_1_W_rom mem_w(.clk(clk),.addr(addr_w),.	z(mem_w_r));
	
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
			// Add_Relu_code_here
        end
    end
		
	// Multiply and accumulate with satuaration functionality
	always_comb begin
		mult = mem_x_r*mem_w_r;
		if(mult > 38'sd262143)
			mult_x_r_w_r = 19'sd262143;
		else if(mult < -38'sd262144)
			mult_x_r_w_r = -19'sd262144;
		else
			mult_x_r_w_r = mult;
	
		f_wire = output_data + mult_x_r_w_r_delay;
		if (~(output_data[19-1] ^ mult_x_r_w_r_delay[19-1]) & (output_data[19-1]^f_wire[19-1])) begin
			if(output_data[19-1] == 0)
				f_wire = 19'sd262143;
			else
				f_wire = -19'sd262144;
		end
		else begin
			f_wire = output_data + mult_x_r_w_r_delay;
		end
	end 
endmodule


module control_path(clk,reset,input_valid,output_ready,addr_x, wr_en_x, addr_w, wr_en_w, clear_acc, en_acc, input_ready, output_valid, output_valid_r);
	parameter LOGSIZE_x=3, LOGSIZE_w=9;
	input clk, reset, input_valid, output_ready;
	output logic wr_en_x, wr_en_w, clear_acc, en_acc, input_ready, output_valid;
	output logic [LOGSIZE_x-1:0] addr_x;
	output logic [LOGSIZE_w-1:0] addr_w;
	logic output_ready_r;
	logic clr_cntr, incr_delay_cntr, clr1, incr_w_addr, clr2, incr_x_addr;
	logic [2:0]delay_cntr;
	parameter [2:0] RESET = 3'b000, LOAD_W = 3'b001, LOAD_X = 3'b010, EXEC = 3'b011, STALL1 = 3'b100,STALL = 3'b101,WAIT = 3'b110;
	logic [2:0] state, next_state; 
	output logic output_valid_r;
	//enum {RESET,LOAD_W,LOAD_X,EXEC,STALL1,STALL} state, next_state; 
	// Output logic
    always_comb begin
		clr_cntr 		= 0;
		incr_delay_cntr = 0;
		clr1 		 	= 0;
		clr2		 	= 0;
        incr_w_addr  	= 0;
		incr_x_addr	 	= 0;
		wr_en_w		 	= 0;
		wr_en_x		 	= 0;
		en_acc		 	= 0;
		clear_acc 	 	= 0;
		input_ready  	= 0;
		output_valid 	= 0;
		output_valid_r  = 0;
		
		if (state == RESET) begin // These signals will be sampled on the second clock cycle after reset 	
			if (input_valid == 1)begin
				incr_x_addr = 1;
				wr_en_x		= 1;
			end
			input_ready = 1;
			clear_acc 	= 1;	
		end
		// For making wr_en_w to 0 so that w memory's 8th index is not over written to
		else if (state == LOAD_X && addr_x == 0)begin 
			if (input_valid == 1) begin
				incr_x_addr = 1;
				wr_en_x		= 1;
			end
			input_ready = 1;
			clear_acc 	= 1;
		end
		// For making wr_en_w to 0 so that w memory's 8th index is not over written to
		else if (state == LOAD_X && ~(addr_x == 13-1))begin 
			if (input_valid == 1) begin
				incr_x_addr = 1;
				wr_en_x		= 1;
			end
			input_ready = 1;
			clear_acc 	= 1;
		end																
		// Here when addr_x == 2 && addr_w == 8 means we gave loaded both x and w
		// Here when addr_x == 2 && addr_w == 0 means only x is loaded, and addr_w reused.
		else if (state == LOAD_X && addr_x == 13-1) begin // Next cycle move to STALL state.
			if (input_valid == 1) begin
				clr1 		= 1;
				clr2		= 1;
				wr_en_x		= 1;//Wait for next cycle to make it 0 because memory block takes this in next cycle
			end
			input_ready = 1;
			clear_acc 	= 1;
		end
		// This STALL state is for waiting a state so that memory X's previous value(2nd index locations write) of x is not used for execution
		else if(state == STALL1 && addr_x == 0) begin
			incr_w_addr = 1;
			incr_x_addr	= 1;
			clear_acc 	= 1;
		end
		else if(state == EXEC && addr_w == 0 && addr_x == 0) begin // Only first cycle after entering the execution mode 
			incr_w_addr = 1;
			incr_x_addr	= 1;
			en_acc		= 1;// Next cycle will have mac result of 0th index of w and 2nd index of x. We need to wait for index 0 of w and x, to enable the acc
			// will have mac result of 8th index of w and 2nd index of x. So only in next cycle make this 1.			
		end
		else if(state == EXEC && ~(addr_x == 13-1)) begin
			incr_w_addr = 1;
			incr_x_addr	= 1;
			en_acc		= 1;
		end
		else if(state == EXEC && addr_x == 13-1) begin
			incr_delay_cntr = 1;
			if(addr_w == 15*13-1)begin
				incr_w_addr = 0; // Stop counting when addr_w = 8 and addr_x == 2, this means that after delay =3 , we move to reset state
			end
			else begin
				incr_w_addr = 1;
			end
			//Counter x
			clr2		= 1;// Perform clr in the next cycle
			if(addr_w == 15*13-1)begin
				incr_x_addr = 0;
			end
			else begin
				incr_x_addr = 1;
			end
			en_acc		= 1;
		end
		else if(state == STALL && delay_cntr == 1) begin
			//Keep the delay counter running
			incr_delay_cntr = 1;
			en_acc		= 1;
		end
		else if(state == STALL && delay_cntr == 2) begin
			//Keep the delay counter running
			incr_delay_cntr = 1;
			en_acc		= 1;
		end
		// Keep executing this until output is read by the dest port
		else if(state == STALL && delay_cntr == 3) begin //Change this two for pipelining
			//stop the delay counter in the next clock cycle, but don't clear the value of 2, because we will be stuck in this loop till we get out_put ready			
			//Keep stalling the counter till the row MAC result is read by the output stream
			//Counter w
			output_valid = 0;
			output_valid_r = 1;
			incr_delay_cntr = 1;
		end
		else if(state == STALL && delay_cntr == 4) begin //Change this two for pipelining
			//stop the delay counter in the next clock cycle, but don't clear the value of 2, because we will be stuck in this loop till we get out_put ready			
			//Keep stalling the counter till the row MAC result is read by the output stream
			//Counter w
			output_valid = 1;
			//output_valid_r = 1;
			incr_delay_cntr = 1;
		end
		
		// Keep executing this until output is read by the dest port
		else if(state == STALL && delay_cntr == 5) begin //Change this two for pipelining
			//stop the delay counter in the next clock cycle, but don't clear the value of 2, because we will be stuck in this loop till we get out_put ready
			//Keep stalling the counter till the row MAC result is read by the output stream
			//Counter w
			if( output_ready_r == 1) begin
				incr_delay_cntr = 1;// Increment the delay counter one last time
				clear_acc 	= 1; //Clear the acc value in the next cycle since we are starting the acc for the next row in next to next cycle
				output_valid = 0;
				if(addr_w == (15*13) -1)begin
					incr_w_addr = 0; // Stop counting when addr_w = 8 and addr_x == 2, this means that after delay =3 , we move to reset state
					incr_x_addr = 0;
				end
				else begin
					//incr_w_addr = 1;
					//incr_x_addr = 1;
				end
			end 
			else begin
				output_valid = 1;				
			end
		end
		// Here we are just bringing the clear_acc to 0, so that next cycle onwards the row mac result will be passed through
		else if(state == STALL && delay_cntr == 6) begin  
			//Keep the delay counter running
			clr_cntr 		= 1;// Clear the delay counter because next cycle we start counting		
			// Next state is RESET
			if(addr_w == (15*13)-1) begin
				//Now stall the counter till the row MAC result is read by the output stream
				//Counter w
				clr1 		= 1;
				//Counter x
				clr2		= 1;
			end
			// Next state is EXEC
			else begin
				//Counter w
				incr_w_addr = 1;
				incr_x_addr	= 1;
				//en_acc		= 1;
				clear_acc = 1;
			end
		end
	end

	// FSM next state logic
	always_comb begin
		next_state = WAIT;
        if (state == RESET )begin
			next_state = RESET;
			if(input_valid == 1)
				next_state = LOAD_X;
		end
		/*else if (state == LOAD_W)begin
			next_state = LOAD_W;
			if(input_valid ==1 && addr_w == 63)
				next_state = LOAD_X;
		end*/
		else if (state == LOAD_X) begin	
			next_state = LOAD_X;
			if(input_valid == 1 && addr_x == 13-1)
				next_state = STALL1;
		end
		else if (state == STALL1)begin
			next_state = STALL1;
			if(addr_x == 0 && addr_w == 0)
				next_state = EXEC;
		end
		else if (state == EXEC)begin
			next_state = EXEC;
			if(addr_x == 13-1)
				next_state = STALL;
		end
		else if(state == STALL) begin
			next_state = STALL;
			if(delay_cntr == 6) begin
				if(addr_w == (15*13)-1)
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


 















module fc_15_13_19_0_1_W_rom(clk, addr, z);
   input clk;
   input [7:0] addr;
   output logic signed [18:0] z;
   always_ff @(posedge clk) begin
      case(addr)
        0: z <= -19'd144;
        1: z <= 19'd144;
        2: z <= 19'd157;
        3: z <= -19'd103;
        4: z <= -19'd64;
        5: z <= 19'd10;
        6: z <= -19'd54;
        7: z <= 19'd87;
        8: z <= -19'd256;
        9: z <= -19'd200;
        10: z <= -19'd67;
        11: z <= 19'd206;
        12: z <= -19'd240;
        13: z <= -19'd71;
        14: z <= 19'd33;
        15: z <= 19'd132;
        16: z <= 19'd141;
        17: z <= -19'd128;
        18: z <= -19'd242;
        19: z <= 19'd55;
        20: z <= 19'd100;
        21: z <= 19'd22;
        22: z <= -19'd35;
        23: z <= 19'd203;
        24: z <= -19'd212;
        25: z <= -19'd175;
        26: z <= 19'd8;
        27: z <= 19'd53;
        28: z <= 19'd47;
        29: z <= 19'd198;
        30: z <= 19'd46;
        31: z <= 19'd159;
        32: z <= 19'd87;
        33: z <= -19'd53;
        34: z <= -19'd200;
        35: z <= -19'd233;
        36: z <= 19'd213;
        37: z <= 19'd3;
        38: z <= 19'd110;
        39: z <= 19'd214;
        40: z <= 19'd59;
        41: z <= -19'd212;
        42: z <= 19'd164;
        43: z <= 19'd76;
        44: z <= -19'd27;
        45: z <= -19'd59;
        46: z <= -19'd48;
        47: z <= -19'd141;
        48: z <= 19'd70;
        49: z <= -19'd34;
        50: z <= 19'd170;
        51: z <= -19'd86;
        52: z <= 19'd245;
        53: z <= -19'd121;
        54: z <= -19'd139;
        55: z <= -19'd223;
        56: z <= -19'd39;
        57: z <= 19'd125;
        58: z <= 19'd86;
        59: z <= -19'd248;
        60: z <= 19'd67;
        61: z <= -19'd124;
        62: z <= 19'd167;
        63: z <= -19'd102;
        64: z <= 19'd79;
        65: z <= 19'd223;
        66: z <= -19'd79;
        67: z <= 19'd37;
        68: z <= -19'd30;
        69: z <= -19'd224;
        70: z <= -19'd5;
        71: z <= -19'd226;
        72: z <= -19'd180;
        73: z <= -19'd97;
        74: z <= 19'd106;
        75: z <= 19'd49;
        76: z <= 19'd101;
        77: z <= -19'd198;
        78: z <= 19'd164;
        79: z <= -19'd85;
        80: z <= 19'd25;
        81: z <= 19'd79;
        82: z <= 19'd85;
        83: z <= 19'd14;
        84: z <= 19'd214;
        85: z <= 19'd202;
        86: z <= 19'd47;
        87: z <= -19'd81;
        88: z <= 19'd71;
        89: z <= -19'd123;
        90: z <= -19'd73;
        91: z <= -19'd118;
        92: z <= 19'd9;
        93: z <= -19'd162;
        94: z <= 19'd37;
        95: z <= -19'd168;
        96: z <= -19'd194;
        97: z <= 19'd214;
        98: z <= 19'd125;
        99: z <= 19'd32;
        100: z <= 19'd246;
        101: z <= -19'd136;
        102: z <= 19'd62;
        103: z <= -19'd190;
        104: z <= 19'd24;
        105: z <= -19'd88;
        106: z <= 19'd116;
        107: z <= -19'd131;
        108: z <= -19'd29;
        109: z <= 19'd24;
        110: z <= 19'd40;
        111: z <= 19'd252;
        112: z <= -19'd153;
        113: z <= -19'd131;
        114: z <= 19'd10;
        115: z <= -19'd194;
        116: z <= -19'd185;
        117: z <= -19'd199;
        118: z <= -19'd19;
        119: z <= 19'd142;
        120: z <= -19'd66;
        121: z <= 19'd165;
        122: z <= -19'd232;
        123: z <= 19'd199;
        124: z <= -19'd253;
        125: z <= 19'd61;
        126: z <= -19'd225;
        127: z <= -19'd191;
        128: z <= 19'd20;
        129: z <= 19'd157;
        130: z <= 19'd98;
        131: z <= 19'd10;
        132: z <= -19'd235;
        133: z <= -19'd96;
        134: z <= 19'd77;
        135: z <= 19'd45;
        136: z <= 19'd73;
        137: z <= -19'd63;
        138: z <= 19'd170;
        139: z <= -19'd212;
        140: z <= 19'd217;
        141: z <= -19'd46;
        142: z <= -19'd216;
        143: z <= -19'd191;
        144: z <= 19'd79;
        145: z <= 19'd50;
        146: z <= -19'd129;
        147: z <= 19'd150;
        148: z <= 19'd107;
        149: z <= 19'd108;
        150: z <= 19'd36;
        151: z <= -19'd215;
        152: z <= 19'd17;
        153: z <= 19'd61;
        154: z <= 19'd240;
        155: z <= 19'd21;
        156: z <= -19'd134;
        157: z <= -19'd241;
        158: z <= 19'd86;
        159: z <= 19'd142;
        160: z <= 19'd172;
        161: z <= -19'd72;
        162: z <= -19'd103;
        163: z <= 19'd194;
        164: z <= 19'd89;
        165: z <= 19'd230;
        166: z <= -19'd17;
        167: z <= -19'd94;
        168: z <= -19'd89;
        169: z <= -19'd102;
        170: z <= -19'd50;
        171: z <= -19'd128;
        172: z <= 19'd108;
        173: z <= -19'd10;
        174: z <= -19'd63;
        175: z <= -19'd68;
        176: z <= -19'd216;
        177: z <= 19'd64;
        178: z <= -19'd174;
        179: z <= 19'd147;
        180: z <= -19'd83;
        181: z <= 19'd119;
        182: z <= -19'd39492;
        183: z <= 19'd250302;
        184: z <= 19'd33972;
        185: z <= 19'd104876;
        186: z <= -19'd217389;
        187: z <= -19'd207570;
        188: z <= 19'd180667;
        189: z <= -19'd229334;
        190: z <= 19'd113341;
        191: z <= 19'd39272;
        192: z <= -19'd143646;
        193: z <= -19'd171690;
        194: z <= 19'd167210;
      endcase
   end
endmodule

