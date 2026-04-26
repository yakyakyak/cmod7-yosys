// Integration testbench: UART register read/write via top module
// Tests: ping, read VERSION, write LED/PWM registers, read-back, NAK on bad addr

`timescale 1ns / 1ps

module tb_uart_reg;

    localparam CLK_FREQ    = 12_000_000;
    localparam BAUD_RATE   = 115_200;
    localparam CLK_PERIOD  = 83;          // 1/12MHz ≈ 83.33 ns, truncated
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;  // 104

    // DUT signals
    reg        clk             = 0;
    wire [1:0] led;
    /* verilator lint_off UNUSEDSIGNAL */
    wire       pio1;
    /* verilator lint_on UNUSEDSIGNAL */
    reg        uart_rxd_in_reg = 1;       // idle high
    wire       uart_rxd_in;
    wire       uart_txd_out;

    assign uart_rxd_in = uart_rxd_in_reg;

    top dut (
        .clk          (clk),
        .led          (led),
        .pio1         (pio1),
        .uart_rxd_in  (uart_rxd_in),
        .uart_txd_out (uart_txd_out)
    );

    /* verilator lint_off BLKSEQ */
    always #(CLK_PERIOD/2) clk = ~clk;
    /* verilator lint_on BLKSEQ */

    // Track pass/fail
    integer pass_count = 0;
    integer fail_count = 0;

    // Send one byte over UART (drives uart_rxd_in)
    task send_byte;
        input [7:0] data;
        integer i;
        begin
            // Start bit
            uart_rxd_in_reg = 0;
            repeat (CLKS_PER_BIT) @(posedge clk);
            // Data bits LSB first
            for (i = 0; i < 8; i = i + 1) begin
                uart_rxd_in_reg = data[i];
                repeat (CLKS_PER_BIT) @(posedge clk);
            end
            // Stop bit
            uart_rxd_in_reg = 1;
            repeat (CLKS_PER_BIT) @(posedge clk);
        end
    endtask

    // Receive one byte from uart_txd_out, check it equals expected
    task recv_byte;
        input [7:0] expected;
        input [63:0] test_name;  // 8-char tag for display
        reg [7:0] received;
        integer i;
        begin
            received = 0;
            // Wait for start bit (line goes low)
            while (uart_txd_out !== 1'b0) @(posedge clk);
            // Advance to center of start bit
            repeat (CLKS_PER_BIT / 2) @(posedge clk);
            // Sample 8 data bits, one per bit period
            for (i = 0; i < 8; i = i + 1) begin
                repeat (CLKS_PER_BIT) @(posedge clk);
                received[i] = uart_txd_out;
            end
            // Step past stop bit before returning
            repeat (CLKS_PER_BIT) @(posedge clk);

            if (received === expected) begin
                $display("  PASS [%s] got 0x%02X", test_name, received);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL [%s] expected 0x%02X, got 0x%02X",
                         test_name, expected, received);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("build/tb_uart_reg.vcd");
        $dumpvars(0, tb_uart_reg);

        $display("==============================================");
        $display("UART Register Interface Testbench");
        $display("==============================================");

        // Wait for design to settle
        repeat (20) @(posedge clk);

        // --- Test 1: Ping ---
        $display("\n[1] Ping");
        send_byte("P");
        recv_byte("P", "ping");

        // --- Test 2: Read VERSION register (0x07 → 0xA7) ---
        $display("\n[2] Read VERSION (reg 0x07)");
        send_byte("R");
        send_byte(8'h07);
        recv_byte("A",    "ack");
        recv_byte(8'h07,  "addr");
        recv_byte(8'hA7,  "data");

        // --- Test 3: Write LED_MODE = 1 (manual LED control) ---
        $display("\n[3] Write LED_MODE=1 (reg 0x01)");
        send_byte("W");
        send_byte(8'h01);
        send_byte(8'h01);
        recv_byte("A",   "ack");
        recv_byte(8'h01, "addr");
        recv_byte(8'h01, "data");

        // --- Test 4: Write LED_CTRL = 0x03 (both LEDs on) ---
        $display("\n[4] Write LED_CTRL=0x03 (reg 0x00)");
        send_byte("W");
        send_byte(8'h00);
        send_byte(8'h03);
        recv_byte("A",   "ack");
        recv_byte(8'h00, "addr");
        recv_byte(8'h03, "data");

        // Verify LEDs are now driven by registers
        @(posedge clk);
        if (led === 2'b11) begin
            $display("  PASS [leds] led = 2'b11");
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL [leds] expected 2'b11, got 2'b%b", led);
            fail_count = fail_count + 1;
        end

        // --- Test 5: Read LED_CTRL back (reg 0x00) ---
        $display("\n[5] Read LED_CTRL (reg 0x00)");
        send_byte("R");
        send_byte(8'h00);
        recv_byte("A",   "ack");
        recv_byte(8'h00, "addr");
        recv_byte(8'h03, "data");

        // --- Test 6: Write PWM_DUTY = 0x80, PWM_MODE = 1 ---
        $display("\n[6] Write PWM_DUTY=0x80 (reg 0x02)");
        send_byte("W");
        send_byte(8'h02);
        send_byte(8'h80);
        recv_byte("A",   "ack");
        recv_byte(8'h02, "addr");
        recv_byte(8'h80, "data");

        $display("\n[7] Write PWM_MODE=1 (reg 0x03)");
        send_byte("W");
        send_byte(8'h03);
        send_byte(8'h01);
        recv_byte("A",   "ack");
        recv_byte(8'h03, "addr");
        recv_byte(8'h01, "data");

        // --- Test 7: NAK on invalid address ---
        $display("\n[8] Read invalid addr 0x0F → NAK");
        send_byte("R");
        send_byte(8'h0F);
        recv_byte("N",   "nak");
        recv_byte(8'h0F, "addr");

        // --- Test 8: Write to invalid address → NAK ---
        $display("\n[9] Write invalid addr 0xFF → NAK");
        send_byte("W");
        send_byte(8'hFF);
        send_byte(8'h42);
        recv_byte("N",    "nak");
        recv_byte(8'hFF,  "addr");

        // --- Summary ---
        $display("\n==============================================");
        $display("Results: %0d passed, %0d failed", pass_count, fail_count);
        $display("==============================================");
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

endmodule
