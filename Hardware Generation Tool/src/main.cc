// ESE 507 Project 3 Handout Code
// You may not redistribute this code

// Getting started:
// The main() function contains the code to read the parameters. 
// For Parts 1 and 2, your code should be in the genFCLayer() function. Please
// also look at this function to see an example for how to create the ROMs.
//
// For Part 3, your code should be in the genNetwork() function.



#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <cstdlib>
#include <cstring>
#include <assert.h>
#include <math.h>
#include <bits/stdc++.h>
#include <algorithm>
#include <initializer_list>

using namespace std;
// Function prototypes
void printUsage();
void genFCLayer(int M, int N, int T, int R, int P, vector<int>& constVector, string modName, fstream &os,string out_file,bool  gen_cc);
void genNetwork(int N, int M1, int M2, int M3, int T, int R, int B, vector<int>& constVector, string modName, fstream &os,string out_file);
void readConstants(ifstream &constStream, vector<int>& constvector);
void genROM(vector<int>& constVector, int bits, string modName, fstream &os,int P,int N,int M);
void findAndreplaceAll(string oldw[], string neww[],fstream &fout, string out_file,int size,bool first);
void possible_P(int * arr,int limit);
float layer_delay(float P,float N,float M);

struct best_comb{
		int P1;
		int P2;
		int P3;
		int budget_used;
	};

int main(int argc, char* argv[]) 
{

   // If the user runs the program without enough parameters, print a helpful message
   // and quit.
   if (argc < 7) {
      printUsage();
      return 1;
   }

   int mode = atoi(argv[1]);

   ifstream const_file;
   fstream os;
   vector<int> constVector;

   //----------------------------------------------------------------------
   // Look here for Part 1 and 2
   if (((mode == 1) && (argc == 7)) || ((mode == 2) && (argc == 8))) {

      // Mode 1/2: Generate one layer with given dimensions and one testbench

      // --------------- read parameters, etc. ---------------
      int M = atoi(argv[2]);
      int N = atoi(argv[3]);
      int T = atoi(argv[4]);
      int R = atoi(argv[5]);

      int P;

      // If mode == 1, then set P to 1. If mode==2, set P to the value
      // given at the command line.
      if (mode == 1) {
         P=1;
         const_file.open(argv[6]);         
      }
      else {
         P = atoi(argv[6]);
         const_file.open(argv[7]);
      }

      if (const_file.is_open() != true) {
         cout << "ERROR reading constant file " << argv[6] << endl;
         return 1;
      }

      // Read the constants out of the provided file and place them in the constVector vector
      readConstants(const_file, constVector);

      string out_file = "fc_" + to_string(M) + "_" + to_string(N) + "_" + to_string(T) + "_" + to_string(R) + "_" + to_string(P) + ".sv";

      os.open(out_file,fstream::out);
      if (os.is_open() != true) {
         cout << "ERROR opening " << out_file << " for write." << endl;
         return 1;
      }
      // -------------------------------------------------------------

      // call the genFCLayer function you will write to generate this layer
      string modName = "fc_" + to_string(M) + "_" + to_string(N) + "_" + to_string(T) + "_" + to_string(R) + "_" + to_string(P);
      genFCLayer(M, N, T, R, P, constVector, modName, os,out_file,true); 

   }
   //--------------------------------------------------------------------


   // ----------------------------------------------------------------
   // Look here for Part 3
   else if ((mode == 3) && (argc == 10)) {
      // Mode 3: Generate three layers interconnected

      // --------------- read parameters, etc. ---------------
      int N  = atoi(argv[2]);
      int M1 = atoi(argv[3]);
      int M2 = atoi(argv[4]);
      int M3 = atoi(argv[5]);
      int T  = atoi(argv[6]);
      int R  = atoi(argv[7]);
      int B  = atoi(argv[8]);

      const_file.open(argv[9]);
      if (const_file.is_open() != true) {
         cout << "ERROR reading constant file " << argv[8] << endl;
         return 1;
      }
      readConstants(const_file, constVector);

      string out_file = "net_" + to_string(N) + "_" + to_string(M1) + "_" + to_string(M2) + "_" + to_string(M3) + "_" + to_string(T) + "_" + to_string(R) + "_" + to_string(B)+ ".sv";


      os.open(out_file,fstream::out);
      if (os.is_open() != true) {
         cout << "ERROR opening " << out_file << " for write." << endl;
         return 1;
      }
      // -------------------------------------------------------------

      string mod_name = "net_" + to_string(N) + "_" + to_string(M1) + "_" + to_string(M2) + "_" + to_string(M3) + "_" + to_string(T) + "_" + to_string(R) + "_" + to_string(B);

      // generate the design
      genNetwork(N, M1, M2, M3, T, R, B, constVector, mod_name, os,out_file);

   }
   //-------------------------------------------------------

   else {
      printUsage();
      return 1;
   }

   // close the output stream
   os.close();

}

