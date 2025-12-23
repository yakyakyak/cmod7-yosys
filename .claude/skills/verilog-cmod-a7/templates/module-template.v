// <Module Name> for CMOD A7-35T
// <Brief description of functionality>
// Clock: 12 MHz
// <Other key specifications>

module <module_name> (
    input  wire clk,              // 12 MHz system clock
    input  wire [N-1:0] <inputs>, // Description
    output wire [M-1:0] <outputs> // Description
);

    // Parameters
    parameter PARAM_NAME = <value>;  // Description

    // Internal signals
    reg [WIDTH-1:0] signal_name = INIT_VALUE;

    // Sequential logic
    always @(posedge clk) begin
        signal_name <= next_value;
    end

    // Combinatorial logic
    assign outputs = signal_name[range];

endmodule
