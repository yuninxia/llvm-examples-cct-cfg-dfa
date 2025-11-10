#pragma once
#include <stddef.h>

typedef struct Task {
  int id;
  int weight;
  int fanout;
} Task;

int sum_weights(const Task *tasks, size_t count);
void log_progress(const Task *tasks, size_t count);
int fanout_walk(const Task *task, int budget);
int run_pipeline(Task *tasks, size_t count);
