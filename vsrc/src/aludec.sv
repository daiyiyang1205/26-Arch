module aludec(
    input  logic [6:0] op,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    output logic [2:0] alucontrol);  
    
    always_comb
        case(op)
            7'b0110011: case (funct3)
                3'b000: if (funct7 == 7'b0000000) alucontrol = 3'b000;
                        else alucontrol = 3'b001;
                3'b111: alucontrol = 3'b010;
                3'b110: alucontrol = 3'b011;
                3'b100: alucontrol = 3'b100;
                default: alucontrol = 3'b000;
            endcase
            
            7'b0010011: case (funct3)
                3'b000: alucontrol = 3'b000;
                3'b111: alucontrol = 3'b010;
                3'b110: alucontrol = 3'b011;
                3'b100: alucontrol = 3'b100;
                default: alucontrol = 3'b000;
            endcase

            7'b0011011: alucontrol = 3'b101;

            7'b0111011: case (funct3)
                3'b000: if (funct7 == 7'b0000000) alucontrol = 3'b101;
                        else alucontrol = 3'b110;
                default: alucontrol = 3'b000;
            endcase

            default: alucontrol = 3'b000;
        endcase

endmodule
