#!/bin/bash
#SBATCH --ntasks=2
#SBATCH --gres=gpu:2
#SBATCH --cpus-per-task=16
#SBATCH --output=slurm-out/slurm-%A.out

echo "TMPDIR = ${TMPDIR}"
export TMPDIR=${SLURM_SUBMIT_DIR}
echo "TMPDIR = ${TMPDIR}"

# prolog
# Check if devices set
if [ -n ${CUDA_VISIBLE_DEVICES} ]; then
    mkdir -pv ${TMPDIR}/${SLURM_JOB_ID}
    export TMPDIR=${TMPDIR}/${SLURM_JOB_ID}
    
    # Sanity check that CUDA_VISIBLE_DEVICES are same as seen by nvidia-smi
    export smivis=
    for i in `nvidia-smi -L | awk '{print $2}' | cut -d":" -f1 `; do
        if [ -z $smivis ]; then
            smivis=${i};
        else
            echo $smivis;
            smivis="${smivis},${i}";
        fi;
    done 
    if [ $smivis == $CUDA_VISIBLE_DEVICES ]; then
        echo "true  : nvidia-smi -L == CUDA_VISIBLE_DEVICES : $CUDA_VISIBLE_DEVICES";
    else
        echo "false : nvidia-smi -L == CUDA_VISIBLE_DEVICES : $CUDA_VISIBLE_DEVICES";
    fi

    ## You must create a 'group' with the GPUs of interest
    ## THEN you must start monitoring with a 'dcgmi job'
    ## QUESTION : How do I list the running dcgmi jobs?
    stdout=$(dcgmi group -c job_${SLURM_JOB_ID} -a ${CUDA_VISIBLE_DEVICES})
    if [ $? -eq 0 ]; then
        groupid=$(echo $stdout | awk '{print $10}')
        dcgmi stats -e
        dcgmi stats -g ${groupid} -s ${SLURM_JOB_ID}
        # Save groupid for epilog script
        echo "${groupid}" > ${TMPDIR}/dcgmi_groupid
    fi
fi


module use /home/${USER}/software/hpc_sdk_2023_239/modulefiles
ml load nvhpc-hpcx-cuda12/23.9
mpiexec --np 2 ./mpi_matrix_mult --option mpi_gpu  --size 100 --verbose false



# epilog
## Delete after finished
#export TMPDIR=${TMPDIR}/${SLURM_JOB_ID}
if [ -n ${CUDA_VISIBLE_DEVICES} ] && [ -f ${TMPDIR}/dcgmi_groupid ]; then
    groupid=$(cat "${TMPDIR}/dcgmi_groupid")
    dcgmi stats -x ${SLURM_JOB_ID}
    dcgmi stats -v -j ${SLURM_JOB_ID} > ${TMPDIR}/gpustats_${SLURM_JOB_ID}
    dcgmi group -d ${groupid}
fi
