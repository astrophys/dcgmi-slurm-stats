#!/bin/bash
#SBATCH --ntasks=2
#SBATCH --gpus-per-task=1
#SBATCH --cpus-per-task=1
#SBATCH --output=slurm-out/slurm-%A.out


ml purge
ml load slurm
module use /home/${USER}/software/hpc_sdk_2023_239/modulefiles
ml load nvhpc-hpcx-cuda12/23.9
ml list
export TMPDIR=${SLURM_SUBMIT_DIR}
echo "TMPDIR = ${TMPDIR}"

# prolog
# Check if devices set
if [ -n ${CUDA_VISIBLE_DEVICES} ]; then
    mkdir -pv ${TMPDIR}/output/${SLURM_JOB_ID}
    export TMPDIR=${TMPDIR}/output/${SLURM_JOB_ID}
    
    # Sanity check that CUDA_VISIBLE_DEVICES are same as seen by nvidia-smi
    #export smivis=
    #for i in `nvidia-smi -L | awk '{print $2}' | cut -d":" -f1 `; do
    #    if [ -z $smivis ]; then
    #        smivis=${i};
    #    else
    #        echo $smivis;
    #        smivis="${smivis},${i}";
    #    fi;
    #done 
    #if [ $smivis == $CUDA_VISIBLE_DEVICES ]; then
    #    echo "true  : nvidia-smi -L == CUDA_VISIBLE_DEVICES : $CUDA_VISIBLE_DEVICES";
    #else
    #    echo "false : nvidia-smi -L == CUDA_VISIBLE_DEVICES : $CUDA_VISIBLE_DEVICES";
    #fi

    ## You must create a 'group' with the GPUs of interest
    ## THEN you must start monitoring with a 'dcgmi job'
    ## QUESTION : How do I list the running dcgmi jobs?
    # stdout=$(dcgmi group -c job_${SLURM_JOB_ID} -a ${CUDA_VISIBLE_DEVICES})
    ###SBATCH --gres=gpu:1
    echo "TMPDIR = ${TMPDIR}"
    set | grep "CUDA\|SLURM" &> ${TMPDIR}/set_slurm_env

    # Consider Checking SLURM_STEP_GPUS first then SLURM_JOB_GPUS
    #   ${SLURM_STEP_GPUS:-$SLURM_JOB_GPUS}
    #   --> https://stackoverflow.com/a/65709108/4021436
    stdout=$(dcgmi group -c job_${SLURM_JOB_ID} -a ${SLURM_JOB_GPUS})
    echo $stdout 

    #### ADD A STEP HERE TO VALIDATE THE GPUs shown to user via nvidia-smi -L
    #### And seen by dcgmi discovery -l

    if [ $? -eq 0 ]; then
        groupid=$(echo $stdout | awk '{print $10}')
        dcgmi stats -e
        dcgmi stats -g ${groupid} -s ${SLURM_JOB_ID}
        # Save groupid for epilog script
        echo "${groupid}" > ${TMPDIR}/dcgmi_groupid
    fi
fi

nvidia-smi -L
### NOTE : mpiexec doesn't work right here with GPUs, if used all your processes will run
### on the same GPU
#mpiexec --np 2 ./mpi_matrix_mult --option mpi_gpu  --size 500 --verbose false & 

# Use env vars to access mpirun --mca .. options
#   --> ompi_info --param pml ucx --level 9     # See UCX options
#   --> https://docs.open-mpi.org/en/main/mca.html
export OMPI_MCA_pml=ucx     # From `man mpirun`, same as using mpirun --mca

# Verbosely print UCX diagnostic info
export OMPI_MCA_pml_ucx_verbose=3

# Print to see if hanging receiv requests
#export OMPI_MCA_pml_ucx_request_leak_check=true

export OMPI_MCA_mpi_common_cuda_verbose=10

echo "Sleeping for 300s"
sleep 300
srun ./mpi_matrix_mult --option mpi_gpu  --size 500 --verbose false &
sleep 10
nvidia-smi  &> ${TMPDIR}/nvidia-smi_running
wait



# epilog
## Delete after finished
#export TMPDIR=${TMPDIR}/${SLURM_JOB_ID}
if [ -n ${CUDA_VISIBLE_DEVICES} ] && [ -f ${TMPDIR}/dcgmi_groupid ]; then
    groupid=$(cat "${TMPDIR}/dcgmi_groupid")
    dcgmi stats -x ${SLURM_JOB_ID}
    dcgmi stats -v -j ${SLURM_JOB_ID} > ${TMPDIR}/gpustats_${SLURM_JOB_ID}
    dcgmi group -d ${groupid}
fi
