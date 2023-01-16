//Author: George
//Project 2


module fc_13_16_32_1_1(clk, reset, input_valid, input_ready, input_data, output_valid, output_ready, output_data);
	input 				 		clk, reset, input_valid, output_ready;
	input signed [32-1:0]  		input_data;
	output logic signed [32-1:0] 	output_data;
	output 		 				output_valid, input_ready;
	parameter                   SIZE_X= 16;
	parameter                   SIZE_W= 13*16;
	localparam          		LOGSIZE_x=$clog2(SIZE_X);
	localparam 					LOGSIZE_w=$clog2(SIZE_W);
	logic [LOGSIZE_x-1:0] 		addr_x;
	logic [LOGSIZE_w-1:0] 		addr_w;
	logic wr_en_x, wr_en_w, clear_acc, en_acc, output_valid_r;
	
	logic [32-1:0] mem_x_r, mem_w_r;
	

	
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
	input signed [32-1:0] 		input_data;
	input 						clk, reset, wr_en_x,wr_en_w,clear_acc,en_acc,output_valid_r;
	output logic signed [32-1:0] 	output_data;
	parameter 					WIDTH= 32; 
	parameter                   SIZE_X= 16;
	parameter                   SIZE_W= 13*16;
	localparam          		LOGSIZE_x=$clog2(SIZE_X);
	localparam 					LOGSIZE_w=$clog2(SIZE_W);
	input [LOGSIZE_x-1:0] 		addr_x;
	input [LOGSIZE_w-1:0] 		addr_w;
	logic signed [2*32-1:0] 		mult;
	
	output logic signed [32-1:0] mem_x_r, mem_w_r;
    logic signed [32-1:0] f_wire, mult_x_r_w_r,mult_x_r_w_r_delay;
	
	// Instantiate memory x
	// Here WIDTH is the Width, SIZE_X is the size of the 2D memory array
	memory #(WIDTH,SIZE_X,LOGSIZE_x) mem_x(.clk(clk),.data_in(input_data),.data_out(mem_x_r),.addr(addr_x),.wr_en(wr_en_x));
	
	//Instantiate memory W
	fc_13_16_32_1_1_W_rom mem_w(.clk(clk),.addr(addr_w),.	z(mem_w_r));
	
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
			if(output_valid_r == 1) begin 
 if(output_data <= 0) 
  output_data <= 0; 
