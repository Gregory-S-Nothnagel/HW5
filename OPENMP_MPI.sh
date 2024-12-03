#!/bin/bash

g++ -O3 -march=native -flto -funroll-loops -ffast-math -Wall -o openMP openMP.cpp -fopenmp

./openMP 5000 5000 1 /scratch/$USER/CPU-5000.txt 0 /scratch/$USER/debug.txt
./openMP 10000 5000 1 /scratch/$USER/CPU-10000.txt 0 /scratch/$USER/debug.txt

./openMP 5000 5000 20 /scratch/$USER/OPENMP-5000.txt 0 /scratch/$USER/debug.txt
./openMP 10000 5000 20 /scratch/$USER/OPENMP-10000.txt 0 /scratch/$USER/debug.txt

source /apps/profiles/modules_asax.sh.dyn
module load openmpi

mpicxx -O3 -march=native -flto -funroll-loops -ffast-math -Wall -o MPI MPI.cpp

mpirun -n 20 ./MPI 5000 5000 /scratch/$USER/MPI-5000.txt
mpirun -n 20 ./MPI 10000 5000 /scratch/$USER/MPI-10000.txt

diff /scratch/$USER/MPI-5000.txt /scratch/$USER/CPU-5000.txt
diff /scratch/$USER/OPENMP-5000.txt /scratch/$USER/CPU-5000.txt
diff /scratch/$USER/MPI-10000.txt /scratch/$USER/CPU-10000.txt
diff /scratch/$USER/OPENMP-10000.txt /scratch/$USER/CPU-10000.txt