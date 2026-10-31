`timescale 1ns/1ps
// Drives a tick every 4 clocks and logs the spike vector after each tick to
// sim_out/rtl_spikes.txt (compared against the Python golden model).
module tb_snn_core;
    localparam integer N = 16;
    localparam integer TICKS = 2000;

    reg clk = 0, rst = 1, tick = 0, tick_d = 0;
    wire [N-1:0] spikes;
    integer fd, n_ticks;

    snn_core #(.N(N), .WFILE("weights.hex")) dut (.clk(clk), .rst(rst), .tick(tick), .spikes(spikes));

    always #5 clk = ~clk;                          // 100 MHz
    always @(posedge clk) begin
        tick_d <= tick;
        if (tick_d) begin
            $fdisplay(fd, "%04x", spikes);
            n_ticks = n_ticks + 1;
        end
    end

    initial begin
        fd = $fopen("sim_out/rtl_spikes.txt", "w");
        n_ticks = 0;
        repeat (5) @(negedge clk);
        rst = 0;
        repeat (TICKS) begin
            repeat (3) @(negedge clk);
            tick = 1; @(negedge clk); tick = 0;
        end
        repeat (4) @(negedge clk);
        $fclose(fd);
        $display("tb done: %0d ticks logged", n_ticks);
        $finish;
    end
endmodule
