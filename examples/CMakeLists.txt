add_executable(example_branch examples/branch.c)
target_link_libraries(example_branch PRIVATE cct_runtime)

add_executable(example_calls examples/calls.c)
target_link_libraries(example_calls PRIVATE cct_runtime)
