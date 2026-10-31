#!/usr/bin/env python3
"""Bit-accurate Python golden model of rtl/snn_core.v (same integer arithmetic).
Usage: golden_model.py weights.hex TICKS out.txt  (one 16-bit hex spike vector per tick)"""
import sys

N, LEAK_SHIFT, THRESH, V_RESET, REFRAC = 16, 4, 256, 0, 3
BIAS_BASE, BIAS_STEP = 14, 1

def s8(x):
    return x - 256 if x & 0x80 else x

def load_weights(path):
    raw = [int(l.strip(), 16) for l in open(path) if l.strip()]
    return [[s8(raw[s * N + d]) for d in range(N)] for s in range(N)]

def simulate(weights_path, ticks):
    W = load_weights(weights_path)
    v = [V_RESET] * N
    refr = [0] * N
    lfsr = [(0xACE1 + j * 0x0101) & 0xFFFF for j in range(N)]
    bias = [BIAS_BASE + j * BIAS_STEP for j in range(N)]
    spikes = [0] * N
    out = []
    for _ in range(ticks):
        prev = spikes[:]
        new_spikes = [0] * N
        for j in range(N):
            i_syn = sum(W[s][j] for s in range(N) if prev[s])
            noise = lfsr[j] & 7
            v_next = v[j] - (v[j] >> LEAK_SHIFT) + bias[j] + i_syn + noise
            lfsr[j] = (lfsr[j] >> 1) ^ (0xB400 if lfsr[j] & 1 else 0)
            if refr[j]:
                refr[j] -= 1
                v[j] = V_RESET
            elif v_next >= THRESH:
                new_spikes[j] = 1
                v[j] = V_RESET
                refr[j] = REFRAC
            else:
                v[j] = max(v_next, -32768)
        spikes = new_spikes
        out.append(sum(b << j for j, b in enumerate(spikes)))
    return out

if __name__ == "__main__":
    wpath, ticks, outp = sys.argv[1], int(sys.argv[2]), sys.argv[3]
    with open(outp, "w") as f:
        for word in simulate(wpath, ticks):
            f.write(f"{word:04x}\n")
