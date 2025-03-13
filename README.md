# dcgmi-slurm-stats
A code to test using dcgmi to collect GPU statistics in a Slurm cluster

### Introduction
We can use the Slurm accounting database (via `sacct`) to collect the elapsed time of a
job and the number of GPUs used (i.e. `--format` field `alloctres`).  With a little 
massaging, we can get the allocated GPU time (i.e. number of GPUs * elapsed time).

If you want to get how _efficiently_ the GPUs were used, this is a much harder prospect.
To do this, we will use `dcgmi` to collect the GPU memory and sm information per tasks 
run on each the GPU. 

We follow the instructions given by [Job Statistics with Nvidia Data Center GPU Manager and Slurm](https://developer.nvidia.com/blog/job-statistics-nvidia-data-center-gpu-manager-slurm/).
and the [DCGMI User Guide](https://docs.nvidia.com/datacenter/dcgm/latest/user-guide/feature-overview.html)

Caveats :
1. `dcgmi` _only_ reports the efficience of processes that _actually_ run on the GPU. So
   if for instance, a GPU is allocated for 60min but only has a process on it for 1min,
   `dcgmi` might report that the process used the streaming multiprocessor for 95%. 
2. If you follow the above instructions and use `CUDA_VISIBLE_DEVICES`, you won't always
   collect the correct GPUs because `CUDA_VISIBLE_DEVICES` always starts indexing from
   0, regardless of the index listed by `nvidia-smi`. Instead you'd want to use
   `SLURM_JOB_GPUS`.
3. This hasn't been tested with more complicated jobs with multiple steps.


### Installation :
You'll want to download the [Nvidia SDK](https://developer.nvidia.com/hpc-sdk) for HPC.
Be sure you pick a version compatible with the installed version of CUDA on your compute
nodes.

i.e. Check the version of CUDA
```
$ nvidia-smi | grep CUDA
```

You'll also need to ensure `dcgmi` is [installed](https://docs.nvidia.com/datacenter/dcgm/latest/user-guide/getting-started.html#installation)
i.e. Check that you have it
```
$ which dcgmi
```


### Compiling
```
$ ml load nvhpc-hpcx-cuda12/23.9
$ make
```

### Running
The recommended way of running this on a Slurm cluster is to utilize `srun` to start copies
of the parallel process.  When I tried calling `mpiexec` directly, I sometimes wound up with 
two processes on the same GPU.  I got the desired behavior using `srun`.


```
# One node exp. (non-interactive)
$ sbatch submit_2task_1node.sh

# Two node exp
$ sbatch submit_2task_2node.sh
```

### DCGMI Notes :
Below is the process for collecting stats from the GPUs
1. Create a `dcgmi` group to follow the particular GPUs allocated for your job
    ```
    # i,j,k are GPU indices enumerated by nvidia-smi 
    $ dcgmi group -c some_name -a i,j,k
    # Be sure to store the dcgmi group id
    ```

2. Enable process watches
    ```
    $ dcgmi stats -e         
    ```

3. Start collecting info on running processes
    ```
    $ dcgmi stats -g dcgmi_group_id -s some_label
    ```

4. Start your GPU process

5. After GPU process has ended, stop collection of stats

    ```
    $ dcgmi stats -x some_label
    ```

6. Querry the statistics 
   
    ```
    $ dcgmi stats -v -j some_label
    ```

7. Delete the group

    ```
    $ dcgmi group -d dcgmi_group_id
    ```

### Observations :
1. After starting `dcgmi stats`, even if I inject a `sleep 300` command, the
   Average SM Utilization does not reflect the time the GPU was unused.


### MPI / CUDA Notes and Observations :
1. I am compiling the code (via `make`) using `nvcc` on a DGX system.  When I 
   call `MPI_Finalize()`, warnings like.  
    ```
    [1741636331.473893] [somehost:123] mpool.c:55   UCX  WARN  object 0x55555b12a040 was not returned to mpool CUDA EVENT objects
    ```
   UCX seems to be some [middleware]((https://docs.nvidia.com/doca/archive/doca-v1.5.0/index.html)
   running on the IB network card. I think I need to do a deeper dive on this to
   understand what is going on here.  I don't think did not observe this behavior
   before with multi-GPU MPI jobs so I think this is very hardware specific.

2. Because I'm calling my MPI code via `srun` rather than `mpirun`, I found it
   challenging to adjust the runtime behavior using MPI `mca` modules.  According to the
   [OpenMPI documentation](https://docs.open-mpi.org/en/v5.0.x/mca.html), 
   You can control the `mca` runtime modules used by `mpirun` by modifing environmental 
   variables. E.g.
    ```
    export OMPI_MCA_mpi_common_cuda_verbose=10
    export OMPI_MCA_pml_ucx_verbose=3
    ```

3. As shown above, you can control the verbose diagnostics output by both UCX 
   and CUDA.

4. At some point I was getting segmentation faults
    a) They all occur near or during `MPI_Finalize()`.
    b) I think some of them might have been related to a having conflicting nvhpc
       modules loaded.
    c) Some of them were due to me trying to free CUDA managed memory.
    d) I think these may be related to the UCX WARN above.


### Questions
1. Q : `dcgmi stats -e` do I need to specify group?
2. Q : Can a normal user stop dcgmi stats on group -g 0? 

### TO DO
1. Work on understanding the UCX warnings and mitigating them
2. Work on understanding using MPI, CUDA, NVLink and Infiniband. It seems quite hardware
   dependant. Useful resources
    a) [UCX Programming Guide](https://docs.nvidia.com/doca/archive/doca-v1.5.0/ucx-programming-guide/index.html)
    b) [OpenUCX Read The Docs](https://openucx.readthedocs.io/en/master/running.html)
    c) [OpenMPI - Modular Component Architecture](https://docs.open-mpi.org/en/main/mca.html)
    d) [OpenMPI - Infiniband / RoCE Support](https://docs.open-mpi.org/en/v5.0.x/tuning-apps/networking/ib-and-roce.html)
    e) [CUDA Unified Memory](https://developer.nvidia.com/blog/unified-memory-cuda-beginners/)
    f) [Mixing MPI and CUDA](https://docs.ccv.brown.edu/oscar/gpu-computing/mpi-cuda)
    g) [OpenMPI - CUDA](https://docs.open-mpi.org/en/v5.0.x/tuning-apps/networking/cuda.html)
    h) [OSU : MPI over IB examples](https://mvapich.cse.ohio-state.edu/benchmarks/)
    i) [CUDA C++ Best Practices Guide](https://docs.nvidia.com/cuda/cuda-c-best-practices-guide/)
    j) [Lawrence Livermore's Awesome MPI Documentation](https://hpc-tutorials.llnl.gov/mpi/)

<!--
### Notes :
[somehost:1046653:0:1046653] proto_common.c:860  Fatal: 'abort' is not implemented for protoc
ol rndv/rkey_ptr/mtype (req: 0x55555fc9eac0)
==== backtrace (tid:1046653) ====
 0 0x0000000000055996 ucp_proto_stub_fatal_not_implemented()  /build-result/src/hpcx-v2.19-gcc-mlnx_ofed-redhat7-cuda12-x86_64/ucx-7bb2722ff2187a0cad557ae4a6afa090569f83fb/src/ucp/proto/proto_common.c:859
 1 0x0000000000057cc3 ucp_proto_abort_fatal_not_implemented()  /build-result/src/hpcx-v2.19-gcc-mlnx_ofed-redhat7-cuda12-x86_64/ucx-7bb2722ff2187a0cad557ae4a6afa090569f83fb/src/ucp/proto/proto_common.c:866
 2 0x000000000001b5b3 uct_mm_ep_arbiter_purge_cb()  /build-result/src/hpcx-v2.19-gcc-mlnx_ofed-redhat7-cuda12-x86_64/ucx-7bb2722ff2187a0cad557ae4a6afa090569f83fb/src/uct/sm/mm/base/mm_ep.c:527
 3 0x0000000000053c37 ucs_arbiter_group_purge()  /build-result/src/hpcx-v2.19-gcc-mlnx_ofed-redhat7-cuda12-x86_64/ucx-7bb2722ff2187a0cad557ae4a6afa090569f83fb/src/ucs/datastruct/arbiter.c:135
 4 0x000000000001c14a uct_mm_ep_pending_purge()  /build-result/src/hpcx-v2.19-gcc-mlnx_ofed-redhat7-cuda12-x86_64/ucx-7bb2722ff2187a0cad557ae4a6afa090569f83fb/src/uct/sm/mm/base/mm_ep.c:542
 5 0x00000000000383d2 uct_ep_pending_purge()  /build-result/src/hpcx-v2.19-gcc-mlnx_ofed-redhat7-cuda12-x86_64/ucx-7bb2722ff2187a0cad557ae4a6afa090569f83fb/src/uct/api/uct.h:3209
 6 0x00000000000383d2 ucp_ep_purge_lanes()  /build-result/src/hpcx-v2.19-gcc-mlnx_ofed-redhat7-cuda12-x86_64/ucx-7bb2722ff2187a0cad557ae4a6afa090569f83fb/src/ucp/core/ucp_ep.c:1277
 7 0x000000000004fd63 ucp_worker_destroy_eps()  /build-result/src/hpcx-v2.19-gcc-mlnx_ofed-redhat7-cuda12-x86_64/ucx-7bb2722ff2187a0cad557ae4a6afa090569f83fb/src/ucp/core/ucp_worker.c:2844
 8 0x000000000004fd63 ucp_worker_destroy()  /build-result/src/hpcx-v2.19-gcc-mlnx_ofed-redhat7-cuda12-x86_64/ucx-7bb2722ff2187a0cad557ae4a6afa090569f83fb/src/ucp/core/ucp_worker.c:2857
 9 0x0000000000006a5b mca_pml_ucx_cleanup()  /var/jenkins/workspace/rel_nv_lib_hpcx_cuda12_x86_64/work/rebuild_ompi/ompi/build/ompi/mca/pml/ucx/../../../../../ompi/mca/pml/ucx/pml_ucx.c:390
10 0x000000000004fba8 ompi_mpi_finalize()  /var/jenkins/workspace/rel_nv_lib_hpcx_cuda12_x86_64/work/rebuild_ompi/ompi/build/ompi/../../ompi/runtime/ompi_mpi_finalize.c:342
11 0x000000000000b8e1 main()  /home/user/code/dcgmi-slurm-stats/src/mpi/mpi_matrix_mult.cu:203
12 0x0000000000029d90 __libc_init_first()  ???:0
13 0x0000000000029e40 __libc_start_main()  ???:0
14 0x000000000000abe5 _start()  ???:0
```
Let's read the documentation to try and figure this out.
Seems like setting OMPI_MCA_mpi_common_cuda_verbose and OMPI_MCA_pml_ucx_verbose
mitigates the segmentation fault.  At least I'm not getting that, but I clearly
need to better understand how to use UCX, MPI and CUDA all together.
-->


<!--
```
# pml_ucx_request_leak_check :
#   spits out warnings during MPI_Finalize() if non-blocking operations haven't been 
#   released.
ompi_info --param pml ucx --level 9
```
-->

### Links :
0. [Job Statistics with Nvidia Data Center GPU Manager and Slurm](https://developer.nvidia.com/blog/job-statistics-nvidia-data-center-gpu-manager-slurm/)
1. [cuda-gdb with mpi](https://docs.nvidia.com/cuda/cuda-gdb/index.html?highlight=MPI#example-mpi-cuda-application)
2. [Bluefield and DOCA Programming Guides](https://docs.nvidia.com/doca/archive/doca-v1.5.0/index.html)
3. [OpenMPI 4.1 README](https://github.com/open-mpi/ompi/blob/v4.1.x/README)
4. [Open UCX with MPI](https://openucx.readthedocs.io/en/master/running.html#running-mpi)
5. [CUDA Unified Memory](https://developer.nvidia.com/blog/unified-memory-cuda-beginners/)
6. [OSU Benchmarks - use for inspiration](https://mvapich.cse.ohio-state.edu/benchmarks/)
7. [DCGMI Documentation](https://docs.nvidia.com/datacenter/dcgm/latest/user-guide/feature-overview.html)
8. [OpenMPI MCA documentation](https://docs.open-mpi.org/en/v5.0.x/mca.html)
9. [DCGM Documentation](https://docs.nvidia.com/datacenter/dcgm/latest/user-guide/feature-overview.html#)
10. [Lawrence Livermore's Awesome MPI Documentation](https://hpc-tutorials.llnl.gov/mpi/)
