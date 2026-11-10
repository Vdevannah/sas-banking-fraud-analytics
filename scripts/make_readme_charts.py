"""Generate the three README charts from the validated SAS results.

The values below are copied verbatim from the SAS output in
reports/phase4_fraud_risk_report.pdf and
reports/phase5_executive_fraud_report.pdf. This script only re-draws
those results with consistent styling; it performs no analysis.

Dependencies:  Python 3.8+ and matplotlib
    pip install matplotlib

Usage (from the repository root):
    python scripts/make_readme_charts.py               # writes to assets/
    python scripts/make_readme_charts.py --out /tmp/x  # writes elsewhere

The original SAS PROC SGPLOT images in assets/sas-original/ are not
touched by this script.
"""
import argparse
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.ticker import StrMethodFormatter

# --- Validated SAS results (do not edit without re-running SAS) -------------
TRUE_POSITIVES = 124          # Combined Rule, Phase 4/5
FALSE_POSITIVES = 22_493      # Combined Rule, Phase 4/5
FRAUD_PREVALENCE_PCT = 0.173  # 492 / 284,807, Phase 5
RULES = ["Zero Amount", "High Amount", "Elapsed Time Window", "Combined Rule"]
RECALL_PCT = [5.49, 7.11, 14.02, 25.20]
PRECISION_PCT = [1.48, 0.37, 0.60, 0.55]

SRC4 = "reports/phase4_fraud_risk_report.pdf"
SRC5 = "reports/phase5_executive_fraud_report.pdf"

# --- Style -------------------------------------------------------------------
SURFACE, INK, INK2, MUTED = "#fcfcfb", "#0b0b0b", "#52514e", "#898781"
GRID, AXIS = "#e1e0d9", "#c3c2b7"
BLUE, BLUE_LIGHT, RED = "#2a78d6", "#86b6ef", "#e34948"
RULE_COLORS = [BLUE_LIGHT, BLUE_LIGHT, BLUE_LIGHT, BLUE]  # highlight Combined

plt.rcParams.update({
    "font.family": ["Helvetica Neue", "Helvetica", "Arial", "DejaVu Sans"],
    "font.size": 13,
    "axes.edgecolor": AXIS,
    "axes.labelcolor": INK2,
    "xtick.color": MUTED,
    "ytick.color": INK,
    "figure.facecolor": SURFACE,
    "axes.facecolor": SURFACE,
    "savefig.facecolor": SURFACE,
})


def new_figure(right=0.92):
    fig, ax = plt.subplots(figsize=(10, 4.6), dpi=200)  # 2000 x 920 px
    fig.subplots_adjust(left=0.24, right=right, top=0.70, bottom=0.2)
    return fig, ax


def finish(fig, ax, title, subtitle, source, path):
    fig.text(0.03, 0.95, title, fontsize=19, fontweight="bold", color=INK, va="top")
    fig.text(0.03, 0.87, subtitle, fontsize=13, color=INK2, va="top")
    fig.text(0.03, 0.03,
             f"Recreated with Matplotlib from validated SAS output · Source: {source}",
             fontsize=10, color=MUTED, va="bottom")
    for side in ("top", "right", "left"):
        ax.spines[side].set_visible(False)
    ax.tick_params(axis="y", length=0, labelsize=13)
    ax.tick_params(axis="x", labelsize=11)
    ax.xaxis.grid(True, color=GRID, linewidth=0.8)
    ax.set_axisbelow(True)
    fig.savefig(path)
    plt.close(fig)
    print(f"wrote {path}")


def hbar(ax, labels, values, colors, fmt, pad):
    y = range(len(labels))
    ax.barh(y, values, height=0.55, color=colors)
    ax.set_yticks(list(y), labels)
    ax.invert_yaxis()
    for i, v in enumerate(values):
        ax.text(v + pad, i, fmt(v), va="center", fontsize=13,
                color=INK, fontweight="bold")


def alert_outcomes(out):
    alerts = TRUE_POSITIVES + FALSE_POSITIVES
    per_detection = FALSE_POSITIVES / TRUE_POSITIVES
    fig, ax = new_figure(right=0.86)
    hbar(ax, ["False positives\n(legitimate)", "True positives\n(confirmed fraud)"],
         [FALSE_POSITIVES, TRUE_POSITIVES], [RED, BLUE],
         lambda v: f"{v:,}  ({v / alerts:.2%} of alerts)", 300)
    ax.set_xlim(0, 30_000)
    ax.xaxis.set_major_formatter(StrMethodFormatter("{x:,.0f}"))
    ax.set_xlabel("Number of alerts")
    finish(fig, ax, "Fraud Alert Outcomes — Combined Rule",
           f"{alerts:,} alerts · ≈{per_detection:.1f} false alerts for every "
           "confirmed fraud case detected",
           SRC5, out / "01_fraud_alert_outcomes.png")


def recall_by_rule(out):
    fig, ax = new_figure()
    hbar(ax, RULES, RECALL_PCT, RULE_COLORS, lambda v: f"{v:.2f}%", 0.4)
    ax.set_xlim(0, 30)
    ax.xaxis.set_major_formatter(StrMethodFormatter("{x:.0f}%"))
    ax.set_xlabel("Recall (% of the 492 confirmed fraud cases flagged)")
    finish(fig, ax, "Fraud Detection Recall by Risk Rule",
           "The Combined Rule flags 124 of 492 fraud cases; 368 are still missed",
           f"{SRC4}, {SRC5}", out / "02_recall_by_rule.png")


def precision_by_rule(out):
    fig, ax = new_figure()
    hbar(ax, RULES, PRECISION_PCT, RULE_COLORS, lambda v: f"{v:.2f}%", 0.025)
    ax.axvline(FRAUD_PREVALENCE_PCT, color=INK2, linestyle=(0, (4, 3)), linewidth=1.2)
    ax.text(FRAUD_PREVALENCE_PCT, -0.62,
            f" Fraud prevalence {FRAUD_PREVALENCE_PCT:.3f}%",
            fontsize=10.5, color=INK2, va="bottom", ha="left")
    ax.set_xlim(0, 1.8)
    ax.set_ylim(3.5, -0.75)
    ax.xaxis.set_major_formatter(StrMethodFormatter("{x:.2f}%"))
    ax.set_xlabel("Precision (% of alerts that are confirmed fraud)")
    finish(fig, ax, "Fraud Detection Precision by Risk Rule",
           "Fewer than 1.5 in 100 alerts are fraud under any rule",
           f"{SRC4}, {SRC5}", out / "03_precision_by_rule.png")


def main():
    default_out = Path(__file__).resolve().parent.parent / "assets"
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--out", type=Path, default=default_out,
                        help="output directory (default: assets/)")
    out = parser.parse_args().out
    out.mkdir(parents=True, exist_ok=True)
    alert_outcomes(out)
    recall_by_rule(out)
    precision_by_rule(out)


if __name__ == "__main__":
    main()
