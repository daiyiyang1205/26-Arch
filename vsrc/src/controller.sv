module controller(
    input  logic [6:0] op,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    output logic regwrite,
    output logic alusrc,
    output logic [2:0] alucontrol);  
    
    logic [2:0] aluop;
    logic [1:0] controls;
    
    assign {regwrite, alusrc} = controls;
    
    maindec md(op, controls);
    
    aludec ad(op, funct3, funct7, alucontrol);
endmodule
