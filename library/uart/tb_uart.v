// UART Loopback Testbench
// Wires TX output directly to RX input and verifies data integrity

`timescale 1ns / 1ps

module tb_uart;

    parameter CLK_FREQ   = 12_000_000;
    parameter BAUD_RATE  = 115_200;
    parameter CLK_PERIOD = 83.33;  // 12 MHz

    localparam CLKS_PER_BIT  = CLK_FREQ / BAUD_RATE;
    localparam CLKS_PER_BYTE = CLKS_PER_BIT * 12; // generous: 12 bit-times

    // Testbench signals
    reg        clk = 0;
    reg        rst = 0;
    reg  [7:0] tx_data = 0;
    reg        tx_valid = 0;
    wire       tx_ready;
    wire       serial;      // TX→RX loopback wire
    wire [7:0] rx_data;
    wire       rx_valid;

    reg [31:0] cycle_count = 0;
    reg [31:0] test_pass = 0;
    reg [31:0] test_fail = 0;

    // DUT instantiation
    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) tx_dut (
        .clk(clk),
        .rst(rst),
        .data_i(tx_data),
        .valid_i(tx_valid),
        .ready_o(tx_ready),
        .tx(serial)
    );

    uart_rx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) rx_dut (
        .clk(clk),
        .rst(rst),
        .rx(serial),
        .data_o(rx_data),
        .valid_o(rx_valid)
    );

    // Clock generation
    always #(CLK_PERIOD/2) clk = ~clk;

    // Cycle counter
    always @(posedge clk) cycle_count = cycle_count + 1;

    // Task: send byte, wait for RX valid, then check
    task check_byte(input [7:0] byte_val);
        integer timeout;
        reg     got_it;
        begin
            $display("[%0t] Sending 0x%02h...", $time, byte_val);

            // Pulse valid for one cycle
            @(posedge clk);
            tx_data  <= byte_val;
            tx_valid <= 1;
            @(posedge clk);
            tx_valid <= 0;

            // Wait for rx_valid or timeout
            got_it  = 0;
            timeout = 0;
            while (!got_it && timeout < CLKS_PER_BYTE) begin
                @(posedge clk);
                timeout = timeout + 1;
                if (rx_valid) begin
                    got_it = 1;
                end
            end

            if (!got_it) begin
                $display("[%0t] FAIL: Timeout (sent 0x%02h)", $time, byte_val);
                test_fail = test_fail + 1;
            end else if (rx_data !== byte_val) begin
                $display("[%0t] FAIL: Sent 0x%02h, got 0x%02h", $time, byte_val, rx_data);
                test_fail = test_fail + 1;
            end else begin
                $display("[%0t] PASS: 0x%02h", $time, byte_val);
                test_pass = test_pass + 1;
            end

            // Wait for TX to finish before next byte
            while (!tx_ready) @(posedge clk);
        end
    endtask

    // Main test sequence
    initial begin
        $dumpfile("build/tb_uart.vcd");
        $dumpvars(0, tb_uart);

        $display("=================================================");
        $display("UART Loopback Testbench");
        $display("CLK_FREQ=%0d  BAUD_RATE=%0d", CLK_FREQ, BAUD_RATE);
        $display("=================================================");

        // Reset
        rst = 1;
        #(CLK_PERIOD * 10);
        rst = 0;
        #(CLK_PERIOD * 5);

        // Verify idle state
        if (serial !== 1'b1) begin
            $display("FAIL: TX line not idle after reset");
            test_fail = test_fail + 1;
        end else begin
            $display("PASS: TX line idle after reset");
            test_pass = test_pass + 1;
        end

        if (tx_ready !== 1'b1) begin
            $display("FAIL: TX not ready after reset");
            test_fail = test_fail + 1;
        end else begin
            $display("PASS: TX ready after reset");
            test_pass = test_pass + 1;
        end

        $display("");
        $display("--- Boundary values ---");
        check_byte(8'h00);
        check_byte(8'hFF);
        check_byte(8'hA5);
        check_byte(8'h5A);
        check_byte(8'h01);
        check_byte(8'h80);

        $display("");
        $display("--- ASCII characters ---");
        check_byte(8'h41);  // 'A'
        check_byte(8'h5A);  // 'Z'
        check_byte(8'h30);  // '0'
        check_byte(8'h39);  // '9'

        $display("");
        $display("--- Sequential sends ---");
        check_byte(8'hDE);
        check_byte(8'hAD);
        check_byte(8'hBE);
        check_byte(8'hEF);

        $display("");
        $display("=================================================");
        $display("Results: %0d passed, %0d failed", test_pass, test_fail);
        if (test_fail == 0)
            $display("ALL TESTS PASSED");
        else
            $display("*** SOME TESTS FAILED ***");
        $display("Cycles: %0d", cycle_count);
        $display("VCD: build/tb_uart.vcd");
        $display("=================================================");

        $finish;
    end

endmodule
