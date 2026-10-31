// syn_acc.v - sums the signed 8-bit weights of all pre-synaptic neurons that spiked
`timescale 1ns/1ps
module syn_acc #(parameter integer N = 16) (
    input  wire [N-1:0]          spk,
    input  wire [N*8-1:0]        wcol,   // column of the weight matrix (all sources -> this neuron)
    output reg  signed [15:0]    sum
);
    integer i;
    always @* begin
        sum = 16'sd0;
        for (i = 0; i < N; i = i + 1)
            if (spk[i]) sum = sum + $signed(wcol[i*8 +: 8]);
    end
endmodule
