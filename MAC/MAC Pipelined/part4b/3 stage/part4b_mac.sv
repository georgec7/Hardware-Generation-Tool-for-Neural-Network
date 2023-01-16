//Author : George


module part4b_mac(clk, reset, a, b, valid_in, f, valid_out);
	input clk, reset, valid_in;
	input signed [13:0] a, b;
	output logic signed [27:0] f;
	output logic valid_out;
	logic signed [13:0] a_r, b_r;
    logic signed [27:0] f_wire, mult_ab, mult_ab_delay;
	logic enable_ab,  enable_f, clear_f;
	
	//Input register a , b and register between multiplier & adder
	always_ff @(posedge clk) begin
		if (reset == 1) begin
			a_r  <= 0;
           	b_r  <= 0;
			mult_ab_delay <= 0;
        end
        else begin
			mult_ab_delay <= mult_ab;
			if (enable_ab == 1) begin
				a_r  <= a;
				b_r  <= b;
			end
        end
    end
	
	// Output register f
	always_ff @(posedge clk) begin
		if (reset == 1) begin
			f	<= 0;
        end
        else if (clear_f == 1) begin
			f 	<=0;
		end
		else if (enable_f == 1) begin
			f 	<= f_wire;
        end
    end
		
// Instantiate 3 stage pipelined multiplier
DW02_mult_3_stage #(14, 14) multinstance(a_r, b_r, 1'b1, clk, mult_ab);

// Accumulate with satuaration functionality
	always_comb begin
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
control cntrl(.valid_in(valid_in), .clk(clk), .reset(reset), .enable_f(enable_f), .enable_ab(enable_ab), .valid_out(valid_out), .clear_f(clear_f));
endmodule

/* Control block control enable signals for input register (a and b) and output register(f).
   Control block controls the valid_out output signal indicating a valid output*/
module control(valid_in, clk, reset, enable_f, enable_ab, valid_out, clear_f);
	input valid_in, clk, reset;
	output logic enable_f, valid_out, enable_ab, clear_f;
	logic enable_R1, enable_mult2, enable_mult3;
 	logic reset_R1, reset_mult2, reset_mult3, reset_out;
	assign enable_ab = valid_in;
	
	// here valid_in and reset signals are delayed by four clock cycles
	always_ff @(posedge clk) begin
		enable_R1    <= valid_in;
		enable_mult2 <= enable_R1;
		enable_mult3 <= enable_mult2;
		enable_f     <= enable_mult3;		
		reset_mult2  <= reset;
		reset_mult3  <= reset_mult2;
		reset_R1     <= reset_mult3;
		reset_out    <= reset_R1;
	end
	/* here enable_f is delayed by one clock cycle. So in total valid_in is delayed
	by five clock cycles. This delayed signal is given to valid_out.  
	*/
	always_ff @(posedge clk) begin
		if (reset ==1 ) begin
			valid_out <= 0;
			clear_f   <= 1;
		end
		else if (reset_mult2 == 1) begin
			valid_out <= 0;
			clear_f   <= 1;
		end
		else if (reset_mult3 == 1) begin
			valid_out <= 0;
			clear_f   <= 1;
		end
		else if (reset_R1 == 1) begin
			valid_out <= 0;
			clear_f   <= 1;
		end
		else if (reset_out == 1) begin
			valid_out <= 0;
			clear_f   <= 0;
		end
		else begin
			valid_out <= enable_f;		
			clear_f   <= 0;
		end
	end
endmodule
 
