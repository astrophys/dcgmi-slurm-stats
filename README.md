# dcgmi-slurm-stats
A code to test using dcgmi to collect GPU statistics in a Slurm cluster


### Installation :
You'll want to download the [Nvidia SDK](https://developer.nvidia.com/hpc-sdk) for HPC.
Be sure you pick a version compatible with the installed version of CUDA on your compute
nodes.

i.e.
```
$ nvidia-smi | grep CUDA
```

### Compiling
```
$ ml load nvhpc-hpcx-cuda12/23.9
$ make
```

### Running
```
# One node exp. (interactive)
$ srun --ntasks=2 --gres=gpu:2 --cpus-per-task=12 --pty bash
$ mpiexec --np 2 ./mpi_matrix_mult --option mpi_gpu  --size 10 --verbose true

# One node exp. (non-interactive)
$ sbatch submit_2task_1node.sh

# Two node exp
$ sbatch submit_2task_2node.sh
```

### QUESTIONS :
1. Q : How do I list the running dcgmi jobs?
2. Q : Can a normal user stop dcgmi stats on group -g 0? 

### NOTES :
1. KEY CHALLENGE : CUDA_VISIBLE_DEVICES' indexing DOES NOT follow dcgmi's
                   This means if you're allocated gpu's 0, 2 on a node (per dcgmi's
                   indexing), CUDA_VISIBLE_DEVICES=0,1 b/c it ALWAYS starts at 0."


### Links :
1. [cuda-gdb with mpi](https://docs.nvidia.com/cuda/cuda-gdb/index.html?highlight=MPI#example-mpi-cuda-application)
