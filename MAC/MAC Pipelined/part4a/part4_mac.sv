//Author : George

module part4_mac(clk, reset, a, b, valid_in, f, valid_out);
	input clk, reset, valid_in;
	input signed [13:0] a, b;
	output logic signed [27:0] f;
	output logic valid_out;
	logic signed [13:0] a_r, b_r;
    logic signed [27:0] f_wire, mult_ab, mult_ab_delay;
	logic enable_ab, enable_R1, enable_f;
	
	// Input Register a and b
	always_ff @(posedge clk) begin
		if (reset == 1) begin
			a_r  <= 0;
			b_r  <= 0;
		end
		else begin
			if (enable_ab == 1) begin
           		a_r  <= a;
            	b_r <= b;
			end
		end
	end
	
	// Output Register f
	always_ff @(posedge clk) begin
		mult_ab_delay <= mult_ab;
        if (reset == 1) begin
			mult_ab_delay <= 0;
			f <= 0;
		end
		else begin
			if (enable_f == 1) begin
				f <= f_wire;
			end
		end
	end
	
	// Multiply and accumulate with satuaration functionality
	always_comb begin
		mult_ab = a_r*b_r;
		f_wire = f + mult_ab_delay;
		if (~(f[27] ^ mult_ab_delay[27]) & (f[27]^f_wire[27])) begin
			if(f[27] == 0)
				f_wire = 134217727;
			else
				f_wire = -134217728;
		end
		else begin
			f_wire = f + mult_ab_delay;
		end
		
	end 
control cntrl(.valid_in(valid_in), .clk(clk), .reset(reset), .enable_f(enable_f), .enable_ab(enable_ab), .valid_out(valid_out), .enable_R1(enable_R1));
endmodule

/* Control block control enable signals for input register (a and b) and output register(f).
   Control block controls the valid_out output signal indicating a valid output*/
module control(valid_in, clk, reset, enable_f, enable_ab, valid_out, enable_R1);
	input valid_in, clk, reset;
	output logic enable_f, valid_out, enable_ab, enable_R1;
 	logic reset_R1, reset_f;
	assign enable_ab = valid_in;
	
	// here valid_in and reset signals are delayed by two clock cycles
	always_ff @(posedge clk) begin
		enable_R1 <= valid_in;
		enable_f <= enable_R1;		
		reset_R1 <= reset;
		reset_f <= reset_R1;
	end
	/* here enable_f is delayed by one clock cycle. So in total valid_in is delayed
	by three clock cycles. This delayed signal is given to valid_out*/
	always_ff @(posedge clk) begin
		if (reset ==1) begin
			valid_out <= 0;
		end
		else if (reset_R1 == 1) begin
			valid_out <= 0;
		end
		else if (reset_f == 1) begin
			valid_out <= 0;
		end
		else begin
			valid_out <= enable_f;		
		end
	end
endmodule
 
