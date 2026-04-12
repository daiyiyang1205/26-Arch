module aludec(
    input  logic [6:0] op,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    output logic [3:0] alucontrol);  
    
always_comb
    case(op)
        7'b0110011: case (funct3) // R
            3'b000: if (funct7[5] == 0) alucontrol = 4'b0000;
                    else alucontrol = 4'b0001;
            3'b111: alucontrol = 4'b0010;
            3'b110: alucontrol = 4'b0011;
            3'b100: alucontrol = 4'b0100;

            3'b010: alucontrol = 4'b0111;
            3'b011: alucontrol = 4'b1000;

            3'b001: alucontrol = 4'b1001;
            3'b101: if (funct7[5] == 0) alucontrol = 4'b1010;
                    else alucontrol = 4'b1011;
            default: alucontrol = 4'b0000;
        endcase
        
        7'b0010011: case (funct3) // I
            3'b000: alucontrol = 4'b0000;
            3'b111: alucontrol = 4'b0010;
            3'b110: alucontrol = 4'b0011;
            3'b100: alucontrol = 4'b0100;

            3'b010: alucontrol = 4'b0111;
            3'b011: alucontrol = 4'b1000;

            3'b001: alucontrol = 4'b1001;
            3'b101: if (funct7[5] == 0) alucontrol = 4'b1010;
                    else alucontrol = 4'b1011;
            default: alucontrol = 4'b0000;
        endcase

        7'b0011011: case (funct3)
            3'b000: alucontrol = 4'b0101;

            3'b001: alucontrol = 4'b1100;
            3'b101: if (funct7[5] == 0) alucontrol = 4'b1101;
                    else alucontrol = 4'b1110;
            default: alucontrol = 4'b0000;
        endcase

        7'b0111011: case (funct3)
            3'b000: if (funct7[5] == 0) alucontrol = 4'b0101;
                    else alucontrol = 4'b0110;
            
            3'b001: alucontrol = 4'b1100;
            3'b101: if (funct7[5] == 0) alucontrol = 4'b1101;
                    else alucontrol = 4'b1110;
            default: alucontrol = 4'b0000;
        endcase

        7'b0000011: alucontrol = 4'b0000; // I Load

        7'b0100011: alucontrol = 4'b0000; // S Store

        7'b0110111: alucontrol = 4'b0000; // U

        default: alucontrol = 4'b0000;
    endcase

endmodule
