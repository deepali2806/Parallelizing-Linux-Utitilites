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

__global__ void naiveStringSort(char *gpuInputText, int i, int n, int *gpuIndex, int iLength, int *gpuLength)
{
    unsigned id = blockIdx.x * blockDim.x + threadIdx.x;
    if(id < n/2)
	{
		//Even Phase
		if((i%2 == 0) && ((id*2+1)< n))
		{
           // printf("\nEven Phase");
            //String comparing
            int flag = 0, s1 = gpuIndex[id*2], s2 = gpuIndex[id*2 + 1];
            //printf("S1 %d S2 %d", s1, s2);
            int m = gpuLength[s1];
            int n = gpuLength[s2];
           // printf("\nM %d and N %d", m, n);
            if(m == n)
            {
               // printf("\nM == n");

                for(int i = 0; i < m; i++)
                {
                 //   printf("\nId %d %c %c", id, gpuInputText[s1*iLength + i], gpuInputText[s2*iLength + i]);

                    if(gpuInputText[s1*iLength + i] <= 122 && 97 <= gpuInputText[s1*iLength + i] )
                        {
                            gpuInputText[s1*iLength + i] = gpuInputText[s1*iLength + i]- 97 + 65;
                        }
                    if(gpuInputText[s2*iLength + i] <= 122 && 97 <= gpuInputText[s2*iLength + i] )
                        {
                            gpuInputText[s2*iLength + i] = gpuInputText[s2*iLength + i]- 97 + 65;
                        }
    
                 //   printf("\nBefore Comparing %c and %c flag %d", gpuInputText[s1*iLength + i], gpuInputText[s2*iLength + i], flag);
                    if(gpuInputText[s1*iLength + i] != gpuInputText[s2*iLength + i])
                    {
                        if(gpuInputText[s1*iLength + i] > gpuInputText[s2*iLength + i])
                        {
                            flag = 1;
                            //printf("\nInside inequality Comparing %c and %c flag %d", gpuInputText[s1*iLength + i], gpuInputText[s2*iLength + i], flag);
    
                            break;   
                        }
                        else
                        {
                            //printf("\nInside inequality else Comparing %c and %c flag %d", gpuInputText[s1*iLength + i], gpuInputText[s2*iLength + i], flag);
                            break;
                        }
                    }
                   // printf("\nAfter Comparing %c and %c flag %d", gpuInputText[s1*iLength + i], gpuInputText[s2*iLength + i], flag);
    
                }
            }
            else if(m > n)
            {
                int flag1 = 0;
              //  printf("\nM > n");
                for(int i = 0; i < n; i++)
                {
               //     printf("\nId %d %c %c", id, gpuInputText[s1*iLength + i], gpuInputText[s2*iLength + i]);

                    if(gpuInputText[s1*iLength + i] <= 122 && 97 <= gpuInputText[s1*iLength + i] )
                        {
                            gpuInputText[s1*iLength + i] = gpuInputText[s1*iLength + i]- 97 + 65;
                        }
                        if(gpuInputText[s2*iLength + i] <= 122 && 97 <= gpuInputText[s2*iLength + i] )
                        {
                            gpuInputText[s2*iLength + i] = gpuInputText[s2*iLength + i]- 97 + 65;
                        }
    
               //     printf("\nBefore Comparing %c and %c flag %d", gpuInputText[s1*iLength + i], gpuInputText[s2*iLength + i], flag);
                    if(gpuInputText[s1*iLength + i] != gpuInputText[s2*iLength + i])
                    {
                        if(gpuInputText[s1*iLength + i] > gpuInputText[s2*iLength + i])
                        {
                            flag = 1;
                 //           printf("\nInside inequality Comparing %c and %c flag %d", gpuInputText[s1*iLength + i], gpuInputText[s2*iLength + i], flag);
    
                            break;   
                        }
                        else
                        {
                            flag1 = 1;
                 //           printf("\nInside inequality else Comparing %c and %c flag %d", gpuInputText[s1*iLength + i], gpuInputText[s2*iLength + i], flag);
                            break;
                        }
                    }
                   //printf("\nAfter Comparing %c and %c flag %d", gpuInputText[s1*iLength + i], gpuInputText[s2*iLength + i], flag);
    
                }

                if(flag1 == 0)
                {
                    flag = 1;
                }

            }
            else if(m < n)
            {
                //printf("\nM < n");

                for(int i = 0; i < m; i++)
                {
                 //   printf("\nId %d %c %c", id, gpuInputText[s1*iLength + i], gpuInputText[s2*iLength + i]);

                    if(gpuInputText[s1*iLength + i] <= 122 && 97 <= gpuInputText[s1*iLength + i] )
                        {
                            gpuInputText[s1*iLength + i] = gpuInputText[s1*iLength + i]- 97 + 65;
                        }
                        if(gpuInputText[s2*iLength + i] <= 122 && 97 <= gpuInputText[s2*iLength + i] )
                        {
                            gpuInputText[s2*iLength + i] = gpuInputText[s2*iLength + i]- 97 + 65;
                        }
    
                 //   printf("\nBefore Comparing %c and %c flag %d", gpuInputText[s1*iLength + i], gpuInputText[s2*iLength + i], flag);
                    if(gpuInputText[s1*iLength + i] != gpuInputText[s2*iLength + i])
                    {
                        if(gpuInputText[s1*iLength + i] > gpuInputText[s2*iLength + i])
                        {
                            flag = 1;
                  //          printf("\nInside inequality Comparing %c and %c flag %d", gpuInputText[s1*iLength + i], gpuInputText[s2*iLength + i], flag);
    
                            break;   
                        }
                        else
                        {
                   //         printf("\nInside inequality else Comparing %c and %c flag %d", gpuInputText[s1*iLength + i], gpuInputText[s2*iLength + i], flag);
                            break;
                        }
                    }
                   // printf("\nAfter Comparing %c and %c flag %d", gpuInputText[s1*iLength + i], gpuInputText[s2*iLength + i], flag);
    
                }
            }


           


			if(flag == 1)
			{
               // printf("\nSwapping");
				int temp=gpuIndex[id*2];
				gpuIndex[id*2]=gpuIndex[id*2+1];
				gpuIndex[id*2+1]=temp;	
                // for(int i =0; i < n; i++)
                //     printf("%d ",gpuIndex[i]);			
			}
		}
		
		//Odd Phase
		if((i%2 == 1) && ((id*2+2)< n))
		{
            //printf("\nOdd Phase");

            int flag = 0, s1 = gpuIndex[id*2+1], s2 = gpuIndex[id*2 + 2];
           // printf("S1 %d S2 %d", s1, s2);
           int m = gpuLength[s1];
           int n = gpuLength[s2];
          // printf("\nM %d and N %d", m, n);

           if(m == n)
           {
           // printf("\nM == n");

               for(int i = 0; i < m; i++)
               {
             //   printf("\nId %d %c %c", id, gpuInputText[s1*iLength + i], gpuInputText[s2*iLength + i]);

                   if(gpuInputText[s1*iLength + i] <= 122 && 97 <= gpuInputText[s1*iLength + i] )
                       {
                           gpuInputText[s1*iLength + i] = gpuInputText[s1*iLength + i]- 97 + 65;
                       }
                       if(gpuInputText[s2*iLength + i] <= 122 && 97 <= gpuInputText[s2*iLength + i] )
                        {
                            gpuInputText[s2*iLength + i] = gpuInputText[s2*iLength + i]- 97 + 65;
                        }
   
               //    printf("\nBefore Comparing %c and %c flag %d", gpuInputText[s1*iLength + i], gpuInputText[s2*iLength + i], flag);
                   if(gpuInputText[s1*iLength + i] != gpuInputText[s2*iLength + i])
                   {
                       if(gpuInputText[s1*iLength + i] > gpuInputText[s2*iLength + i])
                       {
                           flag = 1;
                 //          printf("\nInside inequality Comparing %c and %c flag %d", gpuInputText[s1*iLength + i], gpuInputText[s2*iLength + i], flag);
   
                           break;   
                       }
                       else
                       {
                  //         printf("\nInside inequality else Comparing %c and %c flag %d", gpuInputText[s1*iLength + i], gpuInputText[s2*iLength + i], flag);
                           break;
                       }
                   }
                //   printf("\nAfter Comparing %c and %c flag %d", gpuInputText[s1*iLength + i], gpuInputText[s2*iLength + i], flag);
   
               }
           }
           else if(m > n)
           {
               int flag1 = 0;
          //  printf("\nM > n");

               for(int i = 0; i < n; i++)
               {
          //      printf("\nId %d %c %c", id, gpuInputText[s1*iLength + i], gpuInputText[s2*iLength + i]);

                   if(gpuInputText[s1*iLength + i] <= 122 && 97 <= gpuInputText[s1*iLength + i] )
                       {
                           gpuInputText[s1*iLength + i] = gpuInputText[s1*iLength + i]- 97 + 65;
                       }
                       if(gpuInputText[s2*iLength + i] <= 122 && 97 <= gpuInputText[s2*iLength + i] )
                        {
                            gpuInputText[s2*iLength + i] = gpuInputText[s2*iLength + i]- 97 + 65;
                        }
   
            //       printf("\nBefore Comparing %c and %c flag %d", gpuInputText[s1*iLength + i], gpuInputText[s2*iLength + i], flag);
                   if(gpuInputText[s1*iLength + i] != gpuInputText[s2*iLength + i])
                   {
                       if(gpuInputText[s1*iLength + i] > gpuInputText[s2*iLength + i])
                       {
                           flag = 1;
              //             printf("\nInside inequality Comparing %c and %c flag %d", gpuInputText[s1*iLength + i], gpuInputText[s2*iLength + i], flag);
   
                           break;   
                       }
                       else
                       {
                           flag1 = 1;
               //            printf("\nInside inequality else Comparing %c and %c flag %d", gpuInputText[s1*iLength + i], gpuInputText[s2*iLength + i], flag);
                           break;
                       }
                   }
               //    printf("\nAfter Comparing %c and %c flag %d", gpuInputText[s1*iLength + i], gpuInputText[s2*iLength + i], flag);
   
               }

               if(flag1 == 0)
               {
                   flag = 1;
               }

           }
           else if(m < n)
           {
           // printf("\nM < n");

               for(int i = 0; i < m; i++)
               {
             //   printf("\nId %d %c %c", id, gpuInputText[s1*iLength + i], gpuInputText[s2*iLength + i]);

                   if(gpuInputText[s1*iLength + i] <= 122 && 97 <= gpuInputText[s1*iLength + i] )
                       {
                           gpuInputText[s1*iLength + i] = gpuInputText[s1*iLength + i]- 97 + 65;
                       }
                       if(gpuInputText[s2*iLength + i] <= 122 && 97 <= gpuInputText[s2*iLength + i] )
                       {
                           gpuInputText[s2*iLength + i] = gpuInputText[s2*iLength + i]- 97 + 65;
                       }
   
              ///     printf("\nBefore Comparing %c and %c flag %d", gpuInputText[s1*iLength + i], gpuInputText[s2*iLength + i], flag);
                   if(gpuInputText[s1*iLength + i] != gpuInputText[s2*iLength + i])
                   {
                       if(gpuInputText[s1*iLength + i] > gpuInputText[s2*iLength + i])
                       {
                           flag = 1;
              //             printf("\nInside inequality Comparing %c and %c flag %d", gpuInputText[s1*iLength + i], gpuInputText[s2*iLength + i], flag);
   
                           break;   
                       }
                       else
                       {
                //           printf("\nInside inequality else Comparing %c and %c flag %d", gpuInputText[s1*iLength + i], gpuInputText[s2*iLength + i], flag);
                           break;
                       }
                   }
                //   printf("\nAfter Comparing %c and %c flag %d", gpuInputText[s1*iLength + i], gpuInputText[s2*iLength + i], flag);
   
               }
           }
           


			if(flag == 1)			
            {
                //printf("\nSwapping");
				int temp=gpuIndex[id*2 + 1];
				gpuIndex[id*2+1]=gpuIndex[id*2+2];
				gpuIndex[id*2+2]=temp;
                // for(int i =0; i < n; i++)
                //     printf("%d ",gpuIndex[i]);

			}
		}
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
  
    int *index = (int *)malloc(n*sizeof(int)); 
	for(int i = 0; i < n; i++)
	{
		index[i] = i;
	}	
	
    int *gpuIndex;
    cudaMalloc( &gpuIndex, sizeof(int) * (n) );
	cudaMemcpy(gpuIndex, index, sizeof(int) * (n), cudaMemcpyHostToDevice);

    int *gpuLength;
    cudaMalloc( &gpuLength, sizeof(int)*n);
    cudaMemcpy(gpuLength, length,  sizeof(int)*n, cudaMemcpyHostToDevice);

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    float milliseconds = 0;
    cudaEventRecord(start,0);

    for(int i = 0; i < n; i++)
    {
        naiveStringSort <<<ceil(float(n)/BLOCKSIZE) ,BLOCKSIZE >>> (gpuInputText, i, n, gpuIndex, iLength, gpuLength);
    }
    
    cudaDeviceSynchronize();

    cudaEventRecord(stop,0);
    cudaEventSynchronize(stop);
	cudaEventElapsedTime(&milliseconds, start, stop);
    printf("Time taken by function to execute is: %.6f ms\n", milliseconds);

    cudaMemcpy(index, gpuIndex, sizeof(int)*n , cudaMemcpyDeviceToHost);


    char *fname = argv[2]; 
    FILE *fptr;
    fptr = fopen(fname,"w");
    
    // cout<<"Final";

    // for(int i=0;i<n;i++)
    // {
    //     cout<<index[i]<<" ";
    // }

    // cout<<endl;


    for (size_t i = 0; i < n; i++)
	{
	    for (size_t j = 0; j <= iLength; j++)
	    {
	    	if(inputText[(index[i])*iLength + j] != '\0')
			    fprintf(fptr, "%c", inputText[(index[i])*iLength + j]);
            else
            {
               // printf("Null");
                break;
            }
	    }
        fprintf(fptr,"\n"); 
    }

       

    return 0;
}