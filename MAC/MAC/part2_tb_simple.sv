//Author : George Madathil Saviour


module tb_part2_mac();

   logic clk, reset, valid_in, valid_out;
   logic signed [13:0] a, b;
   logic signed [27:0] f;
   logic signed [13:0] testData[399999:0];
   integer i;
   part2_mac dut(.clk(clk), .reset(reset), .a(a), .b(b), .valid_in(valid_in), .f(f), .valid_out(valid_out));

   initial clk = 0;
   always #5 clk = ~clk;

   initial $readmemh("inputData", testData);

   initial begin

      // Before first clock edge, initialize
      reset = 1;

      for (i=0; i<100000; i=i+1) begin
	  @(posedge clk);
	  #1; valid_in = testData[4*i];
	  a = testData[4*i+1][13:0];
	  b = testData[4*i+2][13:0];
          reset = testData[4*i+3];
      end
      @(posedge clk);
      #20;
      $finish;
   end // initial begin

      integer filehandle=$fopen("outValues");
      always @(posedge clk)
          $fdisplay(filehandle, "%x %x", f, valid_out);
     

endmodule 
