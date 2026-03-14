module maindec(
    input  logic [6:0] op,
    output logic regwrite,
    output logic alusrc);
    
    logic [1:0] controls;

    assign {regwrite, alusrc} = controls;

    always_comb
        case(op)
            7'b0110011: controls = 2'b10;
            
            7'b0010011: controls = 2'b11;

            7'b0011011: controls = 2'b11;

            7'b0111011: controls = 2'b10;
            
            default: controls = 2'b10;
        endcase
endmodule
