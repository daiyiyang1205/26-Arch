`ifdef VERILATOR
`include "include/common.sv"
`include "src/maindec.sv"
`include "src/aludec.sv"
`include "src/memdec.sv"
`endif

module controller import common::*;(
    input  logic clk, reset,
    input  logic [6:0] op,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    output logic regwriteD,
    output logic immcat,
    output logic alusrcD,
    output logic [2:0] alucontrolD,
    output logic upperregD,
    output logic memreadD,
    output logic memwriteD,
    output logic signextendD,
    output msize_t memsizeD,
    output logic memtoregD);

maindec md(op, regwriteD, immcat, alusrcD, upperregD, memreadD, memwriteD, memtoregD);

aludec ad(op, funct3, funct7, alucontrolD);

memdec mmd(funct3, signextendD, memsizeD);

endmodule
