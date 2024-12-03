/*

Name: Gregory Nothnagel

Email: gsnothnagel@crimson.ua.edu

Course Section: CS 581

Homework #: 3

To Compile, use this script:

#!/bin/bash
source /apps/profiles/modules_asax.sh.dyn
module load intel
icpx -O3 -march=native -flto -funroll-loops -ffast-math -Wall -o openMP openMP.cpp -fopenmp

To Run, use this command:

./openMP <SIZE> <MAX_GENERATIONS> <NUM_THREADS> <OUTPUT_FILE> <DEBUG_MODE?> <DEBUG_FILE>

for example:

./openMP 5 100 4 /scratch/$USER/test.txt 1 /scratch/$USER/debug.txt

or, for no debugging (only debug with small board sizes)

./openMP 5 100 4 /scratch/$USER/test.txt 0 dummy_path.txt

*/


#define _CRT_SECURE_NO_WARNINGS
#include <iostream>
#include <cstdlib>
#include <vector>
#include <time.h>
#include <string>
#include <omp.h>
#include <cstdio>

using namespace std;


class Conway {
public:

    bool** cells;
    bool** cellsNext;
    int SIZE;
    int num_iterations;

    Conway(int SIZE, vector<vector<bool>>& initialFrame) : SIZE(SIZE) {

        cells = new bool * [SIZE + 2];
        for (int i = 0; i < SIZE + 2; i++) {
            cells[i] = new bool[SIZE + 2];
            for (int j = 0; j < SIZE + 2; j++) cells[i][j] = false; // all cells start dead
        }

        // initialize based off of initialFrame
        for (int i = 1; i < SIZE + 1; i++) {
            for (int j = 1; j < SIZE + 1; j++) {
                cells[i][j] = initialFrame[i - 1][j - 1]; // initial frame assumed to be 2 cells smaller in both dimensions (aka assumed to not contain boundary buffer cells)
            }
        }

        // Array of next frames cells is a copy of start frame
        cellsNext = new bool * [SIZE + 2];
        for (int i = 0; i < SIZE + 2; i++) {
            cellsNext[i] = new bool[SIZE + 2];
            for (int j = 0; j < SIZE + 2; j++) {
                cellsNext[i][j] = cells[i][j];
            }
        }

    }

    void advance(int MAX_GENERATIONS, int NUM_THREADS, bool DEBUG_MODE, string DEBUG_PATH) {

        bool change = false;

        if (DEBUG_MODE){
            toFile(DEBUG_PATH, "w", false);
        }

#pragma omp parallel default(none) shared(MAX_GENERATIONS, change, DEBUG_MODE, DEBUG_PATH) num_threads(NUM_THREADS)
        {
            int tid = omp_get_thread_num();  // Get the thread ID
            int nthreads = omp_get_num_threads();  // Get the total number of threads

            // Calculate which row this thread is responsible for
            int rows_per_thread = SIZE / nthreads;  // Number of rows each thread will handle
            int start_row = tid * rows_per_thread + 1;  // Starting row for this thread
            int end_row = (tid == nthreads - 1) ? SIZE + 1 : start_row + rows_per_thread;  // Last row (handle remainder in the last thread)


            for (int reps = 0; reps < MAX_GENERATIONS; reps++) {

                for (int row = start_row; row < end_row; row++) {
                    for (int col = 1; col < SIZE + 1; col++) {

                        int neighbors = 0;
                        for (int i = -1; i <= 1; i++) {
                            for (int j = -1; j <= 1; j++) {
                                neighbors += cells[row + i][col + j];
                            }
                        }
                        neighbors -= cells[row][col];

                        // Apply Rules
                        if ((cells[row][col] && neighbors < 2) ||
                            (cells[row][col] && neighbors > 3) ||
                            (!cells[row][col] && neighbors == 3)) {
                            cellsNext[row][col] = !cells[row][col];
                            change = true;
                        }
                        else cellsNext[row][col] = cells[row][col];

                    }
                }

#pragma omp barrier
#pragma omp single
                {
                    swap(cells, cellsNext);
                    if (change && DEBUG_MODE) {
                        toFile(DEBUG_PATH, "a", false);
                    }
                    num_iterations = reps + 1;
                }
                if (!change) break;
#pragma omp barrier
#pragma omp single
                {
                    change = false;
                }
#pragma omp barrier

            }

        }

    }

    void toFile(string name, const char* mode, bool showName) {
        if (showName) cout << name << " ";
        FILE* f = fopen(name.c_str(), mode);

        for (int row = 1; row < SIZE + 1; row++) {
            for (int col = 1; col < SIZE + 1; col++) {
                fprintf(f, "%d", cells[row][col]);
            }
            fprintf(f, "\n");
        }
        fprintf(f, "\n");

        fclose(f);

    }

};


int main(int argc, char* argv[]) { // int argc, char* argv[]

    if (argc != 7) {
        cerr << "Usage: " << argv[0] << " <SIZE> <MAX_GENERATIONS> <NUM_THREADS> <OUTPUT_FILE> <DEBUG_MODE?> <DEBUG_FILE>" << endl;
        return 1;
    }



    int SIZE = stoi(argv[1]);
    int MAX_GENERATIONS = stoi(argv[2]);
    int NUM_THREADS = stoi(argv[3]);
    string PATH = string(argv[4]);
    bool DEBUG_MODE = stoi(argv[5]);
    string DEBUG_PATH = string(argv[6]);

    vector<vector<bool>> randomInitialFrame;
    for (int row = 0; row < SIZE; row++) {
        randomInitialFrame.push_back(vector<bool>());
        for (int col = 0; col < SIZE; col++) {
            randomInitialFrame[row].push_back(rand() % 2);
        }
    }

    Conway C(SIZE, randomInitialFrame);

    cout << "start ";

    int startTime = time(nullptr);

    C.advance(MAX_GENERATIONS, NUM_THREADS, DEBUG_MODE, DEBUG_PATH);

    int endTime = time(nullptr);

    // "w" means overwrite, true means print PATH to screen
    C.toFile(PATH, "w", true);

    printf("end: %d, stopped after %d iterations\n", endTime - startTime, C.num_iterations);


}