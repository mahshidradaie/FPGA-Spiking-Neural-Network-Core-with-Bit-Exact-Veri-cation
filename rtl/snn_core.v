// -----------------------------------------------------------------------------
// snn_core.v - N fully-parallel LIF neurons with a sparse signed synaptic matrix.
// Weights (signed 8-bit, Q8.8 current units) are loaded from WFILE (hex, one byte
// per line, index = src*N + dst). Spikes from tick t-1 drive the input of tick t.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps
module snn_core #(
    parameter integer N = 16,
    parameter integer BIAS_BASE = 14,
    parameter integer BIAS_STEP = 1,
    parameter WFILE = "weights.hex"
) (
    input  wire         clk,
    input  wire         rst,
    input  wire         tick,
    output wire [N-1:0] spikes
);
    reg [7:0]       wmem  [0:N*N-1];
    reg [N*N*8-1:0] wflat;
    integer k;
    initial begin
        $readmemh(WFILE, wmem);
        for (k = 0; k < N*N; k = k + 1) wflat[k*8 +: 8] = wmem[k];
    end

    genvar j, s;
    generate
        for (j = 0; j < N; j = j + 1) begin : g_neuron
            wire [N*8-1:0] wcol;
            for (s = 0; s < N; s = s + 1) begin : g_col
                assign wcol[s*8 +: 8] = wflat[(s*N + j)*8 +: 8];
            end
            wire signed [15:0] i_syn;
            syn_acc #(.N(N)) u_acc (.spk(spikes), .wcol(wcol), .sum(i_syn));

            wire signed [15:0] v_unused;
            lif_neuron #(
                .BIAS(BIAS_BASE + j*BIAS_STEP),
                .SEED(16'hACE1 + j*16'h0101)
            ) u_n (
                .clk(clk), .rst(rst), .tick(tick),
                .i_syn(i_syn), .spike(spikes[j]), .v_mem(v_unused)
            );
        end
    endgenerate
endmodule
