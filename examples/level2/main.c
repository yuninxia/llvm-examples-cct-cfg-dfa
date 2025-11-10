#include "level2.h"

static void seed_tasks(Task *tasks, size_t count) {
  for (size_t i = 0; i < count; ++i) {
    tasks[i].id = (int)i;
    tasks[i].weight = (int)(i * 3 + 5);
    tasks[i].fanout = (int)((i % 4) + 2);
  }
}

int main(void) {
  Task tasks[5];
  seed_tasks(tasks, 5);
  log_progress(tasks, 5);
  int summary = run_pipeline(tasks, 5);
  return summary % 17;
}
