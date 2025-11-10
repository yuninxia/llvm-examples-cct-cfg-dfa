add_executable(example_branch level1/branch.c)
target_link_libraries(example_branch PRIVATE cct_runtime)

add_executable(example_calls level1/calls.c)
target_link_libraries(example_calls PRIVATE cct_runtime)

add_executable(example_level2
  level2/main.c
  level2/dispatcher.c
  level2/stats.c)
target_link_libraries(example_level2 PRIVATE cct_runtime)
target_include_directories(example_level2 PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/level2)
