#include <cuda.h>
#include<bits/stdc++.h>
#include <thrust/device_vector.h>
#include <thrust/sort.h>
#include <thrust/reduce.h>
#include <thrust/iterator/constant_iterator.h>
#include <iostream>
#include <thrust/iterator/zip_iterator.h>
#define BLOCKSIZE 32
//using namespace std;
//Limitation : Tested only for fixed length strings & CAPITAL Letters


__global__ void loadPrefixes(char *gpuInputText, int offset, int iLength, char *gKey1, char *gKey2, int n, int *indexArray)
{
    unsigned id = blockIdx.x * blockDim.x + threadIdx.x;
    if(id < n)
    {
        if(offset < iLength && (offset + 1) < iLength )
            {
                gKey1[id] = gpuInputText[(indexArray[id])*iLength + offset];
                gKey2[id] = gpuInputText[(indexArray[id])*iLength + offset + 1];
            }
    }
}

__global__ void findSingleton(int *gSingletonElement, int *gSegId, char *gKey1, char *gKey2, int *gIndexArray,int n, int *gOutputIndex)
{
    unsigned id = blockIdx.x * blockDim.x + threadIdx.x;
    if(id > 0 && id < n-1)
    {
        if(gKey1[id] == gKey1[id-1] && gKey2[id] == gKey2[id-1] && gSegId[id] == gSegId[id-1]) 
        {
            if(gSingletonElement[id] != 1)
            {
                gSingletonElement[id] = 0;
            }
                
            return;
        }
        if(gKey1[id] == gKey1[id+1] && gKey2[id] == gKey2[id+1] && gSegId[id] == gSegId[id+1]) 
        {
            if(gSingletonElement[id] != 1)
            {
                gSingletonElement[id] = 0;
            }
            return;
        }
        else
        {
            gOutputIndex[id] = gIndexArray[id];
            gSingletonElement[id] = 1;
        }
    }
    else if(id == 0)
    {
        if(gKey1[id] != gKey1[id+1] || gKey2[id] != gKey2[id+1] )
        {
            gOutputIndex[id] = gIndexArray[id];
            gSingletonElement[id] = 1;
        }
        else
        {
            if(gSingletonElement[id] != 1)
            {
                gSingletonElement[id] = 0;
            }
                
        }

    }
    else if(id == n-1)
    {
        if(gKey1[id] != gKey1[id-1] || gKey2[id] != gKey2[id-1])
        {
            gOutputIndex[id] = gIndexArray[id];
            gSingletonElement[id] = 1;
        }
        else
        {
            if(gSingletonElement[id] != 1)
            {
                gSingletonElement[id] = 0;
            }
                
        }
    }
}

