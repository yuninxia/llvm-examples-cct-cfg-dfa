#!/bin/bash
# Batch convert all DOT files to multiple formats

set -euo pipefail

OUTDIR=${1:-output}

echo "=== CFG Visualization Script ==="
echo "Output directory: $OUTDIR"

for level in level1 level2; do
  CFG_DIR="$OUTDIR/$level/cfg"
  if [ -d "$CFG_DIR" ]; then
    echo "Processing $level CFGs..."

    # Count DOT files
    dot_count=$(find "$CFG_DIR" -name "*.dot" 2>/dev/null | wc -l)
    if [ "$dot_count" -eq 0 ]; then
      echo "  No DOT files found in $CFG_DIR"
      continue
    fi

    echo "  Found $dot_count DOT files"

    for dot in "$CFG_DIR"/*.dot; do
      if [ -f "$dot" ]; then
        base=$(basename "$dot" .dot)
        echo "  Converting $base.dot..."

        if command -v dot &> /dev/null; then
          dot -Tsvg "$dot" -o "$CFG_DIR/${base}.svg" 2>/dev/null || echo "    Warning: Failed to generate SVG"

          echo "    Generated ${base}.svg"
        else
          echo "    Error: GraphViz 'dot' command not found. Install with: sudo apt-get install graphviz"
          exit 1
        fi
      fi
    done

    echo "  Completed $level CFG visualization"
  else
    echo "Directory $CFG_DIR does not exist, skipping..."
  fi
done

echo "=== CFG Visualization Complete ==="

# Show summary
for level in level1 level2; do
  CFG_DIR="$OUTDIR/$level/cfg"
  if [ -d "$CFG_DIR" ]; then
    svg_count=$(find "$CFG_DIR" -name "*.svg" 2>/dev/null | wc -l)
    echo "$level: $svg_count SVG files"
  fi
done
