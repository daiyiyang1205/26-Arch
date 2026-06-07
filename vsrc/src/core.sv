`ifndef __CORE_SV
`define __CORE_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/csr.sv"
`include "src/datapath.sv"
`endif

module core import common::*, csr_pkg::*;(
	input  logic       clk, reset,
	output ibus_req_t  ireq,
	input  ibus_resp_t iresp,
	output dbus_req_t  dreq,
	input  dbus_resp_t dresp,
	input  logic       trint, swint, exint,
	output logic [1:0] next_mode,
	output logic [63:0] next_satp,
	input  logic [63:0] paddr
);

logic [63:0] next_reg[31:0];

logic valid;

logic [63:0] pc;

logic [31:0] instr;

logic regwrite;

logic [4:0] writeReg;

logic [63:0] memresult;

logic mem;

logic [63:0] memaddr;

logic [63:0] mhartid;

assign mhartid = 0;

logic [63:0] next_mstatus, next_mepc, next_mtval, next_mtvec, 
            next_mcause, next_mip, next_mie, next_mscratch;

logic [63:0] next_sie, next_sip, next_sepc, next_stval, next_stvec,
			next_scause, next_sscratch, next_mideleg, next_medeleg;

datapath dp(clk, reset,
    		PCINIT,
    		iresp,
			dresp,
    		ireq,
			dreq,
			next_reg,
			valid,
			pc,
			instr,
			regwrite,
			writeReg,
			memresult,
			mem,
			memaddr,
			next_mstatus, next_mepc, next_mtval, next_mtvec, 
            next_mcause, next_satp, next_mip, next_mie, next_mscratch,
			next_sie, next_sip, next_sepc, next_stval, next_stvec,
			next_scause, next_sscratch, next_mideleg, next_medeleg,
			next_mode,
			trint, swint, exint);

`ifdef VERILATOR
	DifftestInstrCommit DifftestInstrCommit(
		.clock              (clk),
		.coreid             (mhartid[7:0]),
		.index              (0),
		.valid              (valid),
		.pc                 (pc),
		.instr              (instr),
		.skip               ((mem & memaddr[31] == 0)),
		.isRVC              (0),
		.scFailed           (0),
		.wen                (regwrite),
		.wdest              ({3'b0, writeReg}),
		.wdata              (memresult)
	);

	DifftestArchIntRegState DifftestArchIntRegState (
		.clock              (clk),
		.coreid             (mhartid[7:0]),
		.gpr_0              (next_reg[0]),
		.gpr_1              (next_reg[1]),
		.gpr_2              (next_reg[2]),
		.gpr_3              (next_reg[3]),
		.gpr_4              (next_reg[4]),
		.gpr_5              (next_reg[5]),
		.gpr_6              (next_reg[6]),
		.gpr_7              (next_reg[7]),
		.gpr_8              (next_reg[8]),
		.gpr_9              (next_reg[9]),
		.gpr_10             (next_reg[10]),
		.gpr_11             (next_reg[11]),
		.gpr_12             (next_reg[12]),
		.gpr_13             (next_reg[13]),
		.gpr_14             (next_reg[14]),
		.gpr_15             (next_reg[15]),
		.gpr_16             (next_reg[16]),
		.gpr_17             (next_reg[17]),
		.gpr_18             (next_reg[18]),
		.gpr_19             (next_reg[19]),
		.gpr_20             (next_reg[20]),
		.gpr_21             (next_reg[21]),
		.gpr_22             (next_reg[22]),
		.gpr_23             (next_reg[23]),
		.gpr_24             (next_reg[24]),
		.gpr_25             (next_reg[25]),
		.gpr_26             (next_reg[26]),
		.gpr_27             (next_reg[27]),
		.gpr_28             (next_reg[28]),
		.gpr_29             (next_reg[29]),
		.gpr_30             (next_reg[30]),
		.gpr_31             (next_reg[31])
	);

    DifftestTrapEvent DifftestTrapEvent(
		.clock              (clk),
		.coreid             (mhartid[7:0]),
		.valid              (0),
		.code               (0),
		.pc                 (0),
		.cycleCnt           (0),
		.instrCnt           (0)
	);

	DifftestCSRState DifftestCSRState(
		.clock              (clk),
		.coreid             (mhartid[7:0]),
		.priviledgeMode     (next_mode),
		.mstatus            (next_mstatus),
		.sstatus            (next_mstatus & SSTATUS_MASK),
		.mepc               (next_mepc),
		.sepc               (next_sepc),
		.mtval              (next_mtval),
		.stval              (next_stval),
		.mtvec              (next_mtvec),
		.stvec              (next_stvec),
		.mcause             (next_mcause),
		.scause             (next_scause),
		.satp               (next_satp),
		.mip                (next_mip),
		.mie                (next_mie),
		.mscratch           (next_mscratch),
		.sscratch           (next_sscratch),
		.mideleg            (next_mideleg),
		.medeleg            (next_medeleg)
	);
`endif
endmodule
`endif