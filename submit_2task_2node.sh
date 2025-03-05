#!/bin/bash
#SBATCH --nodes=2
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=16

module use /home/${USER}/software/hpc_sdk_2023_239/modulefiles
ml load nvhpc-hpcx-cuda12/23.9
mpiexec --np 2 ./mpi_matrix_mult --option mpi_gpu  --size 10 --verbose true

