#!/bin/bash

source /apps/profiles/modules_asax.sh.dyn

module load cuda/11.7.0

nvcc CUDA.cu -o CUDA
./CUDA 5000 5000 /scratch/$USER/CUDA-5000.txt
./CUDA 10000 5000 /scratch/$USER/CUDA-10000.txt

diff /scratch/$USER/CUDA-5000.txt /scratch/$USER/CPU-5000.txt
diff /scratch/$USER/CUDA-10000.txt /scratch/$USER/CPU-10000.txt