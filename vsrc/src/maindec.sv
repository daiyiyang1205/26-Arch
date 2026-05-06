module maindec(
    input  logic [6:0] op,
    input  logic [2:0] funct3,
    input  logic brch,
    output logic regwrite, csrwrite, regwritecsr,
    output logic [1:0] immsrc,
    output logic csrimm, oldcsr,
    output logic [1:0] alusrca, alusrcb,
    output logic memread, memwrite, memtoreg,
    output logic [1:0] nextpcsrc);
    
logic [13:0] controls;

assign {regwrite, csrwrite, regwritecsr, 
        immsrc, 
        csrimm, oldcsr, alusrca, alusrcb, 
        memread, memwrite, memtoreg} = controls;

always_comb
    case(op)
        7'b0110011: controls = 14'b1_0_0_00_00_00_00_000; // R
        
        7'b0010011: controls = 14'b1_0_0_00_00_00_01_000; // I

        7'b0011011: controls = 14'b1_0_0_00_00_00_01_000; // I 32

        7'b0111011: controls = 14'b1_0_0_00_00_00_00_000; // R 32

        7'b0000011: controls = 14'b1_0_0_00_00_00_01_101; // I Load

        7'b0100011: controls = 14'b0_0_0_01_00_00_01_010; // S Store

        7'b0110111: controls = 14'b1_0_0_10_00_01_01_000; // U lui

        7'b1100011: controls = 14'b0_0_0_00_00_00_00_000; // B

        7'b0010111: controls = 14'b1_0_0_10_00_10_01_000; // U auipc

        7'b1101111: controls = 14'b1_0_0_00_00_10_10_000; // J jal

        7'b1100111: controls = 14'b1_0_0_00_00_10_10_000; // I jalr

        7'b1110011: case (funct3) // I CSR
            3'b001: controls = 14'b1_1_1_00_00_00_11_000;
            3'b010: controls = 14'b1_1_1_00_01_00_11_000;
            3'b011: controls = 14'b1_1_1_00_01_11_11_000;

            3'b101: controls = 14'b1_1_1_00_10_00_11_000;
            3'b110: controls = 14'b1_1_1_00_11_00_11_000;
            3'b111: controls = 14'b1_1_1_00_11_11_11_000;

            default: controls = 14'b0;
        endcase

        default: controls = 14'b0;
    endcase

always_comb begin
    if (op == 7'b1100011 && brch) nextpcsrc = 2'b01;
    else if (op == 7'b1101111) nextpcsrc = 2'b10;
    else if (op == 7'b1100111) nextpcsrc = 2'b11;
    else nextpcsrc = 2'b00;
end

endmodule
