`ifndef __CORE_SV
`define __CORE_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "src/datapath.sv"
`endif

module core import common::*;(
	input  logic       clk, reset,
	output ibus_req_t  ireq,
	input  ibus_resp_t iresp,
	output dbus_req_t  dreq,
	input  dbus_resp_t dresp,
	input  logic       trint, swint, exint
);
	/* TODO: Add your CPU-Core here. */

logic [63:0] next_reg[31:0];

logic [63:0] pc;

logic [31:0] instr;

logic regwrite;

logic [4:0] writeReg;

logic [63:0] aluresult;

logic valid;

datapath dp(clk, reset,
    		PCINIT,
    		iresp,
    		ireq,
			next_reg,
			valid,
			pc,
			instr,
			regwrite,
			writeReg,
			aluresult);

`ifdef VERILATOR
	DifftestInstrCommit DifftestInstrCommit(
		.clock              (clk),
		.coreid             (0),
		.index              (0),
		.valid              (valid),
		.pc                 (pc),
		.instr              (instr),
		.skip               (0),
		.isRVC              (0),
		.scFailed           (0),
		.wen                (regwrite),
		.wdest              ({3'b0, writeReg}),
		.wdata              (aluresult)
	);

	DifftestArchIntRegState DifftestArchIntRegState (
		.clock              (clk),
		.coreid             (0),
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
		.coreid             (0),
		.valid              (0),
		.code               (0),
		.pc                 (0),
		.cycleCnt           (0),
		.instrCnt           (0)
	);

	DifftestCSRState DifftestCSRState(
		.clock              (clk),
		.coreid             (0),
		.priviledgeMode     (3),
		.mstatus            (0),
		.sstatus            (0 /* mstatus & 64'h800000030001e000 */),
		.mepc               (0),
		.sepc               (0),
		.mtval              (0),
		.stval              (0),
		.mtvec              (0),
		.stvec              (0),
		.mcause             (0),
		.scause             (0),
		.satp               (0),
		.mip                (0),
		.mie                (0),
		.mscratch           (0),
		.sscratch           (0),
		.mideleg            (0),
		.medeleg            (0)
	);
`endif
endmodule
`endif