#!/usr/bin/env python3
"""
Visualize liveness analysis output as heatmaps and live range charts.
"""

import re
import sys
import matplotlib
matplotlib.use('Agg')  # Use non-interactive backend
import matplotlib.pyplot as plt
import matplotlib.patches as patches
import numpy as np
from pathlib import Path

def parse_liveness_file(filepath):
    """Parse liveness analysis output from text file"""
    with open(filepath, 'r') as f:
        content = f.read()

    blocks = []
    # Pattern to match BasicBlock address and IN/OUT sets
    pattern = r'BasicBlock (0x[0-9a-f]+):\s+IN\s+=\s+\{([^}]*)\}\s+OUT\s+=\s+\{([^}]*)\}'

    for match in re.finditer(pattern, content):
        block_id = match.group(1)
        in_vars = [v.strip() for v in match.group(2).split(',') if v.strip()]
        out_vars = [v.strip() for v in match.group(3).split(',') if v.strip()]

        blocks.append({
            'id': block_id,
            'in': set(in_vars) if in_vars else set(),
            'out': set(out_vars) if out_vars else set()
        })

    return blocks

def create_liveness_heatmap(blocks, output_path):
    """Create a heatmap visualization of liveness analysis"""
    if not blocks:
        print(f"  No blocks found in {output_path}")
        return False

    # Collect all variables
    all_vars = set()
    for block in blocks:
        all_vars.update(block['in'])
        all_vars.update(block['out'])

    if not all_vars:
        print(f"  No live variables found")
        return False

    var_list = sorted(list(all_vars))
    n_blocks = len(blocks)
    n_vars = len(var_list)

    # Create matrix: rows=blocks, cols=variables*2 (IN/OUT)
    matrix = np.zeros((n_blocks, n_vars * 2))

    for i, block in enumerate(blocks):
        for j, var in enumerate(var_list):
            if var in block['in']:
                matrix[i, j*2] = 1
            if var in block['out']:
                matrix[i, j*2 + 1] = 1

    # Create figure
    fig_width = max(8, n_vars * 1.5)
    fig_height = max(4, n_blocks * 0.5)
    fig, ax = plt.subplots(figsize=(fig_width, fig_height))

    # Plot heatmap
    im = ax.imshow(matrix, cmap='RdYlGn', aspect='auto', interpolation='nearest')

    # Set up x-axis (variables)
    ax.set_xticks(range(n_vars * 2))
    labels = []
    for var in var_list:
        labels.extend([f"{var}\nIN", f"{var}\nOUT"])
    ax.set_xticklabels(labels, rotation=45, ha='right')

    # Set up y-axis (blocks)
    ax.set_yticks(range(n_blocks))
    ax.set_yticklabels([f"BB{i}" for i in range(n_blocks)])

    # Add vertical lines between variables
    for i in range(n_vars):
        if i > 0:
            ax.axvline(x=i*2 - 0.5, color='black', linewidth=1, alpha=0.3)

    # Add title and labels
    func_name = Path(output_path).stem
    plt.title(f'Liveness Analysis: {func_name}')
    plt.xlabel('Variables (IN/OUT sets)')
    plt.ylabel('Basic Blocks')

    # Add colorbar
    cbar = plt.colorbar(im, ax=ax, label='Live (green) / Dead (red)')

    # Add grid
    ax.set_xticks(np.arange(-.5, n_vars*2, 1), minor=True)
    ax.set_yticks(np.arange(-.5, n_blocks, 1), minor=True)
    ax.grid(which="minor", color="gray", linestyle='-', linewidth=0.5, alpha=0.3)

    plt.tight_layout()

    svg_path = Path(output_path).with_suffix('.svg')
    fig.savefig(svg_path, format='svg', bbox_inches='tight')
    plt.close(fig)

    return svg_path

