# CUDA Implementation of Conway's Game of Life

This repository contains an implementation of Conway's Game of Life using C and the Compute Unified Device Architecture (CUDA). There are four versions of this program:

- **openMP.cpp**: Uses solution from HW3 (1 thread) (CPU version)
- **openMP.cpp**: Uses solution from HW3 (20 threads)
- **MPI.cpp**: Uses the best-performing solution from HW4 (20 processes)
- **CUDA.cu**: Uses GPU

## Performance Testing

To measure performance, three rounds of tests were conducted on all four versions. openMP.cpp (CPU and threaded versions) and MPI.cpp were tested together for 3 rounds, while CUDA.cu was tested individually for 3 rounds, totaling 6 output files in this repository. The final average times for each version use the times from each of the three rounds for that version.

### Test Setup

- **Board Size**: 5000 x 5000
- **Max Iterations**: 5000

- **Board Size**: 10000 x 10000
- **Max Iterations**: 5000

### Example Output from running OPENMP_MPI.sh

The following lines are from the output file `OPENMP-MPI-ROUND_1.o218155`:

```
/scratch/ualclsd0186/CPU-5000.txt end: 283, stopped after 5000 iterations
start /scratch/ualclsd0186/CPU-10000.txt end: 1169, stopped after 5000 iterations
start /scratch/ualclsd0186/OPENMP-5000.txt end: 93, stopped after 5000 iterations
start /scratch/ualclsd0186/OPENMP-10000.txt end: 59, stopped after 5000 iterations
last iteration: 5000, time: 37.7754
last iteration: 5000, time: 149.188
```

This is how this file can be read, based on the contents of OPENMP_MPI.sh:
- **CPU (5000x5000)**: `283 sec`
- **CPU (10000x10000)**: `1169 sec`
- **OpenMP (5000x5000)**: `93 sec`
- **OpenMP (10000x10000)**: `59 sec`
- **MPI (5000x5000)**: `37.7754 sec`
- **MPI (10000x10000)**: `149.188 sec`

The numbers used in the report table are averages of the times from three separate output files, rounded to two decimal digits. The board sizes for the MPI jobs are not indicated in the output files but can be confirmed by checking the job submission script files.

### Example Output from running CUDA.sh

The following lines are from the output file `CUDA-ROUND_1.o218328`:

```
Final grid state written to /scratch/ualclsd0186/CUDA-5000.txt
Time taken for 5000 iterations: 2101.742 ms
Final grid state written to /scratch/ualclsd0186/CUDA-10000.txt
Time taken for 5000 iterations: 8155.537 ms
```

This is how this file can be read, based on the contents of OPENMP_MPI.sh:
- **CUDA (5000x5000)**: `2.101742`
- **CUDA (10000x10000)**: `8.155537`

The numbers used in the report table are averages of the times from three separate output files, rounded to two decimal digits.


### Output Files

Output files follow the naming format `X-ROUND_Y.oZ`:
- **X**: Method(s) being used (OpenMP, MPI, CUDA)
- **Y**: Round number
- **Z**: Unique identifier

## Scripts

There are two job submission script files provided:
- **OPENMP_MPI.sh** for **openMP.cpp** and **MPI.cpp**
- **CUDA.sh** for **CUDA.cu**

The script for each source file is run 3 times to get the 3 rounds for those source files.

## Compilation

To compile `CUDA.cu`, use the following script (contents of `CUDA.sh`):

```bash
#!/bin/bash

source /apps/profiles/modules_asax.sh.dyn

module load cuda/11.7.0

nvcc CUDA.cu -o CUDA
```

### Running the Program

To run the compiled program, use the following command:

```bash
./CUDA <BOARD_SIZE> <MAX_ITERATIONS> <BOARD_OUTPUT_PATH>
```

#### Arguments

- **`<BOARD_SIZE>`**: Size of the board (e.g., `50` for a 50x50 board).  
- **`<MAX_ITERATIONS>`**: Maximum number of iterations (e.g., `100`).
- **`<BOARD_OUTPUT_PATH>`**: Path to save the final board state.

#### Example Command

To test correctness, run this script using run_gpu

```bash
#!/bin/bash
g++ -O3 -march=native -flto -funroll-loops -ffast-math -Wall -o openMP openMP.cpp -fopenmp
./openMP 5000 5000 1 /scratch/$USER/CPU-5000.txt 0 /scratch/$USER/debug.txt

source /apps/profiles/modules_asax.sh.dyn
module load cuda/11.7.0
nvcc CUDA.cu -o CUDA
./CUDA 5000 5000 /scratch/$USER/CUDA-5000.txt

diff /scratch/$USER/CUDA-5000.txt /scratch/$USER/CPU-5000.txt
```
