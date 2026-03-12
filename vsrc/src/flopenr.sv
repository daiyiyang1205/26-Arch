module flopenr #(parameter WIDTH = 64)
            (input logic clk, reset,
            input  logic we,
            input  logic [WIDTH-1:0] d,
            output logic [WIDTH-1:0] q);

always_ff @(posedge clk, posedge reset)
    if (reset) q <= 0;
    else if (we) q <= d;
endmodule