def create_live_range_chart(blocks, output_path):
    """Create a live range chart showing variable lifetimes across blocks"""
    if not blocks:
        return False

    # Collect all variables
    all_vars = set()
    for block in blocks:
        all_vars.update(block['in'])
        all_vars.update(block['out'])

    if not all_vars:
        return False

    var_list = sorted(list(all_vars))
    n_blocks = len(blocks)
    n_vars = len(var_list)

    # Create figure
    fig_width = max(10, n_blocks * 1.5)
    fig_height = max(6, n_vars * 0.5)
    fig, ax = plt.subplots(figsize=(fig_width, fig_height))

    # Plot live ranges
    colors = plt.cm.Set3(np.linspace(0, 1, n_vars))

    for var_idx, var in enumerate(var_list):
        live_blocks = []
        for block_idx, block in enumerate(blocks):
            if var in block['in'] or var in block['out']:
                live_blocks.append(block_idx)

        if live_blocks:
            # Draw continuous line for live range
            y_pos = var_idx
            for i in range(len(live_blocks)):
                if i == 0 or live_blocks[i] != live_blocks[i-1] + 1:
                    # Start new segment
                    start = live_blocks[i]
                    end = start
                    # Find end of continuous segment
                    j = i + 1
                    while j < len(live_blocks) and live_blocks[j] == live_blocks[j-1] + 1:
                        end = live_blocks[j]
                        j += 1

                    # Draw the line segment
                    ax.plot([start, end + 1], [y_pos, y_pos],
                           color=colors[var_idx], linewidth=6, alpha=0.7)

                    # Add markers at endpoints
                    ax.scatter([start, end + 1], [y_pos, y_pos],
                             color=colors[var_idx], s=50, zorder=5)

    # Set up axes
    ax.set_xlim(-0.5, n_blocks + 0.5)
    ax.set_ylim(-0.5, n_vars - 0.5)

    # Labels
    ax.set_xticks(range(n_blocks + 1))
    ax.set_xticklabels([f"BB{i}" for i in range(n_blocks + 1)])
    ax.set_yticks(range(n_vars))
    ax.set_yticklabels(var_list)

    # Add grid
    ax.grid(True, alpha=0.3, linestyle='--')

    # Title and labels
    func_name = Path(output_path).stem.replace('_ranges', '')
    plt.title(f'Live Variable Ranges: {func_name}')
    plt.xlabel('Basic Blocks')
    plt.ylabel('Variables')

    plt.tight_layout()
    range_svg = Path(output_path).with_name(Path(output_path).stem + '_ranges.svg')
    fig.savefig(range_svg, format='svg', bbox_inches='tight')
    plt.close(fig)

    return range_svg

def visualize_all_liveness(base_dir='output'):
    """Process all liveness files in the output directory"""
    base_path = Path(base_dir)

    print("=== Liveness Visualization Script ===")
    print(f"Base directory: {base_dir}")

    for level in ['level1', 'level2']:
        liveness_dir = base_path / level / 'liveness'

        if not liveness_dir.exists():
            print(f"{level}: Directory {liveness_dir} does not exist, skipping...")
            continue

        txt_files = list(liveness_dir.glob('*.txt'))

        if not txt_files:
            print(f"{level}: No liveness .txt files found")
            continue

        print(f"\nProcessing {level} liveness files...")
        print(f"  Found {len(txt_files)} liveness files")

        for txt_file in txt_files:
            print(f"  Processing {txt_file.name}...")

            blocks = parse_liveness_file(txt_file)

            if blocks:
                # Generate heatmap
                heatmap_svg = create_liveness_heatmap(blocks, txt_file)
                if heatmap_svg:
                    print(f"    Created heatmap: {Path(heatmap_svg).name}")

                # Generate live range chart
                range_svg = create_live_range_chart(blocks, txt_file)
                if range_svg:
                    print(f"    Created range chart: {Path(range_svg).name}")
            else:
                print(f"    Warning: No blocks found in {txt_file.name}")

    print("\n=== Liveness Visualization Complete ===")

    # Show summary
    for level in ['level1', 'level2']:
        liveness_dir = base_path / level / 'liveness'
        if liveness_dir.exists():
            svg_count = len(list(liveness_dir.glob('*.svg')))
            print(f"{level}: Generated {svg_count} SVG visualization files")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        visualize_all_liveness(sys.argv[1])
    else:
        visualize_all_liveness()
