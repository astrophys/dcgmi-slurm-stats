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
