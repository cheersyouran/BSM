#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include "string.h"
#include <iostream>  
#include <cstring>  
#include <windows.h> ¡¡
using namespace std; 

#define SIZE_OF_PATTERN  1024
#define SIZE_OF_TARGET 33554432

char Pat[SIZE_OF_PATTERN + 1];
char Tar[SIZE_OF_TARGET + 1];
int Skipping[SIZE_OF_PATTERN + 2][22] = { 0 };
int possible_matching[20];

void BuildAutomaton(){
	for (int i = 1; i <= SIZE_OF_PATTERN; i++){
		Skipping[i][0] = Pat[SIZE_OF_PATTERN-i];	
	}
	int temporary_root;
	int current_processing;
	for (int i = 1; i <= SIZE_OF_PATTERN; i++){
		temporary_root = 0;
		Skipping[i - 1][Pat[SIZE_OF_PATTERN-i] - 'A' + 1] = i;
		for(current_processing = i;current_processing <=SIZE_OF_PATTERN;current_processing ++){
			if (Skipping[temporary_root][(char)Skipping[current_processing][0] - 'A' + 1] != 0){
				temporary_root = Skipping[temporary_root][(char)Skipping[current_processing][0] - 'A' + 1];
				if (current_processing == SIZE_OF_PATTERN){
					Skipping[temporary_root][21] = 1;
					break;
				}
			}
			else{
				Skipping[temporary_root][(char)Skipping[current_processing][0] - 'A' + 1] = current_processing;
				break;
			}
		}
	}
	Skipping[SIZE_OF_PATTERN][21] = 1;
}


void Search(char *Tar, char *Pat){
	for (int i = 0; i < 20; i++){
		possible_matching[i] = -1;
	}
	printf("------------the start of BSM method---------------\n");
	clock_t start, end, p_start, p_end;
	double runTime;
	p_start = clock();
	//Build map
	BuildAutomaton();
	p_end = clock();
	runTime = (p_end - p_start) / (double)CLOCKS_PER_SEC;
	printf("preprocess time is: %lf \n", runTime);
	//Start searching
	int index_in_tar = 0;
	start = clock();
	while (index_in_tar <= SIZE_OF_TARGET-SIZE_OF_PATTERN){
		int index_in_skip = 0;
		int tail_Node = 0;
		int temp_Node=0;
		for (int index_in_pat = SIZE_OF_PATTERN - 1;index_in_pat >= 0;index_in_pat--){
			if (Skipping[index_in_skip][Tar[index_in_tar + index_in_pat] - 'A' + 1] != 0){
				index_in_skip = Skipping[index_in_skip][Tar[index_in_tar + index_in_pat] - 'A' + 1];
				if (Skipping[index_in_skip][21] == 1){
					possible_matching[tail_Node++] = SIZE_OF_PATTERN - index_in_pat;
				}
			}
			else break;			
		}
		while(possible_matching[temp_Node] != -1){
			for(int test_index = 0;test_index<SIZE_OF_PATTERN;test_index++ ){
				if(Tar[index_in_tar + SIZE_OF_PATTERN  + test_index]
					!=Skipping[SIZE_OF_PATTERN - possible_matching[temp_Node] - test_index][0]){
					possible_matching[temp_Node++]=-1;
					break;
				}
				else{
					if (possible_matching[temp_Node] + test_index == SIZE_OF_PATTERN-1){
						printf("Found it! Start from : %d\n",index_in_tar + SIZE_OF_PATTERN - possible_matching[temp_Node] );
						possible_matching[temp_Node++] = -1;
						break;
					}
				}
			}
		}	
		index_in_tar += SIZE_OF_PATTERN;
	}
	end = clock();
	
	runTime = (end - start) / (double)CLOCKS_PER_SEC;
	printf("------------the finish of BSM method---------------\n");
	printf("find time is: %lf \n\n", runTime);
}


int main(){
    FILE * fp1 = fopen("33554432.txt", "r");
	FILE * fp2 = fopen("1024.txt", "r");
	fscanf(fp1, "%s", Tar);
	fscanf(fp2, "%s", Pat);
	fclose(fp1);
	fclose(fp2);
	
	Search(Tar,Pat);
	
	return 0;
}
