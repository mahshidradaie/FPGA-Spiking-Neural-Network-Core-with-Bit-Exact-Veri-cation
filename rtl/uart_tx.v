// uart_tx.v - minimal 8N1 UART transmitter
`timescale 1ns/1ps
module uart_tx #(parameter integer CLKS_PER_BIT = 868) (   // 100 MHz / 115200
    input  wire       clk,
    input  wire       rst,
    input  wire       valid,
    input  wire [7:0] data,
    output wire       ready,
    output reg        tx
);
    localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;
    reg [1:0]  state;
    reg [15:0] cnt;
    reg [2:0]  bit_i;
    reg [7:0]  sh;
    assign ready = (state == IDLE);

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE; tx <= 1'b1; cnt <= 0; bit_i <= 0; sh <= 0;
        end else case (state)
            IDLE:  begin tx <= 1'b1; if (valid) begin sh <= data; cnt <= 0; state <= START; end end
            START: begin tx <= 1'b0;
                     if (cnt == CLKS_PER_BIT-1) begin cnt <= 0; bit_i <= 0; state <= DATA; end
                     else cnt <= cnt + 1; end
            DATA:  begin tx <= sh[bit_i];
                     if (cnt == CLKS_PER_BIT-1) begin
                         cnt <= 0;
                         if (bit_i == 3'd7) state <= STOP; else bit_i <= bit_i + 1;
                     end else cnt <= cnt + 1; end
            STOP:  begin tx <= 1'b1;
                     if (cnt == CLKS_PER_BIT-1) begin cnt <= 0; state <= IDLE; end
                     else cnt <= cnt + 1; end
        endcase
    end
endmodule
