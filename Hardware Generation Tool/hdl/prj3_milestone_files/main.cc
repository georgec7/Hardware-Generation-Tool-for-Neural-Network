
#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <cstdlib>
#include <cstring>
#include <assert.h>
#include <math.h>
using namespace std;
// Function prototypes
void printUsage();
void genFCLayer(int M, int N, int T, int R, int P, vector<int>& constVector, string modName, fstream &os,string out_file);
void genNetwork(int N, int M1, int M2, int M3, int T, int R, int B, vector<int>& constVector, string modName, fstream &os,string out_file);
void readConstants(ifstream &constStream, vector<int>& constvector);
void genROM(vector<int>& constVector, int bits, string modName, fstream &os);
void findAndreplaceAll(string oldw[], string neww[],fstream &fout, string out_file,int size,bool first);

int main(int argc, char* argv[]) {

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
      genFCLayer(M, N, T, R, P, constVector, modName, os,out_file); 

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


      os.open(out_file);
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
void genROM(vector<int>& constVector, int bits, string modName, fstream &os) {

      int numWords = constVector.size();
      int addrBits = ceil(log2(numWords));

      os << "module " << modName << "(clk, addr, z);" << endl;
      os << "   input clk;" << endl;
      os << "   input [" << addrBits-1 << ":0] addr;" << endl;
      os << "   output logic signed [" << bits-1 << ":0] z;" << endl;
      os << "   always_ff @(posedge clk) begin" << endl;
      os << "      case(addr)" << endl;
      int i=0;
      for (vector<int>::iterator it = constVector.begin(); it < constVector.end(); it++, i++) {
         if (*it < 0)
            os << "        " << i << ": z <= -" << bits << "'d" << abs(*it) << ";" << endl;
         else
            os << "        " << i << ": z <= "  << bits << "'d" << *it      << ";" << endl;
      }
      os << "      endcase" << endl << "   end" << endl << "endmodule" << endl << endl;
}

// Parts 1 and 2
// Here is where you add your code to produce a neural network layer.
void genFCLayer(int M, int N, int T, int R, int P, vector<int>& constVector, string modName, fstream &os,string out_file) {				 
	
   string romModName = modName + "_W_rom";
   string old_w[8] = {"_M_","_N_","main_module_name","_memory_w","2_T_","_T_","_max_","_min_"};
   string new_w[8] = {to_string(M),to_string(N),modName,romModName,to_string(T*2),to_string(T),to_string(long (pow(2,T-1)-1)),to_string(long (pow(2,T-1)))};
   findAndreplaceAll(old_w,new_w,os,out_file,8,true);
	
   if(R == 1)
   {
		old_w[0] = {"// Add_Relu_code_here"};
		new_w[0] = {"if(output_valid_r == 1) begin \n if(output_data <= 0) \n  output_data <= 0; \nend"};
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
   
   genROM(constVector, T, romModName, os);

}

// Part 3: Generate a hardware system with three layers interconnected.
// Layer 1: Input length: N, output length: M1
// Layer 2: Input length: M1, output length: M2
// Layer 3: Input length: M2, output length: M3
// B is the number of multipliers your overall design may use.
// Your goal is to build the fastest design that uses B or fewer multipliers
// constVector holds all the constants for your system (all three layers, in order)
void genNetwork(int N, int M1, int M2, int M3, int T, int R, int B, vector<int>& constVector, string modName, fstream &os, string out_file) {

   // Here you will write code to figure out the best values to use for P1, P2, and P3, given
   // B. 
   int P1 = 1; // replace this with your optimized value
   int P2 = 1; // replace this with your optimized value
   int P3 = 1; // replace this with your optimized value

   // output top-level module
   os << "module " << modName << "();" << endl;
   os << "   // this module should instantiate three layers and wire them together" << endl;
   os << "endmodule" << endl;
   
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


   // generate the three layer modules
   string subModName1 = "l1_fc_" + to_string(M1) + "_" + to_string(N) + "_" + to_string(T) + "_" + to_string(R) + "_" + to_string(P1);
   genFCLayer(M1, N, T, R, P1, constVector1, subModName1, os, out_file);

   string subModName2 = "l2_fc_" + to_string(M2) + "_" + to_string(M1) + "_" + to_string(T) + "_" + to_string(R) + "_" + to_string(P2);
   genFCLayer(M2, M1, T, R, P2, constVector2, subModName2, os,out_file);

   string subModName3 = "l3_fc3_" + to_string(M3) + "_" + to_string(M2) + "_" + to_string(T) + "_" + to_string(R) + "_" + to_string(P3);
   genFCLayer(M3, M2, T, R, P3, constVector3, subModName3, os,out_file);

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