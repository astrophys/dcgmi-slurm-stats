#!/bin/bash
#SBATCH --gres=gpu:3
#SBATCH --cpus-per-task=16

ml load nvhpc/24.7
echo "hello world"
