`ifndef MUX3_SV
`define MUX3_SV

module mux3 #(parameter WIDTH = 64)
    (input logic [WIDTH-1:0] d0, d1, d2,
    input  logic [1:0] s,
    output logic [WIDTH-1:0] y);  
    
always_comb 
    case(s)
        2'b00: y = d0;
        2'b01: y = d1;
        2'b10: y = d2;
        default: y = d0;
    endcase

endmodule

`endif