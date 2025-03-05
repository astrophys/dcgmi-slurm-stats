/**************************************************************
 *  AUTHOR : Ali Snedden
 *  DATE   : 12/29/20
 *  LICENSE: GPL-3
 *  PURPOSE: To refresh myself on how using MPI. Let's do a 
 *           numerical integration using the trapezoidal rule.
 *  NOTES  :
 *      1. To compile and run : 
 *          $ ml load MVAPICH2/2.3.4
 *          $ mpicc mpi_integrate.c
 *          $ srun --ntasks=2 --nodes=2 --pty bash
 *          $ mpirun -np 2 ./a.out
 *
 *      2. To debug :
 *          $ ml load MVAPICH2/2.3.4
 *          $ mpicc -ggdb mpi_integrate.c
 *          $ mpirun -np 2 xterm -e gdb ./a.out
 *
 *  REFERNCES :
 *      1. MPI_Recv() : https://computing.llnl.gov/tutorials/mpi/man/MPI_Recv.txt
 *      2. MPI_Send() : https://hpc-tutorials.llnl.gov/mpi/MPI_appendix/MPI_Send.txt
 *      3. gethostname() : https://stackoverflow.com/a/22207175/4021436
 *      4. MPI tags   : https://stackoverflow.com/a/31471570/4021436
 *      4. Debugging  : https://stackoverflow.com/a/2364825/4021436
 *
 *
 *
 *************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <math.h>
#include <time.h>
#include <mpi.h>
#include "functions.h"
#include "cpu_mult.h"
#include "gpu_mult.h"
#include <cuda_runtime_api.h>
#include <iostream>
using namespace std;



int main(int argc, char * argv[])
{
    /***********************************************************/
    /****************** Variable Declaration *******************/
    /***********************************************************/
    bool verbose = false;
    char hostname[250];
    char errmsg[250];
    int i = 0;                  // Indice
    int taskID = -1;
    int ntasks = -1;
    int sendcode = 0;
    int recvcode = 0;
    int msgtag = 42;           // Message tag used, see : https://stackoverflow.com/a/31471570/4021436
    int destidx = -1;
    int recvidx = -1;
    hostname[249]='\0';
    // Only work with square matrices to make my life easier
    char * option = NULL;

    // There must be a better way in C++
    // Options :
    if(strcmp("--option", argv[1]) == 0){
        option = argv[2];
        printf("\toption = %s\n", option);
        fflush(stdout);
    }else{
        fprintf(stderr, "ERROR, Invalid options");
        return 1;
    }
    // Size of matrices

    /*************** Handle memory allocation *****************/
    // CPU only memory allocation
    if(strcmp("mpi_cpu", option) == 0 || strcmp("mpi_openmp_cpu", option) == 0 || 
       strcmp("mpi_openmp_cpu_opt", option) == 0){
        printf("option = %s",option);
    // GPU
    }else if(strcmp("mpi_gpu", option) == 0){
        printf("option = %s",option);
    }


    /******************* MPI Initializations ******************/
    //MPI_Status status; 
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &taskID);
    MPI_Comm_size(MPI_COMM_WORLD, &ntasks);
    // https://hpc-tutorials.llnl.gov/mpi/non_blocking/
    MPI_Request reqs[2];   // required variable for non-blocking calls
    //MPI_Status stats[2];   // required variable for Waitall routine
    gethostname(hostname, 1023);
    printf("Hello World from Task %i on %s\n", taskID,hostname);

    //initialize_matrix(recvA, dim, 0.0);
    //identity_matrix(sendA, dim, (float)(taskID+2));

    MPI_Finalize();
    printf("Goodbye from Task %i!\n",taskID);
    return 0;
}






