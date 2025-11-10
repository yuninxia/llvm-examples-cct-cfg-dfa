#include "level2.h"

static int depth_expand(int seed, int depth, int fanout) {
  if (depth <= 0)
    return seed;

  int acc = seed + fanout;
  for (int i = 0; i < fanout; ++i) {
    acc += depth_expand(seed + i + 1, depth - 1, fanout / 2 + 1);
  }
  return acc;
}

int fanout_walk(const Task *task, int budget) {
  if (!task || budget <= 0)
    return 0;
  int depth = (task->fanout % budget) + 1;
  return depth_expand(task->weight, depth, task->fanout % 5 + 1);
}

int run_pipeline(Task *tasks, size_t count) {
  int score = 0;
  for (size_t i = 0; i < count; ++i) {
    Task *t = &tasks[i];
    score += fanout_walk(t, (int)(count + t->weight % 7));
    if ((int)i % 2 == 0)
      score -= (int) (sum_weights(tasks, count) % (t->fanout + 3));
  }
  if (score < 0)
    score = -score;
  return score;
}
