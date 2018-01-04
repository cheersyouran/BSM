
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdlib.h>
#include <stdio.h> 
#include <time.h>

#define SIZE_OF_PATTERN 8192
#define SIZE_OF_TARGET 58280548
#define threadNum 8
#define blockNum 256

char Pat[SIZE_OF_PATTERN + 1];
char Tar[SIZE_OF_TARGET + 1];
int Skipping[SIZE_OF_PATTERN + 2][7] = { 0 };
//__constant__ int d_Skipping[(SIZE_OF_PATTERN+2)*7];

void Build_Map(){
	// init Skipping array 
	for (int i = SIZE_OF_PATTERN - 1; i >= 0; i--){
		Skipping[SIZE_OF_PATTERN - i][0] = Pat[i];
		Skipping[SIZE_OF_PATTERN - i - 1][(Pat[i])%5+1] = SIZE_OF_PATTERN - i;
	}
	//bool flag = false;
	int temporary_root;
	int current_processing;
	for (int i = 1; i <= SIZE_OF_PATTERN; i++){
		temporary_root = 0;
		//flag = false;
		for(current_processing = i;current_processing <= SIZE_OF_PATTERN;current_processing ++){
			if (Skipping[temporary_root][((char)Skipping[current_processing][0])%5+1] != 0){
				temporary_root = Skipping[temporary_root][((char)Skipping[current_processing][0])%5+1];
				if (current_processing == SIZE_OF_PATTERN){
					Skipping[temporary_root][6] = 1;
					break;
				}
			}
			else{
				Skipping[temporary_root][((char)Skipping[current_processing][0])%5+1] = current_processing;
				break;
			}
		} 
	}
	Skipping[SIZE_OF_PATTERN][6] = 1;
}

__global__ void MyMethod(char *Tar,int* d_Skipping, int *Output){

	int thd = blockIdx.x*blockDim.x+threadIdx.x;
	int thx = threadIdx.x;
	//int index_in_tar=thx*SIZE_OF_PATTERN;
	int index_in_tar=thd*SIZE_OF_PATTERN;
	int Skip[20];
	for (int i = 0; i < 20; i++){
		Skip[i] = -1;
	}
	//Start searching
	int index_in_pat = 0;
	int index_in_skip = 0;
	int possible_start = 0;
	int tail_Node = 0;
	int test_index = 0;
	int temp_Node = 0;

	if (thd <= SIZE_OF_TARGET/SIZE_OF_PATTERN-1){
		for (index_in_pat = SIZE_OF_PATTERN - 1;index_in_pat >= 0;index_in_pat--){
			//detect skipping number
			if (d_Skipping[index_in_skip*7+(Tar[index_in_tar+index_in_pat])%5+1] != 0){
				index_in_skip = d_Skipping[index_in_skip*7+(Tar[index_in_tar+index_in_pat])%5+1];
				possible_start++;
				if (d_Skipping[index_in_skip*7+6] == 1){
					Skip[tail_Node] = possible_start;
					tail_Node ++;
				}
			}
			else break;			
		}
		while(Skip[temp_Node] != -1){
			if(Tar[index_in_tar+SIZE_OF_PATTERN  + test_index]!=d_Skipping[(SIZE_OF_PATTERN - Skip[temp_Node] - test_index)*7+0]){
				Skip[temp_Node++]=-1;
				test_index = 0;
			}
			else{
				if (Skip[temp_Node] + test_index == SIZE_OF_PATTERN-1){
					//printf("Found it! Start from : %d\n",index_in_tar + 5 - possible_matching[0] );
					Output[thd]=(thd+1)*SIZE_OF_PATTERN - Skip[temp_Node];
					Skip[temp_Node++]=-1;
					test_index = 0;
				}
				else 
					test_index++;
			}
		}	
	}
}

int main (){
	FILE * fp1 = fopen("60.txt", "r");
	FILE * fp2 = fopen("8192.txt", "r");
	fscanf(fp1, "%s", Tar);
	fscanf(fp2, "%s", Pat);
	fclose(fp1);
	fclose(fp2);

	Build_Map();

	int Tar_Size =(SIZE_OF_TARGET + 1)*sizeof(char);
	int Skip_Size = ((SIZE_OF_PATTERN + 2)*7)*sizeof(int);
	int Output[threadNum*blockNum] = {0};
	int Output_Size = threadNum*blockNum*sizeof(int);
	char *d_Tar;
	int *d_Skip;
	int *d_output;

	cudaMalloc((void**)&d_Tar,Tar_Size);
	cudaMemcpy(d_Tar,Tar,Tar_Size,cudaMemcpyHostToDevice);
	cudaMalloc((void**)&d_Skip,Skip_Size);
	cudaMemcpy(d_Skip,Skipping,Skip_Size,cudaMemcpyHostToDevice);

	//cudaMemcpyToSymbol(d_Skipping,Skipping,Skip_Size,0U,cudaMemcpyHostToDevice);

	cudaMalloc((void**)&d_output,Output_Size);
	dim3 dimgrid(blockNum,1,1);
	dim3 dimblock(threadNum,1,1);

	float time=0;
	cudaEvent_t start,stop;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);
	cudaEventRecord(start,0);

	MyMethod<<<dimgrid,dimblock>>>(d_Tar,d_Skip,d_output);
	
	cudaEventRecord(stop,0);
	cudaEventSynchronize(start);
	cudaEventSynchronize(stop);
	cudaEventElapsedTime(&time,start,stop);
	printf("time is  %f(ms)\n",time/1000);
	
	cudaMemcpy(Output,d_output,Output_Size,cudaMemcpyDeviceToHost);
	cudaFree(d_Tar);
	//cudaFree(d_Skip);
	cudaFree(d_output);
	
	for(int i = 0;i<threadNum*blockNum;i++)
		if(Output[i]>0)
			printf("Find it by GPU.%d\n",Output[i]);
	return 0;
}