end
        end
    end
		
	// Multiply and accumulate with satuaration functionality
	always_comb begin
		mult = mem_x_r*mem_w_r;
		if(mult > 64'sd2147483647)
			mult_x_r_w_r = 32'sd2147483647;
		else if(mult < -64'sd2147483648)
			mult_x_r_w_r = -32'sd2147483648;
		else
			mult_x_r_w_r = mult;
	
		f_wire = output_data + mult_x_r_w_r_delay;
		if (~(output_data[32-1] ^ mult_x_r_w_r_delay[32-1]) & (output_data[32-1]^f_wire[32-1])) begin
			if(output_data[32-1] == 0)
				f_wire = 32'sd2147483647;
			else
				f_wire = -32'sd2147483648;
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
		else if (state == LOAD_X && ~(addr_x == 16-1))begin 
			if (input_valid == 1) begin
				incr_x_addr = 1;
				wr_en_x		= 1;
			end
			input_ready = 1;
			clear_acc 	= 1;
		end																
		// Here when addr_x == 2 && addr_w == 8 means we gave loaded both x and w
		// Here when addr_x == 2 && addr_w == 0 means only x is loaded, and addr_w reused.
		else if (state == LOAD_X && addr_x == 16-1) begin // Next cycle move to STALL state.
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
		else if(state == EXEC && ~(addr_x == 16-1)) begin
			incr_w_addr = 1;
			incr_x_addr	= 1;
			en_acc		= 1;
		end
		else if(state == EXEC && addr_x == 16-1) begin
			incr_delay_cntr = 1;
			if(addr_w == 13*16-1)begin
				incr_w_addr = 0; // Stop counting when addr_w = 8 and addr_x == 2, this means that after delay =3 , we move to reset state
			end
			else begin
				incr_w_addr = 1;
			end
			//Counter x
			clr2		= 1;// Perform clr in the next cycle
			if(addr_w == 13*16-1)begin
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
				if(addr_w == (13*16) -1)begin
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
			if(addr_w == (13*16)-1) begin
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
			if(input_valid == 1 && addr_x == 16-1)
				next_state = STALL1;
		end
		else if (state == STALL1)begin
			next_state = STALL1;
			if(addr_x == 0 && addr_w == 0)
				next_state = EXEC;
		end
		else if (state == EXEC)begin
			next_state = EXEC;
			if(addr_x == 16-1)
				next_state = STALL;
		end
		else if(state == STALL) begin
			next_state = STALL;
			if(delay_cntr == 6) begin
				if(addr_w == (13*16)-1)
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


 

















module fc_13_16_32_1_1_W_rom(clk, addr, z);
   input clk;
   input [7:0] addr;
   output logic signed [31:0] z;
   always_ff @(posedge clk) begin
      case(addr)
        0: z <= 32'd16269;
        1: z <= 32'd19569;
        2: z <= -32'd28351;
        3: z <= 32'd28672;
        4: z <= 32'd22501;
        5: z <= 32'd27043;
        6: z <= 32'd5440;
        7: z <= -32'd23866;
        8: z <= -32'd21143;
        9: z <= 32'd11606;
        10: z <= -32'd19991;
        11: z <= -32'd24843;
        12: z <= -32'd12265;
        13: z <= -32'd29491;
        14: z <= 32'd31781;
        15: z <= -32'd1988;
        16: z <= 32'd18837;
        17: z <= -32'd1057;
        18: z <= -32'd19920;
        19: z <= -32'd12262;
        20: z <= -32'd15585;
        21: z <= 32'd9467;
        22: z <= -32'd29713;
        23: z <= -32'd16724;
        24: z <= 32'd15092;
        25: z <= 32'd30117;
        26: z <= 32'd19875;
        27: z <= 32'd16893;
        28: z <= -32'd32489;
        29: z <= -32'd31889;
        30: z <= 32'd11577;
        31: z <= 32'd16548;
        32: z <= 32'd20448;
        33: z <= 32'd15995;
        34: z <= 32'd12452;
        35: z <= 32'd10182;
        36: z <= 32'd10270;
        37: z <= -32'd14876;
        38: z <= 32'd19084;
        39: z <= 32'd21895;
        40: z <= 32'd29499;
        41: z <= 32'd31861;
        42: z <= 32'd29820;
        43: z <= -32'd15534;
        44: z <= -32'd30397;
        45: z <= 32'd28833;
        46: z <= 32'd15246;
        47: z <= 32'd21208;
        48: z <= -32'd4992;
        49: z <= 32'd28095;
        50: z <= -32'd23822;
        51: z <= 32'd12192;
        52: z <= 32'd4794;
        53: z <= -32'd20767;
        54: z <= 32'd28236;
        55: z <= -32'd12882;
        56: z <= -32'd23418;
        57: z <= 32'd15344;
        58: z <= -32'd28757;
        59: z <= -32'd23138;
        60: z <= 32'd16223;
        61: z <= 32'd15589;
        62: z <= 32'd26178;
        63: z <= 32'd3903;
        64: z <= -32'd1184;
        65: z <= 32'd5863;
        66: z <= -32'd18683;
        67: z <= -32'd23682;
        68: z <= 32'd23755;
        69: z <= -32'd32367;
        70: z <= 32'd30981;
        71: z <= 32'd20486;
        72: z <= 32'd32263;
        73: z <= 32'd28033;
        74: z <= -32'd27816;
        75: z <= -32'd30902;
        76: z <= 32'd24099;
        77: z <= 32'd20199;
        78: z <= 32'd23074;
        79: z <= -32'd13661;
        80: z <= 32'd15526;
        81: z <= 32'd32020;
        82: z <= 32'd31299;
        83: z <= -32'd12448;
        84: z <= -32'd21515;
        85: z <= 32'd26768;
        86: z <= 32'd7438;
        87: z <= -32'd12165;
        88: z <= 32'd9344;
        89: z <= 32'd11449;
        90: z <= -32'd2535;
        91: z <= -32'd7201;
        92: z <= -32'd5730;
        93: z <= -32'd9124;
        94: z <= 32'd29470;
        95: z <= 32'd25854;
        96: z <= 32'd29507;
        97: z <= -32'd21980;
        98: z <= -32'd30596;
        99: z <= 32'd20494;
        100: z <= -32'd21579;
        101: z <= -32'd32383;
        102: z <= 32'd8213;
        103: z <= -32'd22084;
        104: z <= 32'd28419;
        105: z <= 32'd13165;
        106: z <= -32'd20218;
        107: z <= 32'd19750;
        108: z <= 32'd596;
        109: z <= -32'd29912;
        110: z <= -32'd26679;
        111: z <= -32'd16646;
        112: z <= -32'd30660;
        113: z <= -32'd28147;
        114: z <= 32'd3674;
        115: z <= -32'd19407;
        116: z <= 32'd31389;
        117: z <= -32'd21656;
        118: z <= 32'd1197;
        119: z <= 32'd7965;
        120: z <= 32'd22562;
        121: z <= 32'd31430;
        122: z <= -32'd32004;
        123: z <= -32'd15936;
        124: z <= -32'd10462;
        125: z <= 32'd30234;
        126: z <= -32'd22849;
        127: z <= -32'd13723;
        128: z <= -32'd24514;
        129: z <= -32'd20677;
        130: z <= -32'd25996;
        131: z <= -32'd13324;
        132: z <= -32'd20291;
        133: z <= 32'd14985;
        134: z <= -32'd2640;
        135: z <= -32'd24640;
        136: z <= -32'd4618;
        137: z <= 32'd9911;
        138: z <= 32'd27878;
        139: z <= 32'd28747;
        140: z <= 32'd12767;
        141: z <= -32'd31569;
        142: z <= -32'd20667;
        143: z <= 32'd14876;
        144: z <= -32'd26948;
        145: z <= 32'd15776;
        146: z <= 32'd28237;
        147: z <= -32'd28327;
        148: z <= 32'd26888;
        149: z <= -32'd3334;
        150: z <= 32'd12406;
        151: z <= 32'd16682;
        152: z <= -32'd4671;
        153: z <= 32'd13170;
        154: z <= -32'd32021;
        155: z <= 32'd17635;
        156: z <= 32'd10637;
        157: z <= -32'd22102;
        158: z <= -32'd28855;
        159: z <= 32'd18891;
        160: z <= -32'd10011;
        161: z <= -32'd22083;
        162: z <= -32'd27201;
        163: z <= 32'd2466;
        164: z <= 32'd25670;
        165: z <= 32'd2928;
        166: z <= 32'd10594;
        167: z <= -32'd11716;
        168: z <= -32'd19929;
        169: z <= 32'd5704;
        170: z <= -32'd15737;
        171: z <= 32'd25606;
        172: z <= 32'd6904;
        173: z <= -32'd3635;
        174: z <= 32'd7714;
        175: z <= 32'd12724;
        176: z <= -32'd20627;
        177: z <= 32'd3184;
        178: z <= 32'd17166;
        179: z <= -32'd26507;
        180: z <= 32'd32618;
        181: z <= -32'd3196;
        182: z <= 32'd22944;
        183: z <= -32'd4821;
        184: z <= -32'd22793;
        185: z <= 32'd23691;
        186: z <= -32'd19953;
        187: z <= 32'd20612;
        188: z <= -32'd31179;
        189: z <= -32'd16040;
        190: z <= 32'd6735;
        191: z <= -32'd8422;
        192: z <= -32'd716412139;
        193: z <= 32'd97169423;
        194: z <= 32'd180086973;
        195: z <= 32'd146820955;
        196: z <= 32'd756169599;
        197: z <= 32'd891982367;
        198: z <= -32'd664231529;
        199: z <= 32'd825453990;
        200: z <= 32'd377956456;
        201: z <= -32'd856759265;
        202: z <= -32'd254455380;
        203: z <= -32'd467614880;
        204: z <= -32'd285190676;
        205: z <= -32'd16715825;
        206: z <= -32'd387549932;
        207: z <= -32'd486832807;
      endcase
   end
endmodule

