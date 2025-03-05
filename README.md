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

```
make
```
