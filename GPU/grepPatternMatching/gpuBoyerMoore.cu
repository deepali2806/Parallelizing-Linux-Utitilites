#include<stdio.h>
#include<stdlib.h>
#include <sys/time.h> 
#include <climits>
#include <fstream>
#include <iostream>
#include <sstream>
#include <cuda.h>
#include <curand_kernel.h>
#include <curand.h>
#include<bits/stdc++.h>
#define BLOCKSIZE 32

using namespace std;


__global__ void patternMatchingBoyerMoore(char *inputText, int iLength, int *gpuLength, int *lastTable, char *pattern, int pLength, int* gpuResultLine, int n)
{
    unsigned id = blockIdx.x * blockDim.x + threadIdx.x;
    if(id < n)
    {
       // printf("\nId  %d Inside Last Table\n", id);
        
        if(gpuLength[id] < pLength)
        {
            gpuResultLine[id] = 0;
            return;
        }

        int i = pLength - 1;
        int j= pLength - 1;
        int cnt = 0;
        while(i < (gpuLength[id] - 1))
        {

           // printf("\nId %d inpt Char %c iLength %d i %d", id, inputText[id*iLength + i], iLength, i);
            if(inputText[id*iLength + i] == pattern[j])
            {
                if(j == 0)
                {
                    //printf("Found Id %d", id);
                    gpuResultLine[id] = 1;
                    return;
                }
                else
                {
                    i--;
                    j--;
                }
            }
            else
            {
                if(inputText[id*iLength + i] > 57)
                {
                    if(inputText[id*iLength + i] >= 97 && inputText[id*iLength + i] <= 122)
                    {
                        i = i + pLength - min (j, 1 + lastTable[inputText[id*iLength + i] - 97 + 26]);
                    }
                    else
                    {
          //              printf("\nId %d j %d lastTabe %d inpt Char %c", id, j, lastTable[inputText[id*iLength + i] - 65], inputText[id*iLength + i]);
                        i = i + pLength - min (j, 1 + lastTable[inputText[id*iLength + i] - 65]);
                    }
                }
                else
                {
                    if(inputText[id*iLength + i] >= 48 && inputText[id*iLength + i] <= 57)
                        i = i + pLength - min (j, 1 + lastTable[inputText[id*iLength + i] - 48 + 52]);
                    else if(inputText[id*iLength + i] == 32)
                        i = i + pLength - min (j, 1 + lastTable[inputText[id*iLength + i] - 32 + 62]);
                }

                j = pLength - 1;
            }

         //   printf("\nId %d Shift %d", id, i);
         cnt++;
        }

        gpuResultLine[id] = 0;
        return;
       
    } 
}



