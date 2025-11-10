# llvm-examples-cct-cfg-dfa

Learning repo with **LLVM-based** examples in C/C++ for:
- **Calling Context Trees (CCT)** via a tiny instrumentation pass + runtime
- **Control-Flow Graphs (CFG)** by emitting GraphViz `.dot` files
- **Data-flow analysis** (backward **liveness** over LLVM IR)

> Works with LLVM **17+** (tested with the New Pass Manager APIs).

---

## Quick start

### 1) Build

```bash
# Adjust LLVM_DIR to your installation:
# cmake -S . -B build -DLLVM_DIR=$(llvm-config --cmakedir)
cmake -S . -B build -DLLVM_DIR=$(llvm-config --cmakedir)
cmake --build build -j
```

Notes:
- Plugins are built as `.so`/`.dylib`/`.dll` under `build/plugins/...`.
- The tiny CCT runtime is built as `libcct_runtime` under `build/runtime`.

### 2) Examples: compile to LLVM IR

```bash
# Emit IR for the Level 1 examples
clang -emit-llvm -S examples/level1/branch.c -o build/branch.ll
clang -emit-llvm -S examples/level1/calls.c  -o build/calls.ll
```

### 3) CFG: emit `.dot` graphs per function

```bash
LLVM_EXAMPLES_OUTDIR=output/level1 opt -load-pass-plugin build/plugins/CFGDot/CFGDot$([[ "$OSTYPE" == "darwin"* ]] && echo .dylib || echo .so) \
    -passes="function(cfg-dot)" -disable-output build/branch.ll
# DOT files will be in ./output/level1/cfg/*.dot
# Render with graphviz:
dot -Tpng output/level1/cfg/foo.dot -o output/level1/cfg/foo.png
```

### 4) Liveness (backward data-flow)

```bash
LLVM_EXAMPLES_OUTDIR=output/level1 opt -load-pass-plugin build/plugins/DataFlow/Liveness$([[ "$OSTYPE" == "darwin"* ]] && echo .dylib || echo .so) \
    -passes="function(liveness)" -disable-output build/branch.ll
# Results written to ./output/level1/liveness/<function>.txt
```

### 5) CCT: instrument & run (two ways)

**Option A — via `opt` on IR:**

```bash
opt -load-pass-plugin build/plugins/CCTInstrument/CCTInstrument$([[ "$OSTYPE" == "darwin"* ]] && echo .dylib || echo .so) \
    -passes="function(cct-instrument)" build/calls.ll -o build/calls.instrumented.bc

clang build/calls.instrumented.bc build/runtime/libcct_runtime.a -o build/calls_cct
./build/calls_cct
# A textual Calling Context Tree prints at program exit.
```

**Option B — directly from `clang` using the pass plugin:**

```bash
clang examples/level1/calls.c -O0 -g -Xclang -disable-O0-optnone \
  -fpass-plugin=build/plugins/CCTInstrument/CCTInstrument$([[ "$OSTYPE" == "darwin"* ]] && echo .dylib || echo .so) \
  -L build/runtime -lcct_runtime -o build/calls_cct
./build/calls_cct
```

### 6) Level 2 multi-file pipeline example

`examples/level2/` contains a heavier workload that exercises recursion, loops, and cross-translation-unit calls. The `runme.sh` helper rebuilds the repo, links this example into a single module, runs every pass, and drops artifacts under `output/level2/`:

```bash
./runme.sh
# Inspect output/level2/ir/module.ll, output/level2/cfg/*.dot, output/level2/liveness/*.txt, output/level2/cct/level2_cct.txt
```

Prefer manual steps? Compile each C file in `examples/level2/` to LLVM bitcode (`clang -O0 -Xclang -disable-O0-optnone -emit-llvm -c ...`), combine them with `llvm-link` (producing something like `level2-module.ll`), set `LLVM_EXAMPLES_OUTDIR=output/level2`, and invoke the `opt` commands above on the linked module.

> Passes always write generated artifacts under `./output` (default) or under the directory pointed to `LLVM_EXAMPLES_OUTDIR` (e.g., `output/level1/cfg`). Remove the directory (or override the env var) if you need a clean slate.

> The `-fpass-plugin` driver flag loads LLVM **pass plugins** in `clang` (analogous to `opt -load-pass-plugin=...`).

---

## What each piece does

- `plugins/CCTInstrument/` – function pass that injects calls to `__cct_enter/exit` at function entry/returns; see `runtime/` below.
- `plugins/CFGDot/` – function pass that writes a **GraphViz DOT** file per IR function using successor edges.
- `plugins/DataFlow/` – a small **backward liveness** analysis over LLVM IR registers (SSA values).
- `runtime/` – tiny thread-aware C++ runtime that maintains a **Calling Context Tree** and prints it at exit.

---

## Minimal prerequisites

- LLVM/Clang **17+** with CMake config files (i.e., `llvm-config --cmakedir` works)
- CMake 3.20+, a C++17 compiler
- (optional) Graphviz `dot` to render CFGs

---

## FAQ

**Q: How do I use these passes with LTO?**  
A: The same plugin works with the new PM in LTO contexts via `-load-pass-plugin`/`--lto-newpm-passes` (see LLVM docs; examples in issue trackers linked in code comments).

**Q: Why is liveness interesting in SSA?**  
A: Even though SSA makes *reaching definitions* trivial for registers, **liveness** remains useful (e.g., for register allocation, dead-code cleanup heuristics, debug info).

---

## License

MIT; see `LICENSE`.
