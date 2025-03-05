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
#include "functions.h"
#include <cuda_runtime_api.h>


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
        1. created code, matrix_generator.py, that multiplies two matrices and
           saves the input and output to a file. I read in data/A.txt, data/B.txt
           and used this function to multiply the matrices. Printed the output and 
           compared to data/AB.txt. It was IDENTICAL. 
           --> This function works!
    NOTES: 
    FUTURE:
*******************************************************/
float * cpu_matrix_multiply(float * A, float * B, int * dimA, int * dimB, int * dimAB)
{
    int j = 0;          // Iterate over elements, do dot product
    int ai = 0;         // Index iterating over rows in A
    int bj = 0;         // Index iterating over columns in B
    float sum = 0;
    char errStr[500];
    float * result = (float *)malloc(sizeof(float) * dimA[0] * dimB[1]);

    // Error Check
    if(dimA[1] != dimB[0]){
        sprintf(errStr, "ERROR!! dimension mismatch, %i != %i", dimA[1], dimB[0]);
        exit_with_error(errStr);
    }

    for(ai=0; ai<dimA[0]; ai++){
        for(bj=0; bj<dimB[1]; bj++){
            sum = 0;
            for(j=0; j<dimA[1]; j++){
                //printf("%.0f * %0.f\n", A[map_idx(ai, j, dimA[1])],
                //        B[map_idx(j, bj, dimB[1])]);

                sum += A[map_idx(ai, j, dimA[1])] * B[map_idx(j, bj, dimB[1])];
                result[map_idx(ai,bj,dimB[1])] = sum;
            }
            //printf("\n");
        }
    }
    dimAB[0] = dimA[0];
    dimAB[1] = dimB[1];
    return result;
}