int main(int argc, char **argv)
{
    int n;
    int iLength;
    
	FILE *filePointer;
	char *filename = argv[1]; 
   	filePointer = fopen( filename , "r") ; 
      
    if ( filePointer == NULL ) 
    {
       printf( "input.txt file failed to open." ) ; 
	   return 0;
    }

    char newLine;
    fscanf(filePointer, "%d", &n);
    fscanf(filePointer, "%d", &iLength);
    fscanf(filePointer, "%c", &newLine);

    char inputText[(iLength+1)*(n)];
    int length[n];
    char temp;

    //Todo last line may not havenewLine character at end
    for (int i = 0; i < n; i++)
    {
        int temp1 = 0;
        for(int j = 0; j <= iLength; j++)
        {
            temp1++;
            fscanf(filePointer, "%c", &temp);
            if(temp == '\n')
            {
                inputText[i*iLength + j] = '\0';
                break;
            }  
            else
            {
                inputText[i*iLength + j] = temp;
    
            }
        }
        length[i] = temp1;
    }
  
    // cout<<"Length";
    // for(int i = 0; i < n; i++)
    // {
    //     cout<<length[i]<<" ";
    // }
    // cout<<endl;
    // for (size_t i = 0; i < n; i++)
	// {
	//     for (size_t j = 0; j <= iLength; j++)
	//     {
	//     	if(inputText[i*iLength + j] != '\0')
	// 		printf("%c", inputText[i*iLength + j]);
    //         else
    //         {
    //             printf("Null");
    //             break;
    //         }
	//     }
	//     printf("\n");
	// }

    char *gpuInputText;
    cudaMalloc(&gpuInputText, (iLength+1)*(n)*sizeof(char));
    cudaMemcpy(gpuInputText, inputText, (iLength+1)*(n)*sizeof(char), cudaMemcpyHostToDevice);

    char pattern[20];
    printf("Enter the pattern you want to find");
    cin.getline(pattern, 20);
    //scanf("%s", pattern);
    printf("\nPattern is %s\n", pattern);
    
    int pLength = 0;
    while (pattern[pLength] != '\0')
    {
        pLength++;
    }
      cout<<"\nPlength "<<pLength<<endl;

    
    int *results = (int *)malloc(n*sizeof(int));
	memset(results, 0, n*sizeof(int));

    int *gpuResultLine;
    cudaMalloc( &gpuResultLine, sizeof(int)*n);
    cudaMemcpy(gpuResultLine, results,  sizeof(int)*n, cudaMemcpyHostToDevice);

    int *gpuLength;
    cudaMalloc( &gpuLength, sizeof(int)*n);
    cudaMemcpy(gpuLength, length,  sizeof(int)*n, cudaMemcpyHostToDevice);
    
    char *gpuPattern;
    cudaMalloc(&gpuPattern, 20*sizeof(char));
    cudaMemcpy(gpuPattern, pattern, 20*sizeof(char) , cudaMemcpyHostToDevice);

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    float milliseconds = 0;
    cudaEventRecord(start,0);
  
    
    //creating last Character Table : finds last occurence
    //A-Za-z0-9BlankSpace
    int lastTableSize = 63;
    int lastTable[lastTableSize];
    std::fill_n(lastTable, lastTableSize, -1);
    
    for (int i = pLength - 1; i >= 0; i--)
    {
        if (isalpha(pattern[i]))
        {
            if(islower(pattern[i]))
            {
                if(lastTable[pattern[i] - 97 + 26] == -1)
                    lastTable[pattern[i] - 97 + 26] = i;
            }
            else
            {
                if(lastTable[pattern[i] - 65] == -1)
                    lastTable[pattern[i] - 65] = i;
            }
        }
        else
        {
            if(lastTable[pattern[i] - 48 + 52] == -1)
                    lastTable[pattern[i] - 48 + 52] = i;
            else if(lastTable[pattern[i] - 32 + 62] == -1)
                    lastTable[pattern[i] - 32 + 62] = i;
        }
        
        
    }

  
   
    int *gpuLastTable;
    cudaMalloc(&gpuLastTable, lastTableSize*sizeof(int));
    cudaMemcpy(gpuLastTable, lastTable, lastTableSize*sizeof(int) , cudaMemcpyHostToDevice);

    
    patternMatchingBoyerMoore <<<ceil(float(n)/BLOCKSIZE) ,BLOCKSIZE>>> (gpuInputText, iLength, gpuLength,gpuLastTable, gpuPattern, pLength, gpuResultLine, n);
    cudaDeviceSynchronize();

    cudaEventRecord(stop,0);
    cudaEventSynchronize(stop);
	cudaEventElapsedTime(&milliseconds, start, stop);
    printf("Time taken by function to execute is: %.6f ms\n", milliseconds);
   
    cudaMemcpy(results, gpuResultLine, sizeof(int)*n , cudaMemcpyDeviceToHost);

    char *fname = argv[2]; 
    FILE *fptr;
    fptr = fopen(fname,"w");
    
    // cout<<"Final";

    
    // for(int i=0;i<n;i++)
    // {
    //     cout<<results[i]<<" ";
    // }

    // cout<<endl;

    for(int i=0;i<n;i++)
    {
        if(results[i] == 1)
        {
            for(int j = 0; j <= iLength; j++)
            {
                if(inputText[i*iLength + j] != '\0')
                    fprintf(fptr ,"%c", inputText[i*iLength + j] ); 
                else
                    break;
            }
            fprintf(fptr,"\n");
        }
    }
    fprintf(fptr,"\n"); 

    return 0;
}