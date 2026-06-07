`ifdef VERILATOR
`include "include/common.sv"
`endif

module exception import common::*;(
    input  logic [31:0] instr,
    input  logic [63:0] pcbranch, pcjal, pcjalr,
    input  logic brch,
    input  logic [63:0] addr,
    output logic illegal_instr, iaddr_misali, laddr_misali, saddr_misali);

logic [6:0] opcode;
logic [2:0] funct3;
logic [6:0] funct7;
logic legal_instr;

// 提取指令字段
assign opcode = instr[6:0];
assign funct3 = instr[14:12];
assign funct7 = instr[31:25];

// 合法指令判定
assign legal_instr = 
    // R-type (opcode=0x33)
    (opcode == 7'b0110011 && (
        (funct3 == 3'b000 && (funct7 == 7'b0000000 || funct7 == 7'b0100000)) || // add, sub
        (funct3 == 3'b111 && funct7 == 7'b0000000) || // and
        (funct3 == 3'b110 && funct7 == 7'b0000000) || // or
        (funct3 == 3'b100 && funct7 == 7'b0000000) || // xor
        (funct3 == 3'b010 && funct7 == 7'b0000000) || // slt
        (funct3 == 3'b011 && funct7 == 7'b0000000) || // sltu
        (funct3 == 3'b001 && funct7 == 7'b0000000) || // sll
        (funct3 == 3'b101 && (funct7 == 7'b0000000 || funct7 == 7'b0100000))   // srl, sra
    )) ||
    // R-type W (opcode=0x3B)
    (opcode == 7'b0111011 && (
        (funct3 == 3'b000 && (funct7 == 7'b0000000 || funct7 == 7'b0100000)) || // addw, subw
        (funct3 == 3'b001 && funct7 == 7'b0000000) || // sllw
        (funct3 == 3'b101 && (funct7 == 7'b0000000 || funct7 == 7'b0100000))    // srlw, sraw
    )) ||
    // I-type (opcode=0x13)
    (opcode == 7'b0010011 && (
        (funct3 == 3'b000) || (funct3 == 3'b111) || (funct3 == 3'b110) || (funct3 == 3'b100) || // addi, andi, ori, xori
        (funct3 == 3'b010) || (funct3 == 3'b011) || // slti, sltiu
        (funct3 == 3'b001 && funct7 == 7'b0000000) || // slli
        (funct3 == 3'b101 && (funct7 == 7'b0000000 || funct7 == 7'b0100000))    // srli, srai
    )) ||
    // I-type W (opcode=0x1B)
    (opcode == 7'b0011011 && (
        (funct3 == 3'b000) || // addiw
        (funct3 == 3'b001 && funct7 == 7'b0000000) || // slliw
        (funct3 == 3'b101 && (funct7 == 7'b0000000 || funct7 == 7'b0100000))    // srliw, sraiw
    )) ||
    // Load (opcode=0x03)
    (opcode == 7'b0000011 && (
        funct3 == 3'b000 || funct3 == 3'b001 || funct3 == 3'b010 || funct3 == 3'b011 ||
        funct3 == 3'b100 || funct3 == 3'b101 || funct3 == 3'b110
    )) ||
    // Store (opcode=0x23)
    (opcode == 7'b0100011 && (
        funct3 == 3'b000 || funct3 == 3'b001 || funct3 == 3'b010 || funct3 == 3'b011
    )) ||
    // Branch (opcode=0x63)
    (opcode == 7'b1100011 && (
        funct3 == 3'b000 || funct3 == 3'b001 || funct3 == 3'b100 || funct3 == 3'b101 ||
        funct3 == 3'b110 || funct3 == 3'b111
    )) ||
    // U-type (lui, auipc)
    (opcode == 7'b0110111) || (opcode == 7'b0010111) ||
    // J-type (jal)
    (opcode == 7'b1101111) ||
    // I-type jalr (opcode=0x67, funct3=0)
    (opcode == 7'b1100111 && funct3 == 3'b000) ||
    // CSR (opcode=0x73)
    (opcode == 7'b1110011 && (
        (funct3 == 3'b001) || (funct3 == 3'b010) || (funct3 == 3'b011) || // csrrw, csrrs, csrrc
        (funct3 == 3'b101) || (funct3 == 3'b110) || (funct3 == 3'b111) || // csrrwi, csrrsi, csrrci
        (instr == 32'b000000000000_00000_000_00000_1110011 || 
        instr == 32'b001100000010_00000_000_00000_1110011)   // ecall (0) , mret (0x302)
    ));

// 非法指令信号
assign illegal_instr = ~legal_instr;

// 指令地址不对齐信号
assign iaddr_misali = (opcode == 7'b1100011 && brch && pcbranch[1:0] != 2'b00) || 
                      (opcode == 7'b1101111 && pcjal[1:0] != 2'b00) ||
                      (opcode == 7'b1100111 && pcjalr[1:0] != 2'b00);

// 读数据地址不对齐信号
assign laddr_misali = (opcode == 7'b0000011) && 
                      (((funct3 == 3'b001 || funct3 == 3'b101) && addr[0] != 1'b0) ||
                      ((funct3 == 3'b010 || funct3 == 3'b110) && addr[1:0] != 2'b00) ||
                      (funct3 == 3'b011 && addr[2:0] != 3'b000)); 

// 写数据地址不对齐信号
assign saddr_misali = (opcode == 7'b0100011) && 
                      ((funct3 == 3'b001 && addr[0] != 1'b0) ||
                      (funct3 == 3'b010 && addr[1:0] != 2'b00) ||
                      (funct3 == 3'b011 && addr[2:0] != 3'b000));

endmodule