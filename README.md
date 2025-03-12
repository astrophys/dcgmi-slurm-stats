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
2. Try SLURM_JOB_GPUS
3. Sometimes when I run this via `srun`, I get warnings like 
```
[1741636331.473893] [somehost:123] mpool.c:55   UCX  WARN  object 0x55555b12a040 was not returned to mpool CUDA EVENT objects
```
other times I get segmentation faults
```
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


```
# pml_ucx_request_leak_check :
#   spits out warnings during MPI_Finalize() if non-blocking operations haven't been 
#   released.
ompi_info --param pml ucx --level 9
```

### Links :
1. [cuda-gdb with mpi](https://docs.nvidia.com/cuda/cuda-gdb/index.html?highlight=MPI#example-mpi-cuda-application)
2. [Bluefield and DOCA Programming Guides](https://docs.nvidia.com/doca/archive/doca-v1.5.0/index.html)
3. [OpenMPI 4.1 README](https://github.com/open-mpi/ompi/blob/v4.1.x/README)
4. [Open UCX with MPI](https://openucx.readthedocs.io/en/master/running.html#running-mpi)
