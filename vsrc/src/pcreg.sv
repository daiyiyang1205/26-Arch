module pcreg(
    input  logic clk, reset,
    input  logic [63:0] pcinit,
    input  logic [63:0] d,
    output logic [63:0] q);  
    
    always_ff @(posedge clk, posedge reset)
        if (reset) q <= pcinit;
        else q <= d;
endmodule
