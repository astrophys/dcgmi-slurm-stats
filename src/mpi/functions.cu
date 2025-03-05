/**************************************************************
 *  AUTHOR : Ali Snedden
 *  DATE   : 02/21/24
 *  LICENSE: GPL-3
 *  PURPOSE: 
 *      This is a file with helper functions used by both cpu
 *       and gpu versions of this code
**************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <math.h>
#include <time.h>
#include <string.h>
#include <mpi.h>
#include <cuda_runtime_api.h>
#include <iostream>
#include "functions.h"
//using namespace nvcuda; 
using namespace std; 



/********************************************************
    ARGS:
        message : char array
    DESCRIPTION:
        Print out error, exit with error
    RETURN:
    DEBUG:
    NOTES: 
    FUTURE:
*******************************************************/
void exit_with_error(char * message){
    fprintf(stderr, "%s", message);
    fflush(stderr);
    MPI_Finalize();
    exit(1);
}


/**********************************
ARGS:
RETURN:
DESCRIPTION:
    Map 2D indices to 1D index
DEBUG:
    1. read_numpy_matrix() uses this function extensively.
       Directly compared output from read_numpy_matrix() with input
       and was IDENTICAL. This could not work if map_idx() didn't 
       function correctly.
FUTURE:
    1. Add error checking if not too expensive
***********************************/
int map_idx(int i, int j, int Ny){
    return (Ny * i + j);
}
// Visible to device
__device__ int d_map_idx(int i, int j, int Ny){
    return (Ny * i + j);
}


/**********************************
ARGS:
    array1D : 'flattened' 2D array as 1D
    N       : length of array
RETURN:
    N/A
DESCRIPTION:
    Prints 1D array and 3D coords
DEBUG:
    1. spot checked, it works
FUTURE:
***********************************/
void write_1D_array(float * array1D, int Nx, int Ny, FILE * f){
    int i = 0;
    int j = 0;
    int idx = 0;
    for(i=0; i<Nx; i++){
        for(j=0; j<Ny; j++){
            idx = map_idx(i,j,Ny);
            fprintf(f, "%*.1f ", 5, array1D[idx]);
        }
        fprintf(f, "\n");
    }
}


/**********************************
ARGS:
    array1D : 'flattened' 2D array as 1D
    N       : length of array
RETURN:
    N/A
DESCRIPTION:
    Prints 1D array and 1D coords
DEBUG:
    1. spot checked, it works
FUTURE:
***********************************/
void print_1D_array(float * array1D, int Nx, int Ny){
    int i = 0;
    int j = 0;
    int idx = 0;
    for(i=0; i<Nx; i++){
        for(j=0; j<Ny; j++){
            idx = map_idx(i,j,Ny);
            printf("%*.1f ", 5, array1D[idx]);
        }
        printf("\n");
    }
}


/********************************************************
    ARGS:
    DESCRIPTION:
    RETURN:
    DEBUG:
    NOTES: 
        1. Use 'flattened' 2D array
    FUTURE:
*******************************************************/
void initialize_matrix(float *A, int * dim, float value){
    for(int i=0; i<dim[0]; i++){
        for(int j=0; j<dim[1]; j++){
            //A[i*dim[0]+j] = value;
            A[map_idx(i,j,dim[1])] = value;
        }       
    }
}


/********************************************************
    ARGS:
        float * A    : 1D projection of 2D matrix
        int * dim    : x and y dimensions
        float factor : factor to multiply identity matrix by
    DESCRIPTION:
        Initialize identity matrix
    RETURN:
    DEBUG:
    NOTES: 
        1. Use 'flattened' 2D array
    FUTURE:
*******************************************************/
void identity_matrix(float *A, int * dim, float factor){
    for(int i=0; i<dim[0]; i++){
        for(int j=0; j<dim[1]; j++){
            //A[i*dim[0]+j] = value;
            if(i == j){
                A[map_idx(i,j,dim[1])] = 1.0 * factor;
            }else{
                A[map_idx(i,j,dim[1])] = 0;
            }
        }       
    }
}


