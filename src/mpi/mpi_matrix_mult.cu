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
    //printf("%s\n", option);
    bool verbose;
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
    int size;
    //bool verbose = false;
    char * option = parse_cl_options(argc, argv, &size, &verbose);
    int nx = size;
    int ny = size;
    int N = nx * ny;
    int * dim = NULL; //[]   = {nx, ny};
    float * sendA = NULL;
    float * recvA = NULL;
    float * resA = NULL; // result of mult sendA and recvA


    /*************** Handle memory allocation *****************/
    // CPU only memory allocation
    if(strcmp("mpi_cpu", option) == 0 || strcmp("mpi_openmp_cpu", option) == 0 || 
       strcmp("mpi_openmp_cpu_opt", option) == 0){
        dim = (int *)malloc(sizeof(int) * 2);
        sendA = (float *)malloc(sizeof(float) * nx * ny); // send to task + 1
        recvA = (float *)malloc(sizeof(float) * nx * ny); // receive from task - 1
        resA = NULL; // result of mult sendA and recvA

    // GPU
    }else if(strcmp("mpi_gpu", option) == 0){
        gpuErrChk(cudaMallocManaged(&dim, 2 * sizeof(float)));
        dim[0] = nx;
        dim[1] = ny;
        gpuErrChk(cudaMallocManaged(&sendA, dim[0] * dim[1] * sizeof(float)));
        gpuErrChk(cudaMallocManaged(&recvA, dim[0] * dim[1] * sizeof(float)));
        gpuErrChk(cudaMallocManaged(&resA, dim[0] * dim[1] * sizeof(float)));
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
    fflush(stdout);

    initialize_matrix(recvA, dim, 0.0);
    identity_matrix(sendA, dim, (float)(taskID+2));



    /***********************************************************/
    /****************** Main Loop - use MPI ********************/
    /***********************************************************/
    printf("Starting Transfer...\n");
    // Transfer 1GB - 1000 times
    for(i=0; i<1000; i++){
        // Print progress
        if(taskID == 0 && i%100 == 0){
            printf("\ti = %i\n", i);
            fflush(stdout);
        }
        if(verbose == true && i%100 == 0){
            printf("\tTask %i : destidx = %i, recvidx = %i\n", taskID, destidx, recvidx);
            fflush(stdout);
        }

        // Round Robin strategy 0 -> 1 -> 2 -> ... -> N -> 0
        // destination...
        if(taskID == ntasks - 1){
            destidx = 0;
        }else{
            destidx = taskID + 1;
        }
        // recieve
        if(taskID == 0){
            recvidx = ntasks - 1;
        }else{
            recvidx = taskID - 1;
        }

        // Non-blocking, needed for round-robin
        sendcode = MPI_Isend(sendA, N, MPI_FLOAT, destidx, msgtag, MPI_COMM_WORLD,
                             &reqs[0]);
        recvcode = MPI_Irecv(recvA, N, MPI_FLOAT, recvidx, msgtag, MPI_COMM_WORLD,
                             &reqs[1]);

        // Ensure every task completes
        MPI_Barrier(MPI_COMM_WORLD);

        // Check for error
        if(sendcode != MPI_SUCCESS || recvcode != MPI_SUCCESS){
            fprintf(stderr, "ERROR!!! MPI_SUCCESS not achieved. See sendcode %i or recvcode %i", sendcode, recvcode);
        }

        /****************** Multiply Matrix *******************/
        // CPU
        if(strcmp("mpi_cpu", option) == 0){
            resA = cpu_matrix_multiply(sendA, recvA, dim, dim, dim);


        // CPU - openmp
        }else if(strcmp("mpi_openmp_cpu", option) == 0){
            sprintf(errmsg, "ERROR!!! %s is not yet implemented\n", option);
            exit_with_error(errmsg);


        // CPU - cache optimized
        }else if(strcmp("mpi_openmp_cpu_opt", option) == 0){
            sprintf(errmsg, "ERROR!!! %s is not yet implemented\n", option);
            exit_with_error(errmsg);


        // GPU
        }else if(strcmp("mpi_gpu", option) == 0){
            gpu_matrix_multiply<<<1024,32>>>(sendA, recvA, dim, dim, resA, dim, false);
            gpuErrChk(cudaPeekAtLastError());
            gpuErrChk(cudaDeviceSynchronize());


        }else{
            sprintf(errmsg, "ERROR!!! Invalid option,%s, passed\n", option);
            exit_with_error(errmsg);
        }


        // GPU NV-link

        // Visual Test that my code is assigning arrays and sending them correctly
        if(verbose == true && taskID == 1 && i%100 == 0){
            printf("task 1 : send array\n");
            print_1D_array(sendA, nx, ny);
            printf("task 1 : recv array\n");
            print_1D_array(recvA, nx, ny);
            printf("task 1 : result array\n");
            print_1D_array(resA, nx, ny);
        }
    }

    /*
    printf("Releasing memory\n");
    fflush(stdout);
    if(strcmp("mpi_cpu", option) == 0 || strcmp("mpi_openmp_cpu", option) == 0 || 
       strcmp("mpi_openmp_cpu_opt", option) == 0){
        free(dim);
        free(sendA);
        free(recvA);
        free(resA);

    // GPU
    }else if(strcmp("mpi_gpu", option) == 0){
        cudaFree(dim);
        cudaFree(sendA);
        cudaFree(recvA);
        cudaFree(resA);
    }
    */


    /*
        I believe MPI_Finalize() doesn't play cleanly with UCX / CUDA in the 
        Nvidia POD env.  I need to learn more about this.
    */
    printf("Line BEFORE MPI_Finalize\n");
    fflush(stdout);
    MPI_Finalize();

    if(taskID == 0){
        printf("The transfer is finished!\n");
    }
    return 0;
}






