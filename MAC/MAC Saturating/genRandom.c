//Author : George

#include <stdio.h>
#include <time.h>

#define MASK_14 16383
#define MASK_28 268435455
int main() {
    int desiredInputs = 100000;
    srand(time(NULL)); // Set random seed based on current time

    FILE *inputData, *expectedOutput;

    inputData = fopen("inputData", "w");
    expectedOutput = fopen("expectedOutput", "w");

    fprintf(expectedOutput, "xxxxxxx x\n0000000 0\n0000000 0\n"); // To match output file

    int i, reset, reset_t, valid_in[desiredInputs], valid_out[desiredInputs], mult_ab; 
    int output[desiredInputs], mult_ab27, out_iprev27, out_i27;
    
    int a=0,b=0;

    for (i=0; i<desiredInputs; i++) {
        a = (-8192 + (rand() % 16384)); 
        b = (-8192 + (rand() % 16384));
        valid_in[i] = rand() % 2;
        reset_t = rand() % 100;
	mult_ab = a*b;
        mult_ab27 = (mult_ab & (1<<27)) >> 27;
	if (reset_t == 5)
	{
		reset = 1;
	        printf("reset index is at %d\n", i+5);
	}
	else 
	{
		reset = 0;
	}
	fprintf(inputData, "%x\n%x\n%x\n%x\n", valid_in[i], (a&MASK_14),(b&MASK_14), reset);
	if (reset == 1)
	{
		output[i-1] = 0;
		output[i] = 0;
		valid_out[i-1] = 0;
		valid_out[i] = 0;
	}
	else 
	{
		if (valid_in[i] == 1)
		{
			output[i] = output[i-1] + a*b;
        		out_i27 = (output[i] & (1<<27)) >> 27;
        		out_iprev27 = (output[i-1] & (1<<27)) >> 27;
			if (~(out_iprev27 ^ mult_ab27) & (out_iprev27 ^ out_i27))
				if(out_iprev27 == 0)
					output[i] = 134217727;
				else
					output[i] = -134217728;
		}
		else
		{
			output[i] = output[i-1];
		}
		valid_out[i] = valid_in[i];
	}
	
    }

    for (i=0; i<desiredInputs-1; i++) {
    	fprintf(expectedOutput, "%07x %x\n", output[i] & MASK_28, valid_out[i]);
    }
    fclose(inputData);
    fclose(expectedOutput);
}
