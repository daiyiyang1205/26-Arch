module datapath(
    input  logic clk, reset,
    input  logic regwrite,
    input  logic alusrc,
    input  logic [2:0] alucontrol,
    input  logic [63:0] pcinit,
    output logic [63:0] pc,
    input  logic [31:0] instr);
      
    logic [63:0] pcplus4;
    
    logic [63:0] srca, writedata, result;
    logic [63:0] seimm;
    
    logic [63:0] srcb;
    
    // next pc
    pcreg pcr(clk, reset, pcinit, pcplus4, pc);
    adder pcadder(pc, 64'b100, pcplus4);
    
    
    // register file
    regfile rf(clk, regwrite,
               instr[24:20], instr[19:15], srca, writedata,
               instr[11:7], result);
    signext se(instr[31:20], seimm);
    
    // ALU
    mux2 srcbmux(writedata, seimm, alusrc, srcb);
    alu alu(srca, srcb, alucontrol, result);
endmodule
