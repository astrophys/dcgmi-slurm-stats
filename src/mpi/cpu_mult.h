#ifndef CPU_MULT
#define CPU_MULT
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
float * cpu_matrix_multiply(float * A, float * B, int * dimA, int * dimB,
                            int * dimAB);
#endif