// Read values from the constant file into the vector
void readConstants(ifstream &constStream, vector<int>& constvector) {
   string constLineString;
   while(getline(constStream, constLineString)) {
      int val = atoi(constLineString.c_str());
      constvector.push_back(val);
   }
}

// Generate a ROM based on values constVector.
// Values should each be "bits" number of bits.
void genROM(vector<int>& constVector, int bits, string modName, fstream &os,int P,int N,int M) {

		int numWords = constVector.size()/P;
		int addrBits = ceil(log2(numWords));
		string modName_temp;
		cout<< "numWOrds "<<numWords<<endl;
		for(int a = 0; a< P; a++)
		{
			modName_temp = modName +"_"+ to_string(a);
			string z = "z_" + to_string(a);
			os << "module " << modName_temp << "(clk, addr, "<<z<<");" << endl; // ModName_1 + ModName_2...strind extension
			os << "   input clk;" << endl;
			os << "   input [" << addrBits-1 << ":0] addr;" << endl;
			os << "   output logic signed [" << bits-1 << ":0] "<<z<<";" << endl;
			os << "   always_ff @(posedge clk) begin" << endl;
			os << "      case(addr)" << endl;
			int i=0;
			int step = 0;
			vector<int>::iterator begin,end;
			 
			if(P == 1)
			{
				begin = constVector.begin();
				end = begin + constVector.size() -1;
				for (vector<int>::iterator it = begin; it <=end; it++, i++){
				if (*it < 0)
					os << "        " << i << ": "<<z <<"<= -" << bits << "'d" << abs(*it) << ";" << endl;// z_1 + z_2..string extension
				else
					os << "        " << i << ": "<<z <<"<= "  << bits << "'d" << *it      << ";" << endl;// z_1 + z_2..string extension

				}
			}
			else
			{
				int lim =0;
				if(P == M)
				{
					lim = 1;
				}
				else
				{
					lim = M/P;
				}
				step = a*N;
				for(int b = 1; b<= lim; b++,step = step + P*N)
				{	
					begin = constVector.begin()+ step;
					//if(P == 4)
						//end = begin + numWords*P -1;
					//else
					end = begin + N -1;
					for (vector<int>::iterator it = begin; it <=end; it++, i++){
					if (*it < 0)
						os << "        " << i << ": "<<z <<"<= -" << bits << "'d" << abs(*it) << ";" << endl;// z_1 + z_2..string extension
					else
						os << "        " << i << ": "<<z <<"<= "  << bits << "'d" << *it      << ";" << endl;// z_1 + z_2..string extension

					}
				}
			}
			os << "      endcase" << endl << "   end" << endl << "endmodule" << endl << endl;
		}
}

