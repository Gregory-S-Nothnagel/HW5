/*

Gregory Nothnagel
gsnothnagel@crimson.ua.edu
CS 581
Homework #5

To Compile CUDA.cu game of life program, run the following script:

        #!/bin/bash

		source /apps/profiles/modules_asax.sh.dyn

		module load cuda/11.7.0

		nvcc CUDA.cu -o CUDA

To Run, use the following command (inside of a .sh file obviously) and run with run_gpu on class queue:

        ./CUDA <BOARD_SIZE> <MAX_ITERATIONS> <BOARD_OUTPUT_PATH>

For more details, see "Compilation" section of README.md in the github repo

* Then you can inspect the board output file to confirm that everything looks as expected

*/

#include <stdio.h>
#include <stdlib.h>  // For atoi
#include <cuda_runtime.h>

// Function to write the final grid to a file
void write_grid_to_file(const char *filename, int *grid, int width, int height) {
    FILE *file = fopen(filename, "w");
    if (!file) {
        perror("Error opening file");
        return;
    }

    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            fprintf(file, "%d", grid[y * width + x]);
        }
        fprintf(file, "\n");
    }
        fprintf(file, "\n");

    fclose(file);
    printf("Final grid state written to %s\n", filename);
}

// Kernel to update the grid
__global__ void game_of_life(int *grid, int *newGrid, int width, int height) {
    int x = threadIdx.x + blockIdx.x * blockDim.x;
    int y = threadIdx.y + blockIdx.y * blockDim.y;

    // Ensure the thread is within the grid bounds
    if (x >= width || y >= height) return;


        int live_neighbors = 0;

    // Count live neighbors with boundary checks
    for (int nx = x - 1; nx <= x + 1; nx++) {
        for (int ny = y - 1; ny <= y + 1; ny++) {
            if (nx != x || ny != y) {
                                // Only count valid neighbors within the grid
                                if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
                                        live_neighbors += grid[ny * width + nx];
                                }
                        }
        }
    }

    // Apply Conway's rules
    int current = grid[y * width + x];

        if ((current && live_neighbors < 2) || (current && live_neighbors > 3) || (!current && live_neighbors == 3)) {
                newGrid[y * width + x] = !current;
        }
    else newGrid[y * width + x] = current;

        return;

}

// Main program
int main(int argc, char *argv[]) {
    if (argc != 4) {
        printf("Usage: %s <grid size (N)> <max iterations> <output file>\n", argv[0]);
        return -1;
    }

    int N = atoi(argv[1]);
    int MAX_ITERATIONS = atoi(argv[2]);
    const char *outputFile = argv[3];

    if (N <= 0 || MAX_ITERATIONS <= 0) {
        printf("Both grid size and max iterations must be positive integers.\n");
        return -1;
    }

    const int width = N;
    const int height = N;

    size_t gridSize = width * height * sizeof(int);

    // Allocate memory for the grid on the host
    int *h_grid = (int *)malloc(gridSize);
    int *h_newGrid = (int *)malloc(gridSize);

    // Initialize the grid (random or predefined pattern)
    for (int i = 0; i < width * height; i++) {
        h_grid[i] = rand() % 2; // Randomly initialize cells as 0 or 1
    }

    // Allocate memory for the grid on the device
    int *d_grid, *d_newGrid;
    cudaMalloc(&d_grid, gridSize);
    cudaMalloc(&d_newGrid, gridSize);

    // Copy the initial grid to the device
    cudaMemcpy(d_grid, h_grid, gridSize, cudaMemcpyHostToDevice);

    // Define the execution configuration
    dim3 threadsPerBlock(16, 16);
    dim3 blocksPerGrid((width + threadsPerBlock.x - 1) / threadsPerBlock.x,
                       (height + threadsPerBlock.y - 1) / threadsPerBlock.y);


        int *currentGrid = d_grid;
        int *nextGrid = d_newGrid;

        // Create CUDA events for timing
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    // Start recording
    cudaEventRecord(start, 0);

        for (int iter = 0; iter < MAX_ITERATIONS; iter++) {
                game_of_life<<<blocksPerGrid, threadsPerBlock>>>(currentGrid, nextGrid, width, height);
                cudaDeviceSynchronize();

                // Swap the grids
                int *temp = currentGrid;
                currentGrid = nextGrid;
                nextGrid = temp;
        }

        // Stop recording
    cudaEventRecord(stop, 0);
    cudaEventSynchronize(stop);

    // Calculate elapsed time
    float milliseconds = 0;
    cudaEventElapsedTime(&milliseconds, start, stop);

    // Clean up events
    cudaEventDestroy(start);
    cudaEventDestroy(stop);

    // Copy the final grid back to the host
    cudaMemcpy(h_grid, d_grid, gridSize, cudaMemcpyDeviceToHost);

    // Write the final grid to the specified file
    write_grid_to_file(outputFile, h_grid, width, height);

    // Free memory
    free(h_grid);
    free(h_newGrid);
    cudaFree(d_grid);
    cudaFree(d_newGrid);

        printf("Time taken for %d iterations: %.3f ms\n", MAX_ITERATIONS, milliseconds);

    return 0;
}