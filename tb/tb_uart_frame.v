`timescale 1ns/1ps
// Checks the UART stream of snn_top: finds 0xA5 headers and counts complete frames.
module tb_uart_frame;
    reg clk = 0, btn_rst = 1;
    wire txd; wire [7:0] led;
    snn_top #(.CLK_HZ(1_000_000), .TICK_HZ(1000), .BAUD(100_000)) dut (
        .clk(clk), .btn_rst(btn_rst), .uart_txd(txd), .led(led));
    always #500 clk = ~clk;                         // 1 MHz sim clock -> 10 clk/bit

    integer frames = 0, bad = 0;
    reg [7:0] b0, b1, b2;
    task recv(output [7:0] d);
        integer i;
        begin
            @(negedge txd);                         // start bit
            repeat (15) @(posedge clk);             // middle of first data bit
            for (i = 0; i < 8; i = i + 1) begin d[i] = txd; repeat (10) @(posedge clk); end
        end
    endtask

    initial begin
        repeat (10) @(posedge clk); btn_rst = 0;
        while (frames < 20) begin
            recv(b0);
            if (b0 == 8'hA5) begin recv(b1); recv(b2); frames = frames + 1; end
            else bad = bad + 1;
        end
        $display("uart frames received: %0d (header resyncs: %0d)", frames, bad);
        $finish;
    end
    initial begin #400_000_000; $display("TIMEOUT"); $finish; end
endmodule