int main(int argc, char **argv)
{
    int n, iLength;
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

    char inputText[iLength*n + n];

    for (int i = 0; i < n; i++)
    {
        for(int j = 0; j <= iLength; j++)
        {
            fscanf(filePointer, "%c", &inputText[i*iLength + j]);
        }
    }

    // for (size_t i = 0; i < n; i++)
    // {
    //     for (size_t j = 0; j < iLength; j++)
    //     {
    //         printf("%c", inputText[i*iLength + j]);
    //     }
    //     printf("\n");
    // }

    thrust::device_vector<int> indexArray(n);
    thrust::sequence (indexArray.begin(), indexArray.end());

    char *gpuInputText;
    cudaMalloc(&gpuInputText, iLength*n*sizeof(char));
    cudaMemcpy(gpuInputText, inputText, iLength*n*sizeof(char), cudaMemcpyHostToDevice);

    //Initial Setup
    thrust::device_vector<int> singletonElement(n, 0);
    thrust::device_vector<int> segId(n, 0);
    thrust::device_vector<char> k1(n);
    thrust::device_vector<char> k2(n);
    thrust::device_vector<int> outputIndex(n, 0);
    
    char *hk1 = (char *)malloc(n*sizeof(char)); 
    char *hk2 = (char *)malloc(n*sizeof(char)); 
    int *hSingletonElement = (int *)malloc(n*sizeof(int)); 
    int *hSegId = (int *)malloc(n*sizeof(int)); 
    int *hOutputIndex = (int *)malloc(n*sizeof(int));
    //Load prefix
    //Check offset < iLength
    int offset = 0;

        int *gSingletonElement = thrust::raw_pointer_cast(&singletonElement[0]);
        char *gKey1 = thrust::raw_pointer_cast(&k1[0]);
        char *gKey2 = thrust::raw_pointer_cast(&k2[0]);
        int *gIndexArray = thrust::raw_pointer_cast(&indexArray[0]);
        int *gSegId = thrust::raw_pointer_cast(&segId[0]);
        int *gOutputIndex = thrust::raw_pointer_cast(&outputIndex[0]);


    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    float milliseconds = 0;
    cudaEventRecord(start,0);


    // for (int i = 0; i < n; i++)
    // {
    //   k1[i] = gpuInputText[i*iLength + 0];
    //   k2[i] = gpuInputText[i*iLength + 1];
    // }
    
    loadPrefixes<<<ceil(float(n)/BLOCKSIZE) ,BLOCKSIZE>>>(gpuInputText, offset, iLength, gKey1, gKey2, n, gIndexArray);
    cudaDeviceSynchronize();
    int numberOfSingletonElements = 0;
    int itr = 0;

    do
    {
        itr++;
        thrust::sort_by_key(thrust::make_zip_iterator(thrust::make_tuple(segId.begin(), k1.begin(), k2.begin())), 
                            thrust::make_zip_iterator(thrust::make_tuple(segId.end(), k1.end(), k2.end())), 
                            indexArray.begin());
        
        // std::cout<<"After Sorting"<<std::endl;
        // for(int i = 0; i < n; i++)
        // {
        //     std::cout<<segId[i]<<" "<< k1[i]<<" "<<k2[i]<<" "<<indexArray[i]<<" "<<std::endl;
        // }

        findSingleton <<<ceil(float(n)/BLOCKSIZE) ,BLOCKSIZE>>>(gSingletonElement, gSegId, gKey1, gKey2, gIndexArray, n, gOutputIndex);
        cudaDeviceSynchronize();

       // std::cout<<"Flag"<<std::endl;

        numberOfSingletonElements = 0;

        numberOfSingletonElements = thrust::count(thrust::device, singletonElement.begin(),singletonElement.end(), 1);
       
        // for(int i = 0; i < n; i++)
        // {
        //     if(singletonElement[i] == 1)
        //     {
        //        // numberOfSingletonElements++;
        //     }

        //     std::cout<<singletonElement[i]<<"  ";
        // }
        // std::cout<<""<<std::endl;

        // std::cout<<"OutpUt array"<<std::endl;

        // for(int i = 0; i < n; i++)
        // {
        //     std::cout<<outputIndex[i]<<"  ";
        // }
        // std::cout<<""<<std::endl;

        //Generate Segment IDs sequentially
        int cnt = 0;

        cudaMemcpy(hk1, gKey1, sizeof(char)*n , cudaMemcpyDeviceToHost);
        cudaMemcpy(hk2, gKey2, sizeof(char)*n , cudaMemcpyDeviceToHost);
        cudaMemcpy(hSingletonElement, gSingletonElement, sizeof(int)*n , cudaMemcpyDeviceToHost);
        cudaMemcpy(hSegId, gSegId, sizeof(int)*n , cudaMemcpyDeviceToHost);

        // segId[0] = cnt;
        // for(int i = 1; i < n; i++)
        // {
        //     if(singletonElement[i] == 1)
        //     {
        //         cnt++;
        //         segId[i] = cnt;
        //     }
        //     else if(singletonElement[i] == 0 && (k1[i] == k1[i-1] && k2[i] == k2[i-1]))
        //     {
        //         segId[i] = segId[i-1]; 
        //     }
        //     else if(singletonElement[i] == 0 && (k1[i] != k1[i-1] || k2[i] != k2[i-1]))
        //     {
        //         cnt++;
        //         segId[i] = cnt;
        //     }   
        // }

        hSegId[0] = cnt;
        for(int i = 1; i < n; i++)
        {
            if(hSingletonElement[i] == 1)
            {
                cnt++;
                hSegId[i] = cnt;
            }
            else if(hSingletonElement[i] == 0 && (hk1[i] == hk1[i-1] && hk2[i] == hk2[i-1]))
            {
                hSegId[i] = hSegId[i-1]; 
            }
            else if(hSingletonElement[i] == 0 && (hk1[i] != hk1[i-1] || hk2[i] != hk2[i-1]))
            {
                cnt++;
                hSegId[i] = cnt;
            }   
        }
        cudaMemcpy(gSegId, hSegId, sizeof(int)*n , cudaMemcpyHostToDevice);

        // std::cout<<"Segments"<<std::endl;

        // for(int i = 0; i < n; i++)
        // {
        //     std::cout<<segId[i]<<"  ";
        // }
        // std::cout<<""<<std::endl;

        offset = offset + 2;
       
        //Load Prefixes
        // for (int i = 0; i < n; i++)
        // {
        //     if(offset < iLength && (offset + 1) < iLength )
        //     {
        //         k1[i] = gpuInputText[i*iLength + offset];
        //         k2[i] = gpuInputText[i*iLength + offset + 1];
        //     }
          
        // }
        loadPrefixes<<<ceil(float(n)/BLOCKSIZE) ,BLOCKSIZE>>>(gpuInputText, offset, iLength, gKey1, gKey2, n, gIndexArray);
        cudaDeviceSynchronize();

        // std::cout<<"Prefix Loaded"<<std::endl;

        // for(int i = 0; i < n; i++)
        // {
        //     std::cout<<segId[i]<<" "<< k1[i]<<" "<<k2[i]<<" "<<indexArray[i]<<" "<<std::endl;
        // }
        // std::cout<<"Iteration "<<itr<<std::endl;
        // std::cout<<"Nuber of singlton Elements "<<numberOfSingletonElements<<std::endl;
        // std::cout<<"Offset "<<offset<<std::endl;

    }while( numberOfSingletonElements != n);
    
    cudaDeviceSynchronize();

    cudaEventRecord(stop,0);
    cudaEventSynchronize(stop);
	cudaEventElapsedTime(&milliseconds, start, stop);
    printf("Time taken by function to execute is: %.6f ms\n", milliseconds);


        // std::cout<<"After All iteration OutpUt array"<<std::endl;

        // for(int i = 0; i < n; i++)
        // {
        //     std::cout<<outputIndex[i]<<"  ";
        // }
        // std::cout<<""<<std::endl;

        // std::cout<<"Final OutpUt"<<std::endl;
        cudaMemcpy(hOutputIndex, gOutputIndex, sizeof(int)*n , cudaMemcpyDeviceToHost);

        char *fname = argv[2]; 
        FILE *fptr;
        fptr = fopen(fname,"w");

        for(int i = 0; i < n; i++)
        {
            for(int j = 0; j < iLength; j++)
            {
                fprintf(fptr, "%c", inputText[hOutputIndex[i]*iLength + j]);
               // std::cout<< inputText[outputIndex[i]*iLength + j]<<"";
            }
            fprintf(fptr,"\n"); 
        }
        fprintf(fptr,"\n"); 

    return 0;
}

