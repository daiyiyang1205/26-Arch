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
    input  logic brch,
    output logic regwriteD,
    output logic csrwriteD,
    output logic regwritecsrD,
    output logic [1:0] immsrc,
    output logic csrimmD,
    output logic oldcsrD,
    output logic [1:0] alusrcaD,
    output logic [1:0] alusrcbD,
    output logic [3:0] alucontrolD,
    output logic memreadD,
    output logic memwriteD,
    output logic signextendD,
    output msize_t memsizeD,
    output logic memtoregD,
    output logic [1:0] nextpcsrc);

maindec md(op, funct3, brch,
            regwriteD, csrwriteD, regwritecsrD,
            immsrc,
            csrimmD, oldcsrD, alusrcaD, alusrcbD, 
            memreadD, memwriteD, memtoregD,
            nextpcsrc);

aludec ad(op, funct3, funct7, alucontrolD);

memdec mmd(funct3, signextendD, memsizeD);

endmodule
