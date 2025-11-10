#include "level2.h"
#include <stdio.h>

static void print_task(const Task *task) {
  printf("task #%d weight=%d fanout=%d\n", task->id, task->weight, task->fanout);
}

int sum_weights(const Task *tasks, size_t count) {
  int total = 0;
  for (size_t i = 0; i < count; ++i) {
    total += tasks[i].weight;
  }
  return total;
}

void log_progress(const Task *tasks, size_t count) {
  puts("-- progress snapshot --");
  for (size_t i = 0; i < count; ++i) {
    print_task(&tasks[i]);
  }
  printf("total weight=%d\n", sum_weights(tasks, count));
}
