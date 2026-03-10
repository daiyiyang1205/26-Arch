module signext(
    input  logic [11:0] a,
    output logic [63:0] y);  
    
    assign y = {{52{a[11]}}, a};
endmodule