// Parts 1 and 2
// Here is where you add your code to produce a neural network layer.
void genFCLayer(int M, int N, int T, int R, int P, vector<int>& constVector, string modName, fstream &os,string out_file,bool  gen_cc) {				 
    string romModName = modName + "_W_rom";
    string modName_temp;
	string ROMcode;
	string outputcode;
	//fc_4_4_12_0_4_W_rom_0
	
	//fc_4_4_12_0_4_0mem_w(.clk(clk),.addr(addr_w),.z_0(mem_w_r));
	
	for(int a = 0; a< P; a++)
	{
		modName_temp = romModName + "_" + to_string(a);
		if(a == 0)
			ROMcode.append("if(select == "+ to_string(a) + ")\n\t\t" + modName_temp + " mem_w(.clk(clk),.addr(addr_w),.z_" + to_string(a)+"(mem_w_r));\n");
		else
			ROMcode.append("\telse if(select == "+ to_string(a) + ")\n\t\t" + modName_temp + " mem_w(.clk(clk),.addr(addr_w),.z_" + to_string(a)+"(mem_w_r));\n");
	}
	for(int a = 0; a< P; a++)
	{
		if(a == 0)
			outputcode.append("if(output_cntr == "+ to_string(a) + ")\n\t\t" + "output_data = output_data_f[" + to_string(a)+"];\n");
		else 
			outputcode.append("\t\telse if(output_cntr == "+ to_string(a) + ")\n\t\t" + "output_data = output_data_f[" + to_string(a)+"];\n");
	}

	string controlpath_name = "control_path_" + modName;
	string datapath_name = "data_path_" + modName;
   //cout<<ROMcode<<endl;
   string old_w[14] = {"_M_","_N_","main_module_name","_memory_w","2_T_","_T_","_max_","_min_","_P_","//Put memory code here","_M*N/P_","//Add output logic here","data_path_name","control_path_name"};
   string new_w[14] = {to_string(M),to_string(N),modName,romModName,to_string(T*2),to_string(T),to_string(long (pow(2,T-1)-1)),to_string(long (pow(2,T-1))), to_string(P),ROMcode,to_string(M*N/P), outputcode,datapath_name, controlpath_name};
   findAndreplaceAll(old_w,new_w,os,out_file,14,true);
	
	
   if(R == 1)
   {
		old_w[0] = {"// Add_Relu_code_here"};
		new_w[0] = {"if(output_valid_r == 1) begin \n if(output_data <= 0) \n  output_data <= 0; \nend"};
		findAndreplaceAll(old_w,new_w,os,out_file,1,false);
   }
   if (gen_cc == true)
   {
	   new_w[0] = {"module memory(clk, data_in, data_out,addr, wr_en);\n\tparameter 			WIDTH=16, SIZE=64, ADDR_SIZE = $clog2(SIZE);\n\tlocalparam          LOGSIZE=$clog2(SIZE);\n\tinput [WIDTH-1:0]	data_in;\n\toutput logic [WIDTH-1:0] data_out;\n\tinput [ADDR_SIZE-1:0] addr;\n\tinput				clk,wr_en;\n\tlogic [SIZE-1:0][WIDTH-1:0] mem;\n\talways_ff @(posedge clk) begin\n\t\tdata_out<=mem[addr];\n\t\tif(wr_en)\n\t\t\tmem[addr]<=data_in;\n\tend\nendmodule\n"};
	   old_w[0] = "// Add memory code here";
	   findAndreplaceAll(old_w,new_w,os,out_file,1,false);
   }

   // You will need to generate ROM(s) with values from the pre-stored constant values.
   // Here is code that demonstrates how to do this for the simple case where you want to put all of
   // the matrix values W in one ROM. This is probably what you will need for P=1, but you will want 
   // to change this for P>1. Please also see some examples of splitting these vectors in the Part 3
   // code.


   // Check there are enough values in the constant file.
   if (M*N != constVector.size()) {
      cout << "ERROR: constVector does not contain correct amount of data for the requested design" << endl;
      cout << "The design parameters requested require " << M*N+M << " numbers, but the provided data only have " << constVector.size() << " constants" << endl;
      assert(false);
   }

   // Generate a ROM (for W) with constants 0 through M*N-1, with T bits
   
   genROM(constVector, T, romModName, os,P,N,M);

}

