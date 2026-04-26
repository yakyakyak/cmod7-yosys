// Example Module for CMOD A7-35T
// A simple parameterized counter that demonstrates module structure
// Clock: 12 MHz
//
// USER: Rename module and customize for your design

module example_module #(
    parameter WIDTH = 8           // Counter width (customize as needed)
) (
    input  wire             clk,  // 12 MHz system clock
    input  wire             en,   // Enable signal
    output wire [WIDTH-1:0] out   // Output value
);

    // Internal signals
    reg [WIDTH-1:0] counter = {WIDTH{1'b0}};

    // Sequential logic
    always @(posedge clk) begin
        if (en)
            counter <= counter + 1;
    end

    // Combinatorial logic
    assign out = counter;

endmodule
