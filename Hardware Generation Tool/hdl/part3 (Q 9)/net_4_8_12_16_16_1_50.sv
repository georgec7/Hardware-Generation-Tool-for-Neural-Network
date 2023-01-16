`include "l1_fc_8_4_16_1_4.sv"
`include "l2_fc_12_8_16_1_12.sv"
`include "l3_fc_16_12_16_1_16.sv"
module net_4_8_12_16_16_1_50(clk, reset, input_valid, input_ready, input_data, output_valid, output_ready, output_data);
	input						clk, reset, input_valid, output_ready;
	input signed [16-1:0]input_data;
	output 		 				output_valid, input_ready;
	output signed [16-1:0]output_data;
	logic 						output_valid1, output_valid2, input_ready2,input_ready3;
	logic signed [16-1:0]output_data1, output_data2;
	l1_fc_8_4_16_1_4 layer1(clk, reset, input_valid, input_ready, input_data, output_valid1, input_ready2, output_data1);
	l2_fc_12_8_16_1_12 layer2(clk, reset, output_valid1, input_ready2, output_data1, output_valid2, input_ready3, output_data2);
	l3_fc_16_12_16_1_16 layer3(clk, reset, output_valid2, input_ready3, output_data2, output_valid, output_ready, output_data);
endmodule
