/**************************************************************
 *  AUTHOR : Ali Snedden
 *  DATE   : 02/21/24
 *  LICENSE: GPL-3
 *  PURPOSE: 
**************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <math.h>
#include <time.h>
#include <mpi.h>
#include <cuda_runtime_api.h>
#include "functions.h"


/********************************************************
    ARGS:
        A : 'flattened' 2d matrix
        B : 'flattened' 2d matrix
        dimA : gives x & y dims
        dimB : gives x & y dims
        dimAB: pointer modified to return size of new matrix

    DESCRIPTION:
        Multiply A*B : Check dims. Expect only 2 dimensions
        for dimA and dimB.
    RETURN:
    DEBUG:
    NOTES: 
        1. blockDim.x  : number of threads in each block
           blockIdx.x  : index of current block
           threadIdx.x : 
        2. Error Check - not possible on device code
    FUTURE:
*******************************************************/
__global__ void gpu_matrix_multiply(float * A, float * B, int * dimA, int * dimB,
                                float * AB, int * dimAB, bool verbose)
{
    int j = 0;          // Iterate over elements, do dot product
    int startIdx = blockIdx.x * blockDim.x + threadIdx.x; // Index of current thread in block
    int stride   = blockDim.x * gridDim.x;                // Number of threads in the block
    int ai = 0;         // Index iterating over rows in A
    int bj = 0;         // Index iterating over columns in B
    float sum = 0;
    //printf("%i %i : [%i %i] %i %i\n", startIdx, stride, threadIdx.x, blockIdx.x, blockDim.x, gridDim.x);
    if(blockIdx.x == 0 && threadIdx.x ==0 && verbose == true){
        printf("****************************\n\tblockDim.x = %i\n\tgridDim.x = %i\n",
               blockDim.x, gridDim.x);
    }

    // if(dimA[1] != dimB[0]){
    //     char errStr[] = "ERROR!! dimension mismatch\n";
    //     //sprintf(errStr, "ERROR!! dimension mismatch, %i != %i", dimA[1], dimB[0]);
    //     d_exit_with_error(errStr);
    // }
    
    // Grid-stride loop
    for(ai=startIdx; ai<dimA[0]; ai+=stride){
        //printf("[%i %i] : %i : dimA[0] = %i\n", threadIdx.x, blockIdx.x, ai, dimA[0]);
        for(bj=0; bj<dimB[1]; bj++){
            sum = 0;
            for(j=0; j<dimA[1]; j++){
                //printf("\t[%i, %i] x [%i, %i]\n", ai, j, j, bj);  // EXPENSIVE!! increases runtime 100x

                sum += A[d_map_idx(ai, j, dimA[1])] * B[d_map_idx(j, bj, dimB[1])];
                AB[d_map_idx(ai,bj,dimB[1])] = sum;
            }
            //printf("\n");
        }
    }
}




