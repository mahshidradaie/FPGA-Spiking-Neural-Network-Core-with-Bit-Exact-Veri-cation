#!/usr/bin/env python3
"""Compare RTL and golden-model spike logs tick by tick."""
import sys
a = [l.strip() for l in open(sys.argv[1]) if l.strip()]
b = [l.strip() for l in open(sys.argv[2]) if l.strip()]
if len(a) != len(b):
    sys.exit(f"FAIL: length mismatch RTL={len(a)} golden={len(b)}")
bad = [i for i, (x, y) in enumerate(zip(a, b)) if x != y]
if bad:
    i = bad[0]
    sys.exit(f"FAIL: {len(bad)} mismatching ticks, first at tick {i}: RTL={a[i]} golden={b[i]}")
total = sum(bin(int(x, 16)).count("1") for x in a)
print(f"PASS: {len(a)} ticks bit-exact, {total} total spikes")
