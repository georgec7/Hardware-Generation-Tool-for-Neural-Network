part4 has parallel memories, pipelining between multiplier and adder, and pipelined multiplier using Designware component.


For simulation,
In part3_random_tb.sv matvec8_part3 is changed to matvec8_part4

$ vlog /home/home4/pmilder/ese507/synthesis/sim_ver/DW02_mult*.v
$ vlog part3_random_tb.sv matvec8_part4.sv
$ vsim -sv_seed 5 tbench3 -c -do "run -all"

For synthesis,
Fastest clk is 0.85ns

$ dc_shell -f runsynth.tcl | tee output.txt_0.85