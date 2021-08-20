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

__global__ void kernelForLoop(int n, int length, char *gpuResultMatrix, char *gpuCharacters, int size, curandState *states) 
{
    unsigned id = blockIdx.x * blockDim.x + threadIdx.x;
    curand_init(id, id, 0, &states[id]);  // 	Initialize CURAND
   // printf("\nId %d", id);
    if(id < n)
    {
        for(int i =0; i<length; i++)
        {
                float x = curand_uniform (&states[id])*1000000;
                int modValue = int(x)%(size-1);
                gpuResultMatrix[id*length + i] = gpuCharacters[modValue];
            // printf(" gpuCharacters[modValue]: %c modval %d\n",gpuCharacters[modValue], modValue);
        }
    }
}


int main(int argc, char **argv)
{
    char *fname = argv[1]; 
    FILE *fptr;
    fptr = fopen(fname,"w");

    int n, length;
    printf("Enter how many lines you want to print\n");
    scanf("%d", &n);
    printf("Enter length of each string\n");
    scanf("%d", &length);
    fprintf(fptr ,"%d ", n); 
    fprintf(fptr ,"%d\n", length); 

    //n = 3;
    //length = 7;
    char *gpuResultMatrix;
    cudaMalloc( &gpuResultMatrix, sizeof(char)*n*length);
    
    char characters[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 ";
   //char characters[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"; 
   int size = sizeof(characters);

    cout<<"Size :"<<size<<endl;

    char *gpuCharacters;
    cudaMalloc(&gpuCharacters, size);
    cudaMemcpy(gpuCharacters, characters, size , cudaMemcpyHostToDevice);

    //Cuda Random states
    curandState *dev_random;
    cudaMalloc((void**)&dev_random, (float(n)/BLOCKSIZE)*BLOCKSIZE*sizeof(curandState));

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    float milliseconds = 0;
    cudaEventRecord(start,0);


    kernelForLoop<<<ceil(float(n)/BLOCKSIZE) ,BLOCKSIZE>>> ( n, length, gpuResultMatrix, gpuCharacters, size, dev_random);
    cudaDeviceSynchronize();


    char *results = (char *)malloc(n*length*sizeof(char));
    cudaMemcpy(results, gpuResultMatrix, sizeof(char)*n*length , cudaMemcpyDeviceToHost);

         
    for(int i=0;i<n;i++)
    {
        for(int j = 0; j < length; j++)
            fprintf(fptr ,"%c", results[i*length + j] ); 
        fprintf(fptr,"\n"); 
    }
   // fprintf(fptr,"\n"); 

    cudaEventRecord(stop,0);
    cudaEventSynchronize(stop);
	cudaEventElapsedTime(&milliseconds, start, stop);
    printf("Time taken by function to execute is: %.6f ms\n", milliseconds);
    

    return 0;
}