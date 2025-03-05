/**************************************************************
 *  AUTHOR : Ali Snedden
 *  DATE   : 02/21/24
 *  LICENSE: GPL-3
 *  PURPOSE: 
**************************************************************/
#ifndef FUNCTIONS
#define FUNCTIONS


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
void exit_with_error(char * message);


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
void write_1D_array(float * array1D, int Nx, int Ny, FILE * f);


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
void print_1D_array(float * array1D, int Nx, int Ny);


/********************************************************
    ARGS:
    DESCRIPTION:
    RETURN:
    DEBUG:
    NOTES: 
        1. Use 'flattened' 2D array
    FUTURE:
*******************************************************/
void initialize_matrix(float *A, int * dim, float value);


/********************************************************
    ARGS:
        float * A : 1D projection of 2D matrix
        int * dim : x and y dimensions
    DESCRIPTION:
        Initialize identity matrix
    RETURN:
    DEBUG:
    NOTES: 
        1. Use 'flattened' 2D array
    FUTURE:
*******************************************************/
void identity_matrix(float *A, int * dim, float factor);


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
int map_idx(int i, int j, int Ny);
// Visible to device
extern __device__ int d_map_idx(int i, int j, int Ny);

/**********************************
ARGS:
    char * argv[] : CL args to parse 
    char * option : e.g. 'mpi_cpu', etc
    int * size    : size of square matrices, e.g. size x size matrix
    bool * verbose: should we pring verbose option or not?
RETURN:
DESCRIPTION:
    Parses Command line options. Prints 'help' if requested.
DEBUG:
FUTURE:
***********************************/
char * parse_cl_options(char ** argv, int * size, bool * verbose);


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
void print_help(int exitval);


// This is C++ code - from stackoverflow :
/********************************************************
    ARGS:
        cudaError_t code
        const char* file : 
        int line :
    DESCRIPTION:
        Uses macro and inline function b/c it is important to preserve the
        file and line number in the error printing.
    RETURN:
    DEBUG:
    NOTES: 
        1. https://stackoverflow.com/q/14038589 
        2. https://stackoverflow.com/a/40766760 # force inline funcs into every file
    FUTURE:
*******************************************************/
#define gpuErrChk(ans) { gpuAssert((ans), __FILE__, __LINE__); }
inline void gpuAssert(cudaError_t code, const char *file, int line, bool abort=true)
{
   if (code != cudaSuccess) 
   {
      fprintf(stderr,"GPUassert: %s %s : %d\n", cudaGetErrorString(code), file, line);
      if (abort) exit(code);
   }
}

#endif
