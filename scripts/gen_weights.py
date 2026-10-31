#!/usr/bin/env python3
"""Generate a sparse excitatory/inhibitory weight matrix (signed int8) -> weights.hex.
Index = src*N + dst. Inhibitory sources: neurons 4, 9, 14. No self-connections."""
import random, sys

N = 16
P_CONN = 0.30
SEED = 2026

def main(path="weights.hex"):
    rng = random.Random(SEED)
    inhibitory = {i for i in range(N) if i % 5 == 4}
    w = [[0] * N for _ in range(N)]
    for s in range(N):
        for d in range(N):
            if s == d or rng.random() > P_CONN:
                continue
            w[s][d] = -rng.randint(16, 60) if s in inhibitory else rng.randint(8, 40)
    with open(path, "w") as f:
        for s in range(N):
            for d in range(N):
                f.write(f"{w[s][d] & 0xFF:02x}\n")
    print(f"wrote {path}: {N*N} weights, {sum(1 for r in w for x in r if x)} non-zero")

if __name__ == "__main__":
    main(*sys.argv[1:])