void possible_P(int * arr,int limit)
{
	int j =0;
	for(int i =1;i<=limit;i++)
	{
		if(limit%i == 0)
		{
			arr[j] = i;
			j++;
		}
	}
}

float layer_delay(float P,float N,float M)
{
	return ((N+3+(2*P))*M/P + (N +1));
}
float layer_delayx(float P1,float P2, float N1, float M1, float M2)
{
	return (((M1+3+(2*P2))*M2/P2) + ((N1+3+(2*P1))*M1/P1) -N1 -3);
}
// Part 3: Generate a hardware system with three layers interconnected.
// Layer 1: Input length: N, output length: M1
// Layer 2: Input length: M1, output length: M2
// Layer 3: Input length: M2, output length: M3
// B is the number of multipliers your overall design may use.
// Your goal is to build the fastest design that uses B or fewer multipliers
// constVector holds all the constants for your system (all three layers, in order)
void genNetwork(int N, int M1, int M2, int M3, int T, int R, int B, vector<int>& constVector, string modName, fstream &os, string out_file) {

	int Total_B;
	float l1_delay,l2_delay,l3_delay,max_delay,temp_tp,delay;
	float highest_tp = 0, lowest_Budget_used=B;
	struct best_comb A[100];
	int z = 0;
	
	// Find the possible P value for the three layers
	static int P_l1[100];
	static int P_l2[100];
	static int P_l3[100];

	possible_P(P_l1, M1);
	possible_P(P_l2, M2);
	possible_P(P_l3, M3);
	
	for (int i = M1 - 1; i >= 0; i--) 
	cout << P_l1[i];
	cout <<""<<endl;
	
	for (int i = M2 - 1; i >= 0; i--) 
	cout << P_l2[i];
	cout <<""<<endl;
	
	for (int i = M3 - 1; i >= 0; i--) 
	cout << P_l3[i];
	cout <<""<<endl;

	
	int P1 = 1; // replace this with your optimized value
	int P2 = 1; // replace this with your optimized value
	int P3 = 1; // replace this with your optimized value
   
   
	l1_delay = (layer_delay(P1,N,M1));
	l2_delay = (layer_delayx(P1,P2,N,M1,M2));
	l3_delay = (layer_delayx(P2,P3,M1,M2,M3)); 
	//l2_delay = (layer_delay(P2,M1,M2));
	//l3_delay = (layer_delay(P3,M2,M3));
			 	
	cout<<"------Init optimizer------"<<endl;
	cout<<"L1 delay = "<<l1_delay<<endl;
	cout<<"L2 delay = "<<l2_delay<<endl;
	cout<<"L3 delay = "<<l3_delay<<endl;
	
	max_delay =  max({l1_delay, l2_delay, l3_delay});
	delay = max_delay;
	
	cout<<"Initial System Max Delay = "<<max_delay<<endl;	
  
	if(max_delay == l1_delay)
		highest_tp = N/l1_delay;
	else if(max_delay == l2_delay)
		highest_tp = M1/l2_delay;
	else if(max_delay == l3_delay)
		highest_tp = M2/l3_delay;
	
	cout<<"Initial Highest throughput = "<<highest_tp<<endl;
	for(int i=0;P_l1[i]!=0;i++)
	{
		for(int j=0;P_l2[j]!=0;j++)
		{
			for(int k=0;P_l3[k]!=0;k++)
			{
				Total_B = P_l1[i] + P_l2[j] + P_l3[k];
				//Check if total P value is within the budget
				if(Total_B <= B)
				{
					
					l1_delay =  layer_delay(P_l1[i],N,M1);
					l2_delay =  layer_delayx(P_l1[i],P_l2[j],N,M1,M2);
					l3_delay =  layer_delayx(P_l2[j],P_l3[k],M1,M2,M3);
					//l2_delay =  layer_delay(P_l2[j],M1,M2);
					//l3_delay =  layer_delay(P_l3[k],M2,M3);

					max_delay = max({l1_delay, l2_delay, l3_delay});
					//Overall throughput of the system = throughput of the slowest layer
					if(max_delay == l1_delay)
						temp_tp = N/l1_delay;
					else if(max_delay == l2_delay)
						temp_tp = M1/l2_delay;
					else if(max_delay == l3_delay)
						temp_tp = M2/l3_delay;
					

						
					// if this throughput is greater than the current best throughtput value and lowest budget is used to achieve this best TP,
					// Select this as the best combination pf P1,P2,P3 and the best throuput
					// that can be acheived through optimization
					/*if(temp_tp == highest_tp)
					{	
						A[z].P1 = P_l1[i];
						A[z].P2 = P_l2[j];
						A[z].P3 = P_l3[k];
						A[z].budget_used = Total_B;
						cout<<"A P1,P2, P3 combination with same highest TP  
					}	*/
					if(max_delay < delay)
					{
						P1 = P_l1[i];
						P2 = P_l2[j];
						P3 = P_l3[k];
						delay = max_delay;
						
						cout<<"Highest TP achieved for P1="<<P_l1[i]<<" P2 = "<<P_l2[j]<<" P3 ="<<P_l3[k]<<" TP = "<<temp_tp << " Max delay = "<<max_delay<<" Used Budget = " <<Total_B<<endl;
					}
					else
					{
						cout<<"Not the highest TP achieved for P1="<<P_l1[i]<<" P2 = "<<P_l2[j]<<" P3 ="<<P_l3[k]<<" TP = "<<temp_tp << " Max delay = "<<max_delay<<" Used Budget = " <<Total_B<<endl;
					}
					
				}
				else
				{
					cout<<"Budget not satisfied! for P1="<<P_l1[i]<<" P2 = "<<P_l2[j]<<" P3 ="<<P_l3[k]<<endl;
					//Skip since this combination of P1,P2 and P3 execeeds the budget available
				}
			}
		}
	}
	cout<<"Choosing the best combination out of the group with the same TP, based on Budget used"<<endl;
	for(int i=0;P_l1[i]!=0;i++)
	{
		for(int j=0;P_l2[j]!=0;j++)
		{
			for(int k=0;P_l3[k]!=0;k++)
			{
				
				Total_B = P_l1[i] + P_l2[j] + P_l3[k];
				if(Total_B <= B)
				{
					l1_delay =  layer_delay(P_l1[i],N,M1);
					l2_delay =  layer_delayx(P_l1[i],P_l2[j],N,M1,M2);
					l3_delay =  layer_delayx(P_l2[j],P_l3[k],M1,M2,M3);
					
					max_delay = max({l1_delay, l2_delay, l3_delay});
						//Overall throughput of the system = throughput of the slowest layer
						if(max_delay == l1_delay)
							temp_tp = N/l1_delay;
						else if(max_delay == l2_delay)
							temp_tp = M1/l2_delay;
						else if(max_delay == l3_delay)
							temp_tp = M2/l3_delay;
						
					if(max_delay == delay)
					{
						if(Total_B<lowest_Budget_used)
						{
							P1 = P_l1[i];
							P2 = P_l2[j];
							P3 = P_l3[k];
							lowest_Budget_used = Total_B;
							cout<<"Combinatons with same TP P1="<<P_l1[i]<<" P2 = "<<P_l2[j]<<" P3 ="<<P_l3[k]<<" TP = "<<temp_tp << " Max delay = "<<max_delay<<" Used Budget = " <<lowest_Budget_used<<endl;
					
						}
					}
				}
			}
		}
	}
	cout<<"Result after optimization"<<endl;
	cout<<"P1="<<P1<<" P2="<<P2<<" P3="<<P3<<" c cycles = "<<delay<<" delay"<<" Used Budget = " <<lowest_Budget_used<<endl;
	// Here you will write code to figure out the best values to use for P1, P2, and P3, given
	// B. 
	//P1 = 1; // replace this with your optimized value
	//P2 = 1; // replace this with your optimized value
	//P3 = 1; // replace this with your optimized value
	
	
	// -------------------------------------------------------------------------
	// Split up constVector for the three layers
	// layer 1's W matrix is M1 x N
	int start = 0;
	int stop = M1*N;
	vector<int> constVector1(&constVector[start], &constVector[stop]);

	// layer 2's W matrix is M2 x M1
	start = stop;
	stop = start+M2*M1;
	vector<int> constVector2(&constVector[start], &constVector[stop]);

	// layer 3's W matrix is M3 x M2
	start = stop;
	stop = start+M3*M2;
	vector<int> constVector3(&constVector[start], &constVector[stop]);

	if (stop > constVector.size()) {
	  os << "ERROR: constVector does not contain enough data for the requested design" << endl;
	  os << "The design parameters requested require " << stop << " numbers, but the provided data only have " << constVector.size() << " constants" << endl;
	  assert(false);
	}
	// --------------------------------------------------------------------------

	fstream os1;
	fstream os2;
	fstream os3;
	
	// generate the three layer modules
	// Layer 1
	string subModName1 = "l1_fc_" + to_string(M1) + "_" + to_string(N) + "_" + to_string(T) + "_" + to_string(R) + "_" + to_string(P1);
	string subModName1_file = "l1_fc_" + to_string(M1) + "_" + to_string(N) + "_" + to_string(T) + "_" + to_string(R) + "_" + to_string(P1) + ".sv";
	os1.open(subModName1_file,fstream::out);
	if (os1.is_open() != true) {
	 cout << "ERROR opening " << subModName1_file << " for write." << endl;
	 //return 1;
	}
	genFCLayer(M1, N, T, R, P1, constVector1, subModName1, os1, subModName1_file,true);
	os1.close();
	
	// Layer 2
	string subModName2 = "l2_fc_" + to_string(M2) + "_" + to_string(M1) + "_" + to_string(T) + "_" + to_string(R) + "_" + to_string(P2);
	string subModName2_file = "l2_fc_" + to_string(M2) + "_" + to_string(M1) + "_" + to_string(T) + "_" + to_string(R) + "_" + to_string(P2) + ".sv";
	os2.open(subModName2_file,fstream::out);
	if (os2.is_open() != true) {
	 cout << "ERROR opening " << subModName2_file << " for write." << endl;
	 //return 1;
	}
	genFCLayer(M2, M1, T, R, P2, constVector2, subModName2, os2,subModName2_file,false);
	os2.close();
	
	// Layer 3
	string subModName3 = "l3_fc_" + to_string(M3) + "_" + to_string(M2) + "_" + to_string(T) + "_" + to_string(R) + "_" + to_string(P3);
	string subModName3_file = "l3_fc_" + to_string(M3) + "_" + to_string(M2) + "_" + to_string(T) + "_" + to_string(R) + "_" + to_string(P3) + ".sv";
	os3.open(subModName3_file,fstream::out);
	if (os3.is_open() != true) {
	 cout << "ERROR opening " << subModName3_file << " for write." << endl;
	 //return 1;
	}
	genFCLayer(M3, M2, T, R, P3, constVector3, subModName3, os3,subModName3_file,false);
	os3.close();
	
	
/*	module net_8_8_8_8_13_0_3(clk, reset, input_valid, input_ready, input_data, output_valid, output_ready, output_data);

input						clk, reset, input_valid, output_ready;
input signed [13-1:0]  		input_data;
output 		 				output_valid, input_ready;
output logic signed [13-1:0] output_data;
logic 						output_valid1, output_valid2, input_ready2,input_ready3;
logic signed [13-1:0] 		output_data1, output_data2;

l1_fc_8_8_13_0_1 layer1(clk, reset, input_valid, input_ready, input_data, output_valid1, input_ready2, output_data1);
l2_fc_8_8_13_0_1 layer2(clk, reset, output_valid1, input_ready2, output_data1, output_valid2, input_ready3, output_data2);
l3_fc3_8_8_13_0_1 layer3(clk, reset, output_valid2, input_ready3, output_data2, output_valid, output_ready, output_data);

endmodule
*/	
	
	// output top-level module
	os << "`include \""<< subModName1_file <<"\"" << endl;
	os << "`include \""<< subModName2_file <<"\"" <<endl;
	os << "`include \""<< subModName3_file <<"\"" <<endl;
	os << "module " << modName << "(clk, reset, input_valid, input_ready, input_data, output_valid, output_ready, output_data);" << endl;
	os << "\tinput						clk, reset, input_valid, output_ready;"<< endl;
	os << "\tinput signed [" << to_string(T)<<"-1:0]" << "input_data;" << endl;
	os << "\toutput 		 				output_valid, input_ready;" <<endl;
	os << "\toutput signed [" << to_string(T) <<"-1:0]"<< "output_data;" << endl;
	os << "\tlogic 						output_valid1, output_valid2, input_ready2,input_ready3;" <<endl;
	os << "\tlogic signed [" << to_string(T)<<"-1:0]" 	<< "output_data1, output_data2;" << endl;
	
	os <<"\t"<<subModName1 << " layer1(clk, reset, input_valid, input_ready, input_data, output_valid1, input_ready2, output_data1);" <<endl;
	os <<"\t"<< subModName2 << " layer2(clk, reset, output_valid1, input_ready2, output_data1, output_valid2, input_ready3, output_data2);" <<endl;
	os <<"\t"<< subModName3 << " layer3(clk, reset, output_valid2, input_ready3, output_data2, output_valid, output_ready, output_data);" <<endl;
	os << "endmodule" << endl;


}