/**********************************
ARGS:
    int * A : flattened 2D array
    int M   : number of Rows
    int N   : number of Cols
RETURN:
DESCRIPTION:
    Print 2D matrix. Must do it to on device b/c the halfs must
    be converted to ints __and__ that can __only__ be done on 
    the device. It is ridiculous, but I'm only using __one__ 
    thread to print the matrix.
DEBUG:
FUTURE:
***********************************
__global__ void print_matrix(half * A, int M, int N){
    int i = 0;
    int j = 0;
    int rIdx = blockIdx.x * blockDim.x + threadIdx.x;     //Row    index
    int cIdx = blockIdx.y * blockDim.y + threadIdx.y;     //Column index
    
    if(rIdx == 0 && cIdx == 0){
        for(i=0; i<M; i++){
            for(j=0; j<N; j++){
                printf("%*i", 3, __half2int_rd(A[d_map_idx(i,j,N)]));
            }
            printf("\n");
        }
    }
}*/


/**********************************
ARGS:
    int * A : flattened 2D array - Input array to convert
    half * B: flattened 2D array - Result
    int M   : number of Rows
    int N   : number of Cols
RETURN:
DESCRIPTION:
    Print 2D matrix
DEBUG:
FUTURE:
***********************************
__global__ void some_func(half * A){
    int startIdx = blockIdx.x * blockDim.x + threadIdx.x; // Index of current thread in block
    int stride   = blockDim.x * gridDim.x;                // Number of threads in the block
    //printf("%i : %i : %i \n", startIdx, stride, threadIdx.x);

    if(blockIdx.x == 0 && blockIdx.y == 0 && threadIdx.x ==1 && threadIdx.y == 1){
        printf("****************************\n\tblockDim.x = %i\n\tblockDim.y = %i\n\tgridDim.x = %i\n\tgridDim.y = %i\n\tblockIdx.x = %i\n\tblockIdx.y = %i\n\tthreadIdx.x = %i\n\tthreadIdx.y = %i\n",
               blockDim.x, blockDim.y, gridDim.x, gridDim.y, blockIdx.x, blockIdx.y,
               threadIdx.x, threadIdx.y);
    }
}*/




/**********************************
ARGS:
    int exitval : exit value
RETURN:
DESCRIPTION:
    Parses Command line options. Prints 'help' if requested.
DEBUG:
FUTURE:
    1. Learn an argparse like lib
***********************************/
void print_help(int exitval){
    printf("USAGE:\n\n");
    printf("mpiexec --np num mpi_matrix_mult --option option --size 10 --verbose true/false\n");
    printf("\tnum    = (int) number of MPI tasks\n");
    printf("\toption = (str) 'mpi_cpu', 'mpi_cache_opt', 'mpi_openmp_cpu' or\n");
    printf("\t         'mpi_gpu' or 'mpi_openmp_cpu_opt'\n");
    printf("\tsize    = (int) size of square matrices\n");
    printf("\tverbose = (str) either 'true' or 'false'\n");
    exit(exitval);
}


/**********************************
ARGS:
    char * argv[] : CL args to parse 
RETURN:
DESCRIPTION:
    Parses Command line options. Prints 'help' if requested.
DEBUG:
FUTURE:
    1. Learn an argparse like lib
***********************************/
char * parse_cl_options(int argc, char ** argv, int * size, bool * verbose){
    /*************************** Help Section ***************************/
    if(argv[1][1] == 'h' && argv[1][0] == '-'){
        print_help(0);
    }
    char * option = NULL;

    // There must be a better way in C++
    // Options : 
    if(strcmp("--option", argv[1]) == 0){
        option = argv[2];
        printf("\toption = %s\n", option);
        fflush(stdout);
    }else{
        print_help(1);
    }
    // Size of matrices
    if(strcmp("--size", argv[3]) == 0){
        *size = (int)atoi(argv[4]);
        printf("\tsize = %i\n", *size);
        fflush(stdout);
    }else{
        print_help(1);
    }
    printf("\tnargc = %i\n", argc);
    fflush(stdout);
    // Verbose
    if(argc > 5){
        if(strcmp("--verbose", argv[5]) == 0){
            if(strcmp(argv[6], "true") == 0){
                *verbose = true;
            }else if(strcmp(argv[6], "false") == 0){
                *verbose = false;
            }else{
                print_help(1);
            }
        }
    }else if(argc == 5){
        *verbose = false;
    }else{
        print_help(1);
    }
    printf("\tverbose = %i\n", *verbose);
    fflush(stdout);
    return(option);
}
