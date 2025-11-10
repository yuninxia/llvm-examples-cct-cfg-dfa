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
# Emit IR for the examples
clang -emit-llvm -S examples/branch.c -o build/branch.ll
clang -emit-llvm -S examples/calls.c  -o build/calls.ll
```

### 3) CFG: emit `.dot` graphs per function

```bash
opt -load-pass-plugin build/plugins/CFGDot/libCFGDot$([[ "$OSTYPE" == "darwin"* ]] && echo .dylib || echo .so) \
    -passes="function(cfg-dot)" -disable-output build/branch.ll
# DOT files will be in ./cfg/*.dot
# Render with graphviz:
dot -Tpng cfg/foo.dot -o cfg/foo.png
```

### 4) Liveness (backward data-flow)

```bash
opt -load-pass-plugin build/plugins/DataFlow/libLiveness$([[ "$OSTYPE" == "darwin"* ]] && echo .dylib || echo .so) \
    -passes="function(liveness)" -disable-output build/branch.ll
# Results written to ./liveness/<function>.txt
```

### 5) CCT: instrument & run (two ways)

**Option A — via `opt` on IR:**

```bash
opt -load-pass-plugin build/plugins/CCTInstrument/libCCTInstrument$([[ "$OSTYPE" == "darwin"* ]] && echo .dylib || echo .so) \
    -passes="function(cct-instrument)" build/calls.ll -o build/calls.instrumented.bc

clang build/calls.instrumented.bc build/runtime/libcct_runtime.a -o build/calls_cct
./build/calls_cct
# A textual Calling Context Tree prints at program exit.
```

**Option B — directly from `clang` using the pass plugin:**

```bash
clang examples/calls.c -O0 -g -Xclang -disable-O0-optnone \
  -fpass-plugin=build/plugins/CCTInstrument/libCCTInstrument$([[ "$OSTYPE" == "darwin"* ]] && echo .dylib || echo .so) \
  -L build/runtime -lcct_runtime -o build/calls_cct
./build/calls_cct
```

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
