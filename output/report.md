# LLVM Analysis Visualization Report

Generated on 2025-11-10 03:08:44 UTC
(Artifacts rooted at `./`)

## Level 1

- CFG diagrams: 2
- Liveness visuals: 2
- CCT captures: 1

### Control-Flow Graphs
![CFG foo](level1/cfg/foo.svg)

![CFG main](level1/cfg/main.svg)

### Liveness Heatmaps
![Liveness foo](level1/liveness/foo.svg)

### Live Range Charts
![Live Ranges foo](level1/liveness/foo_ranges.svg)

### Calling Context Trees
#### calls_cct.txt
```
r=3
=== Calling Context Tree ===
main [1]
  bar [1]
    baz [1]
```


## Level 2

- CFG diagrams: 8
- Liveness visuals: 12
- CCT captures: 1

### Control-Flow Graphs
![CFG depth_expand](level2/cfg/depth_expand.svg)

![CFG fanout_walk](level2/cfg/fanout_walk.svg)

![CFG log_progress](level2/cfg/log_progress.svg)

![CFG main](level2/cfg/main.svg)

![CFG print_task](level2/cfg/print_task.svg)

![CFG run_pipeline](level2/cfg/run_pipeline.svg)

![CFG seed_tasks](level2/cfg/seed_tasks.svg)

![CFG sum_weights](level2/cfg/sum_weights.svg)

### Liveness Heatmaps
![Liveness depth_expand](level2/liveness/depth_expand.svg)

![Liveness fanout_walk](level2/liveness/fanout_walk.svg)

![Liveness log_progress](level2/liveness/log_progress.svg)

![Liveness run_pipeline](level2/liveness/run_pipeline.svg)

![Liveness seed_tasks](level2/liveness/seed_tasks.svg)

![Liveness sum_weights](level2/liveness/sum_weights.svg)

### Live Range Charts
![Live Ranges depth_expand](level2/liveness/depth_expand_ranges.svg)

![Live Ranges fanout_walk](level2/liveness/fanout_walk_ranges.svg)

![Live Ranges log_progress](level2/liveness/log_progress_ranges.svg)

![Live Ranges run_pipeline](level2/liveness/run_pipeline_ranges.svg)

![Live Ranges seed_tasks](level2/liveness/seed_tasks_ranges.svg)

![Live Ranges sum_weights](level2/liveness/sum_weights_ranges.svg)

### Calling Context Trees
#### level2_cct.txt
```
-- progress snapshot --
task #0 weight=5 fanout=2
task #1 weight=8 fanout=3
task #2 weight=11 fanout=4
task #3 weight=14 fanout=5
task #4 weight=17 fanout=2
total weight=55
=== Calling Context Tree ===
main [1]
  seed_tasks [1]
  run_pipeline [1]
    sum_weights [3]
    fanout_walk [5]
      depth_expand [5]
        depth_expand [16]
          depth_expand [39]
            depth_expand [78]
              depth_expand [108]
                depth_expand [120]
  log_progress [1]
    sum_weights [1]
    print_task [5]
```


