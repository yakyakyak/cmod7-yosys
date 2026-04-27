// Interactive UART register testbench.
// Driven by sim_console.py via stdin/stdout pipes.
//
// Input  (one command per line):  P | R HH | W HH DD
// Output (one response per line): READY | P | A HH HH | N HH

`timescale 1ns / 1ps

module tb_uart_interactive;

    localparam CLK_FREQ     = 12_000_000;
    localparam BAUD_RATE    = 115_200;
    localparam CLK_PERIOD   = 83;
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;  // 104

    reg  clk            = 0;
    wire [1:0] led;
    /* verilator lint_off UNUSEDSIGNAL */
    wire pio1;
    /* verilator lint_on UNUSEDSIGNAL */
    reg  uart_rxd_in_reg = 1;
    wire uart_rxd_in;
    wire uart_txd_out;

    assign uart_rxd_in = uart_rxd_in_reg;

    top dut (
        .clk          (clk),
        .led          (led),
        .pio1         (pio1),
        .uart_rxd_in  (uart_rxd_in),
        .uart_txd_out (uart_txd_out)
    );

    always #(CLK_PERIOD / 2) clk = ~clk;

    task send_byte;
        input [7:0] data;
        integer i;
        begin
            uart_rxd_in_reg = 0;
            repeat (CLKS_PER_BIT) @(posedge clk);
            for (i = 0; i < 8; i = i + 1) begin
                uart_rxd_in_reg = data[i];
                repeat (CLKS_PER_BIT) @(posedge clk);
            end
            uart_rxd_in_reg = 1;
            repeat (CLKS_PER_BIT) @(posedge clk);
        end
    endtask

    task recv_byte;
        output [7:0] received;
        integer i;
        begin
            received = 0;
            while (uart_txd_out !== 1'b0) @(posedge clk);
            repeat (CLKS_PER_BIT / 2) @(posedge clk);
            for (i = 0; i < 8; i = i + 1) begin
                repeat (CLKS_PER_BIT) @(posedge clk);
                received[i] = uart_txd_out;
            end
            repeat (CLKS_PER_BIT) @(posedge clk);
        end
    endtask

    reg [8*64:1] line;
    reg [7:0]    cmd, b0, b1;
    reg [7:0]    r0, r1, r2;
    integer      stdin_fd, n;

    initial begin
        stdin_fd = $fopen("/dev/stdin", "r");

        repeat (20) @(posedge clk);
        $display("READY");
        $fflush();

        while (1) begin
            n = $fgets(line, stdin_fd);
            if (n <= 0) $finish;
            if (n <= 1) begin  // blank line
            end else begin
                cmd = 0; b0 = 0; b1 = 0;
                // $sscanf ignores leading whitespace for %h; use %c for the command char
                n = $sscanf(line, " %c %h %h", cmd, b0, b1);

                case (cmd)
                    "P": begin
                        send_byte("P");
                        recv_byte(r0);
                        if (r0 == 8'h50) $display("P");
                        else             $display("ERR");
                        $fflush();
                    end

                    "R": begin
                        send_byte("R");
                        send_byte(b0);
                        recv_byte(r0);
                        if (r0 == 8'h41) begin  // 'A'
                            recv_byte(r1);
                            recv_byte(r2);
                            $display("A %02h %02h", r1, r2);
                        end else begin           // 'N'
                            recv_byte(r1);
                            $display("N %02h", r1);
                        end
                        $fflush();
                    end

                    "W": begin
                        send_byte("W");
                        send_byte(b0);
                        send_byte(b1);
                        recv_byte(r0);
                        if (r0 == 8'h41) begin  // 'A'
                            recv_byte(r1);
                            recv_byte(r2);
                            $display("A %02h %02h", r1, r2);
                        end else begin           // 'N'
                            recv_byte(r1);
                            $display("N %02h", r1);
                        end
                        $fflush();
                    end

                    default: begin
                        $display("ERR");
                        $fflush();
                    end
                endcase
            end
        end
    end

endmodule
