module maindec(
    input  logic [6:0] op,
    output logic regwrite, immcat, alusrc, upperreg, 
                    memread, memwrite, memtoreg);
    
logic [6:0] controls;

assign {regwrite, immcat, alusrc, upperreg, 
        memread, memwrite, memtoreg} = controls;

always_comb
    case(op)
        7'b0110011: controls = 7'b1000000; // R
        
        7'b0010011: controls = 7'b1010000; // I

        7'b0011011: controls = 7'b1010000; // I

        7'b0111011: controls = 7'b1010000; // I

        7'b0000011: controls = 7'b1010101; // I Load

        7'b0100011: controls = 7'b0110010; // S Store

        7'b0110111: controls = 7'b1001000; // U
        
        default: controls = 7'b1000000;
    endcase

endmodule
