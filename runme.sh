#!/usr/bin/env bash
set -euo pipefail

# Detect LLVM_DIR from spack if not provided.
if [[ -z "${LLVM_DIR:-}" ]]; then
  LLVM_PREFIX=$(spack location -i llvm@17.0.6 2>/dev/null || true)
  if [[ -z "$LLVM_PREFIX" ]]; then
    echo "[runme] LLVM_DIR not set and llvm@17.0.6 not found via spack." >&2
    exit 1
  fi
  export LLVM_DIR="$LLVM_PREFIX/lib/cmake/llvm"
fi

if [[ -z "${LLVM_PREFIX:-}" ]]; then
  LLVM_PREFIX=$(dirname "$(dirname "$(dirname "$LLVM_DIR")")")
fi

echo "[runme] Using LLVM_DIR=$LLVM_DIR"
echo "[runme] Using LLVM_PREFIX=$LLVM_PREFIX"

export PATH="$LLVM_PREFIX/bin:$PATH"
export LD_LIBRARY_PATH="$LLVM_PREFIX/lib:${LD_LIBRARY_PATH:-}"

OUTDIR=${OUTDIR:-output}
rm -rf "$OUTDIR"
for lvl in level1 level2; do
  mkdir -p "$OUTDIR/$lvl/ir" "$OUTDIR/$lvl/cfg" "$OUTDIR/$lvl/liveness" \
           "$OUTDIR/$lvl/bin" "$OUTDIR/$lvl/cct"
done
echo "[runme] Using OUTDIR=$OUTDIR (per-level subdirs under level1/, level2/)"

cmake -S . -B build -DLLVM_DIR="$LLVM_DIR" -DCMAKE_BUILD_TYPE=Release "$@"
cmake --build build -j

mkdir -p build

# Compile Level 1 IR (without optnone to allow pass execution)
clang -O0 -Xclang -disable-O0-optnone -emit-llvm -S examples/level1/branch.c -o "$OUTDIR/level1/ir/branch.ll"
clang -O0 -Xclang -disable-O0-optnone -emit-llvm -S examples/level1/calls.c  -o "$OUTDIR/level1/ir/calls.ll"

# Build the Level 2 multi-file example into a single module
level2_sources=(main dispatcher stats)
level2_objects=()
for src in "${level2_sources[@]}"; do
  bc="$OUTDIR/level2/ir/${src}.bc"
  clang -O0 -Xclang -disable-O0-optnone -emit-llvm -c "examples/level2/${src}.c" -o "$bc"
  level2_objects+=("$bc")
done
llvm-link "${level2_objects[@]}" -o "$OUTDIR/level2/ir/module.bc"
llvm-dis "$OUTDIR/level2/ir/module.bc" -o "$OUTDIR/level2/ir/module.ll"

DLL_EXT=".so"
if [[ "$OSTYPE" == "darwin"* ]]; then
  DLL_EXT=".dylib"
fi

# Level 1 passes and instrumentation
LLVM_EXAMPLES_OUTDIR="$OUTDIR/level1" opt -load-pass-plugin build/plugins/CFGDot/CFGDot${DLL_EXT} \
    -passes="function(cfg-dot)" -disable-output "$OUTDIR/level1/ir/branch.ll"

LLVM_EXAMPLES_OUTDIR="$OUTDIR/level1" opt -load-pass-plugin build/plugins/DataFlow/Liveness${DLL_EXT} \
    -passes="function(liveness)" -disable-output "$OUTDIR/level1/ir/branch.ll"

opt -load-pass-plugin build/plugins/CCTInstrument/CCTInstrument${DLL_EXT} \
    -passes="function(cct-instrument)" "$OUTDIR/level1/ir/calls.ll" -o "$OUTDIR/level1/ir/calls.instrumented.bc"
clang++ "$OUTDIR/level1/ir/calls.instrumented.bc" build/runtime/libcct_runtime.a -o "$OUTDIR/level1/bin/calls_cct"

set +e
"$OUTDIR/level1/bin/calls_cct" | tee "$OUTDIR/level1/cct/calls_cct.txt"
level1_status=${PIPESTATUS[0]}
set -e
if [[ $level1_status -ne 0 ]]; then
  echo "[runme] level1 binary exited with status $level1_status" >&2
fi

# Level 2 passes on the linked module
LLVM_EXAMPLES_OUTDIR="$OUTDIR/level2" opt -load-pass-plugin build/plugins/CFGDot/CFGDot${DLL_EXT} \
    -passes="function(cfg-dot)" -disable-output "$OUTDIR/level2/ir/module.ll"

LLVM_EXAMPLES_OUTDIR="$OUTDIR/level2" opt -load-pass-plugin build/plugins/DataFlow/Liveness${DLL_EXT} \
    -passes="function(liveness)" -disable-output "$OUTDIR/level2/ir/module.ll"

opt -load-pass-plugin build/plugins/CCTInstrument/CCTInstrument${DLL_EXT} \
    -passes="function(cct-instrument)" "$OUTDIR/level2/ir/module.ll" -o "$OUTDIR/level2/ir/module.instrumented.bc"
clang++ "$OUTDIR/level2/ir/module.instrumented.bc" build/runtime/libcct_runtime.a -o "$OUTDIR/level2/bin/level2_cct"

set +e
"$OUTDIR/level2/bin/level2_cct" | tee "$OUTDIR/level2/cct/level2_cct.txt"
level2_status=${PIPESTATUS[0]}
set -e
if [[ $level2_status -ne 0 ]]; then
  echo "[runme] level2 binary exited with status $level2_status" >&2
fi

echo "[runme] Level 1 outputs under $OUTDIR/level1 (IR/cfg/liveness/cct)"
echo "[runme] Level 2 outputs under $OUTDIR/level2 (IR/cfg/liveness/cct)"

if [[ "${RUN_VISUALIZE:-0}" == "1" ]]; then
  echo "[runme] RUN_VISUALIZE=1 -> invoking visualization pipeline"
  SKIP_RUNME=1 ./visualize.sh
fi
