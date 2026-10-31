// -----------------------------------------------------------------------------
// lif_neuron.v - fixed-point Leaky Integrate-and-Fire neuron (Q8.8, 16-bit)
//
//   v[t+1] = v[t] - (v[t] >>> LEAK_SHIFT) + BIAS + noise + i_syn
//   if v[t+1] >= THRESH : emit spike, v <= V_RESET, enter REFRAC ticks of silence
//
// * One state update per `tick` pulse (decouples biological time from clk).
// * 16-bit Galois LFSR provides cheap, deterministic, synthesizable noise.
// * Internal arithmetic is 18-bit signed and saturates at the 16-bit minimum.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps
module lif_neuron #(
    parameter integer LEAK_SHIFT = 4,
    parameter signed [15:0] THRESH  = 16'sd256,   // 1.0 in Q8.8
    parameter signed [15:0] V_RESET = 16'sd0,
    parameter integer REFRAC = 3,
    parameter signed [15:0] BIAS = 16'sd20,
    parameter [15:0] SEED = 16'hACE1
) (
    input  wire               clk,
    input  wire               rst,
    input  wire               tick,
    input  wire signed [15:0] i_syn,
    output reg                spike,
    output reg  signed [15:0] v_mem
);
    reg [15:0] lfsr;
    reg [3:0]  refr;

    wire signed [17:0] v_ext  = v_mem;
    wire signed [17:0] leak   = v_ext >>> LEAK_SHIFT;
    wire signed [17:0] bias_e = BIAS;
    wire signed [17:0] syn_e  = i_syn;
    wire signed [17:0] noise  = {15'b0, lfsr[2:0]};
    wire signed [17:0] v_next = v_ext - leak + bias_e + syn_e + noise;

    wire fire = (v_next >= THRESH);
    wire signed [15:0] v_sat = (v_next < -18'sd32768) ? -16'sd32768 : v_next[15:0];

    always @(posedge clk) begin
        if (rst) begin
            v_mem <= V_RESET;
            spike <= 1'b0;
            refr  <= 4'd0;
            lfsr  <= SEED;
        end else if (tick) begin
            lfsr <= (lfsr >> 1) ^ (lfsr[0] ? 16'hB400 : 16'h0000);
            if (refr != 4'd0) begin
                refr  <= refr - 4'd1;
                spike <= 1'b0;
                v_mem <= V_RESET;
            end else if (fire) begin
                spike <= 1'b1;
                v_mem <= V_RESET;
                refr  <= REFRAC[3:0];
            end else begin
                spike <= 1'b0;
                v_mem <= v_sat;
            end
        end
    end
endmodule
