#!/bin/bash
set -euo pipefail

ROOT_DIR=$(pwd)
OUTDIR=${1:-output}
OUTDIR=$(realpath "$OUTDIR")
REPORT_PATH=${2:-$OUTDIR/report.md}
REPORT=$(realpath -m "$REPORT_PATH")
REPORT_DIR=$(dirname "$REPORT")
mkdir -p "$REPORT_DIR"

pretty_name() {
  case "$1" in
    level1) echo "Level 1" ;;
    level2) echo "Level 2" ;;
    *) echo "$1" ;;
  esac
}

mkdir -p "$OUTDIR"

echo "=== Generating Markdown Visualization Report ==="

{
  echo "# LLVM Analysis Visualization Report"
  echo
  echo "Generated on $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  rel_outdir=$(realpath --relative-to="$REPORT_DIR" "$OUTDIR")
  echo "(Artifacts rooted at \`$rel_outdir/\`)"
  echo
} > "$REPORT"

for level in level1 level2; do
  level_dir="$OUTDIR/$level"
  [ -d "$level_dir" ] || continue
  name=$(pretty_name "$level")

  echo "## $name" >> "$REPORT"
  echo >> "$REPORT"

  cfg_svgs=$(find "$level_dir/cfg" -maxdepth 1 -name '*.svg' 2>/dev/null | wc -l || true)
  live_svgs=$(find "$level_dir/liveness" -maxdepth 1 -name '*.svg' 2>/dev/null | wc -l || true)
  cct_txt=$(find "$level_dir/cct" -maxdepth 1 -name '*.txt' 2>/dev/null | wc -l || true)
  echo "- CFG diagrams: $cfg_svgs" >> "$REPORT"
  echo "- Liveness visuals: $live_svgs" >> "$REPORT"
  echo "- CCT captures: $cct_txt" >> "$REPORT"
  echo >> "$REPORT"

  echo "### Control-Flow Graphs" >> "$REPORT"
  have_svg=false
  shopt -s nullglob
  for svg in "$level_dir"/cfg/*.svg; do
    have_svg=true
    rel=$(realpath --relative-to="$REPORT_DIR" "$svg")
    title=$(basename "$svg" .svg)
    echo "![CFG $title]($rel)" >> "$REPORT"
    echo >> "$REPORT"
  done
  shopt -u nullglob
  if ! $have_svg; then
    echo "_No CFG SVGs found in $level_dir/cfg._" >> "$REPORT"
    echo >> "$REPORT"
  fi

  echo "### Liveness Heatmaps" >> "$REPORT"
  have_heat=false
  shopt -s nullglob
  for svg in "$level_dir"/liveness/*.svg; do
    base=$(basename "$svg")
    if [[ "$base" == *_ranges.svg ]]; then
      continue
    fi
    have_heat=true
    rel=$(realpath --relative-to="$REPORT_DIR" "$svg")
    title=${base%.svg}
    echo "![Liveness $title]($rel)" >> "$REPORT"
    echo >> "$REPORT"
  done
  shopt -u nullglob
  if ! $have_heat; then
    echo "_No liveness heatmaps generated._" >> "$REPORT"
    echo >> "$REPORT"
  fi

  echo "### Live Range Charts" >> "$REPORT"
  have_range=false
  shopt -s nullglob
  for svg in "$level_dir"/liveness/*_ranges.svg; do
    have_range=true
    rel=$(realpath --relative-to="$REPORT_DIR" "$svg")
    title=${svg##*/}
    title=${title%_ranges.svg}
    echo "![Live Ranges $title]($rel)" >> "$REPORT"
    echo >> "$REPORT"
  done
  shopt -u nullglob
  if ! $have_range; then
    echo "_No live range charts generated._" >> "$REPORT"
    echo >> "$REPORT"
  fi

  echo "### Calling Context Trees" >> "$REPORT"
  have_cct=false
  shopt -s nullglob
  for txt in "$level_dir"/cct/*.txt; do
    have_cct=true
    title=$(basename "$txt")
    echo "#### $title" >> "$REPORT"
    echo '```' >> "$REPORT"
    cat "$txt" >> "$REPORT"
    echo '```' >> "$REPORT"
    echo >> "$REPORT"
  done
  shopt -u nullglob
  if ! $have_cct; then
    echo "_No CCT transcripts captured._" >> "$REPORT"
    echo >> "$REPORT"
  fi

  echo >> "$REPORT"
done

cat <<EOF
Report generated: $REPORT
View with any Markdown renderer (e.g., VS Code, GitHub preview, or mdbook).
=== Markdown Visualization Report Complete ===
EOF
