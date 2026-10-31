#!/usr/bin/env python3
"""Plot a spike raster + population rate. Usage: plot_raster.py spikes.txt out.png"""
import sys
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

N = 16
words = [int(l.strip(), 16) for l in open(sys.argv[1]) if l.strip()]
xs, ys = [], []
for t, w in enumerate(words):
    for j in range(N):
        if (w >> j) & 1:
            xs.append(t)
            ys.append(j)
fig, (a0, a1) = plt.subplots(2, 1, figsize=(9, 5), sharex=True, gridspec_kw={"height_ratios": [3, 1]})
a0.scatter(xs, ys, s=3, c="k")
a0.set_ylabel("neuron")
a0.set_title("Spike raster (RTL simulation)")
a1.plot([bin(w).count("1") for w in words], lw=0.6)
a1.set_ylabel("spikes/tick")
a1.set_xlabel("tick (1 tick = 1 ms)")
fig.tight_layout()
fig.savefig(sys.argv[2], dpi=150)
print("saved", sys.argv[2])
