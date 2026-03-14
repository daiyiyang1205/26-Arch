module controller(
    input  logic clk, reset,
    input  logic [6:0] op,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    output logic regwriteD,
    output logic alusrcD,
    output logic [2:0] alucontrolD);

maindec md(op, regwriteD, alusrcD);

aludec ad(op, funct3, funct7, alucontrolD);

endmodule
