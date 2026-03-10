module adder(
    input  logic [63:0] a, b,
    output logic [63:0] y);  
    
    assign y = a + b;
endmodule
