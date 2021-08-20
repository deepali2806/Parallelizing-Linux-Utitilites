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

__global__ void patternMatchingNaive(char *gpuInputText ,int n, int length, char *pattern, int* gpuResultLine, int pLength, int *gpuLength)
{
    unsigned id = blockIdx.x * blockDim.x + threadIdx.x;
    if(id < n)
    {
       // printf("\nIn pattern match %c", gpuInputText[id*length + 0]);
      //  printf("\n Pattern is %s", pattern );
        //Considering reusltMatrix has fix length for all lines       
        int i = 0;
        while(i < (gpuLength[id] - 1))
        {
           // printf("\nIn For loop pattern match");
            int cnt = 0, j = 0;
            int temp = i;
            while(pattern[j] != '\0')
            {
                if(temp < length && pattern[j] == gpuInputText[id*length + temp])   
                {
                    cnt++;
                }
                else
                {
                    break;
                }
                j++;
                temp++;
            }
            
           // printf("Count %d", cnt);

            if(cnt == pLength)
            { 
                gpuResultLine[id] = 1;
             //   printf("\n Found ");

                // for(int k = 0; k < length; k++)
                // {
                //     if(gpuInputText[id*length + k] != '\0')
                //         printf("%d %c", id, gpuInputText[id*length + k]);
                //     else 
                //         break;
                // }
                    
               // printf("\n");
                return;
           }
           
           i++;
        }
        gpuResultLine[id] = 0;

    }
}


int main(int argc, char **argv)
{
    int n;
    int iLength;
   // n = 8;
    
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

    int *gpuLength;
    cudaMalloc( &gpuLength, sizeof(int)*n);
    cudaMemcpy(gpuLength, length,  sizeof(int)*n, cudaMemcpyHostToDevice);

    char pattern[20];
    printf("Enter the pattern you want to find");
    scanf("%s", pattern);
    printf("\nPattern is %s\n", pattern);
    
    int pLength = 0;
    while (pattern[pLength] != '\0')
    {
        pLength++;
    }
    

    char *gpuPattern;
    cudaMalloc(&gpuPattern, 20);
    cudaMemcpy(gpuPattern, pattern, 20 , cudaMemcpyHostToDevice);

    int *results = (int *)malloc(n*sizeof(int));
	memset(results, 0, n*sizeof(int));

    int *gpuResultLine;
    cudaMalloc( &gpuResultLine, sizeof(int)*n);
    cudaMemcpy(gpuResultLine, results,  sizeof(int)*n, cudaMemcpyHostToDevice);

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    float milliseconds = 0;
    cudaEventRecord(start,0);


    patternMatchingNaive <<<ceil(float(n)/BLOCKSIZE) ,BLOCKSIZE>>> (gpuInputText, n,iLength, gpuPattern, gpuResultLine, pLength, gpuLength);
    cudaDeviceSynchronize();

    cudaEventRecord(stop,0);
    cudaEventSynchronize(stop);
	cudaEventElapsedTime(&milliseconds, start, stop);
    printf("Time taken by function to execute is: %.6f ms\n", milliseconds);
    

    cudaMemcpy(results, gpuResultLine, sizeof(int)*n , cudaMemcpyDeviceToHost);


    char *fname = argv[2]; 
    FILE *fptr;
    fptr = fopen(fname,"w");
    
    //cout<<"Final";

    
    // for(int i=0;i<n;i++)
    // {
    //     cout<<results[i]<<" ";
    // }

   // cout<<endl;
    for(int i=0;i<=n;i++)
    {
        if(results[i] == 1)
        {
            for(int j = 0; j < iLength; j++)
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