void printUsage() {
  cout << "Usage: ./gen MODE ARGS" << endl << endl;

  cout << "   Mode 1 (Part 1): Produce one neural network layer (unparallelized)" << endl;
  cout << "      ./gen 1 M N T R const_file" << endl << endl;

  cout << "   Mode 2 (Part 2): Produce one neural network layer (parallelized)" << endl;
  cout << "      ./gen 2 M N T R P const_file" << endl << endl;

  cout << "   Mode 3 (Part 3): Produce a system with three interconnected layers" << endl;
  cout << "      ./gen 3 N M1 M2 M3 T R B const_file" << endl;
}

void findAndreplaceAll(string oldw[], string neww[],fstream &fout,string out_file, int size,bool first)
{
	int i;
	fstream t_file;
	fstream fs;
	string tmp;
	string t = "temp.txt";
	string temp =  "template.sv";
	fout.close();
	for(i = 0;i<size;i++)
	{	
		//For the first time take template as the reference
		if( first == true && i == 0)
		{
			fs.open(temp, ios::in);
			fout.open(out_file,ios::out);
		// After the first time take the out_file as the reference, because we need to find and replace in
		// the updated file
		}
		else
		{
			//fout.open(out_file,ios::out);
			t_file.open(t,ios::out);
			fs.open(out_file,ios::in);
		}
		while (!fs.eof()) 
		{
			getline(fs, tmp);
			while (tmp.find(oldw[i]) != string::npos)
			{
				tmp.replace(tmp.find(oldw[i]), oldw[i].length(), neww[i]);
			}
			if(first == true && i == 0)
			{
				fout << tmp << endl;
			}
			else
			{
				t_file << tmp << endl;
			}
		}
		if(first == true && i == 0)
		{
			fout.close();
			fs.close();
		}
		else
		{
			t_file.close();
			fs.close();
			t_file.open(t,ios::in);
			fs.open(out_file,ios::out);
			while (!t_file.eof())
			{
			getline(t_file, tmp);
			fs << tmp << endl;
			} 
			t_file.close();
			t_file.close();
			fs.close();
		}
	}
	fout.open(out_file, ios::out| ios::app);
}