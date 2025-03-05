#!/bin/bash
#SBATCH --ntasks=2
#SBATCH --gres=gpu:2
#SBATCH --cpus-per-task=16
#SBATCH --output=slurm-out/slurm-%A.out

module use /home/${USER}/software/hpc_sdk_2023_239/modulefiles
ml load nvhpc-hpcx-cuda12/23.9
mpiexec --np 2 ./mpi_matrix_mult --option mpi_gpu  --size 10 --verbose true

