// -----------------------------------------------------------------------------
// snn_top.v - board-level wrapper: 1 kHz neuron tick + UART spike streaming.
// Frame per tick (3 bytes @115200 8N1): 0xA5, spikes[15:8], spikes[7:0]
// The 8 low spike lines are also mapped to LEDs for quick visual checks.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps
module snn_top #(
    parameter integer CLK_HZ   = 100_000_000,
    parameter integer TICK_HZ  = 1000,
    parameter integer BAUD     = 115200
) (
    input  wire       clk,
    input  wire       btn_rst,
    output wire       uart_txd,
    output wire [7:0] led
);
    localparam integer TICK_DIV = CLK_HZ / TICK_HZ;

    // synchronous reset release
    reg [2:0] rst_sh = 3'b111;
    always @(posedge clk) rst_sh <= {rst_sh[1:0], btn_rst};
    wire rst = rst_sh[2];

    reg [31:0] div = 0;
    reg tick = 0, tick_d = 0;
    always @(posedge clk) begin
        if (rst) begin div <= 0; tick <= 0; tick_d <= 0; end
        else begin
            tick_d <= tick;
            if (div == TICK_DIV-1) begin div <= 0; tick <= 1'b1; end
            else begin div <= div + 1; tick <= 1'b0; end
        end
    end

    wire [15:0] spikes;
    snn_core #(.N(16), .WFILE("weights.hex")) u_core (.clk(clk), .rst(rst), .tick(tick), .spikes(spikes));

    reg [23:0] frame;
    reg [1:0]  idx;
    reg        sending;
    reg        u_valid;
    reg [7:0]  u_data;
    wire       u_ready;

    uart_tx #(.CLKS_PER_BIT(CLK_HZ / BAUD)) u_tx (
        .clk(clk), .rst(rst), .valid(u_valid), .data(u_data), .ready(u_ready), .tx(uart_txd));

    always @(posedge clk) begin
        if (rst) begin sending <= 0; u_valid <= 0; idx <= 0; frame <= 0; u_data <= 0; end
        else begin
            u_valid <= 1'b0;
            if (tick_d && !sending) begin
                frame <= {8'hA5, spikes[15:8], spikes[7:0]};
                idx <= 0; sending <= 1'b1;
            end else if (sending && u_ready && !u_valid) begin
                u_data  <= (idx == 0) ? frame[23:16] : (idx == 1) ? frame[15:8] : frame[7:0];
                u_valid <= 1'b1;
                if (idx == 2) sending <= 1'b0; else idx <= idx + 1;
            end
        end
    end

    // stretch spikes so they are visible on LEDs (~16 ms)
    reg [7:0] hold [0:7];
    integer i;
    always @(posedge clk) begin
        for (i = 0; i < 8; i = i + 1) begin
            if (rst) hold[i] <= 0;
            else if (tick && spikes[i]) hold[i] <= 8'd16;
            else if (tick && hold[i] != 0) hold[i] <= hold[i] - 1;
        end
    end
    assign led = {|hold[7], |hold[6], |hold[5], |hold[4], |hold[3], |hold[2], |hold[1], |hold[0]};
endmodule
