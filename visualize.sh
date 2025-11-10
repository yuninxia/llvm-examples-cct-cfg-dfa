#!/bin/bash
# Master visualization script - runs analysis and generates all visualizations

set -euo pipefail

echo "================================="
echo "LLVM Analysis & Visualization"
echo "================================="

# 1. Run the analysis (optional)
if [[ "${SKIP_RUNME:-0}" == "1" ]]; then
  echo ""
  echo "Step 1: Skipping LLVM analysis (SKIP_RUNME=1)."
else
  echo ""
  echo "Step 1: Running LLVM analysis passes..."
  ./runme.sh
fi

# 2. Generate CFG visualizations
echo ""
echo "Step 2: Generating CFG visualizations..."
./scripts/visualize_cfg.sh output

# 3. Generate liveness visualizations
echo ""
echo "Step 3: Generating liveness analysis visualizations..."
python3 scripts/visualize_liveness.py output

# 4. Generate Markdown report
echo ""
echo "Step 4: Generating Markdown report..."
./scripts/generate_report.sh output

echo ""
echo "================================="
echo "✅ Complete!"
echo "================================="
echo ""
echo "View results:"
echo "  - Inspect output/report.md (paths point into \`output/\`)"
echo "  - Serve \`output/\` via \`python3 -m http.server --directory output\` to browse assets"
echo ""
echo "Output structure:"
echo "  output/"
echo "    ├── level1/"
echo "    │   ├── cfg/       (*.dot, *.svg)"
echo "    │   ├── liveness/  (*.txt, *.svg)"
echo "    │   └── cct/       (*.txt)"
echo "    ├── level2/"
echo "    │   └── (same structure)"
echo "  output/report.md summarizes the latest run (committable alongside other artifacts)."
