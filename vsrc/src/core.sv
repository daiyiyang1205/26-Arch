`ifndef __CORE_SV
`define __CORE_SV

`ifdef VERILATOR
`include "include/common.sv"
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

logic [63:0] rf[31:0];

logic writeback_ok;

logic [63:0] pc;

logic [31:0] instr;

logic regwrite;

logic [4:0] writeReg;

logic [63:0] aluresult;

datapath dp(clk, reset,
    		PCINIT,
    		iresp,
    		ireq,
			rf,
			writeback_ok,
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
		.valid              (writeback_ok),
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
		.gpr_0              (rf[0]),
		.gpr_1              (rf[1]),
		.gpr_2              (rf[2]),
		.gpr_3              (rf[3]),
		.gpr_4              (rf[4]),
		.gpr_5              (rf[5]),
		.gpr_6              (rf[6]),
		.gpr_7              (rf[7]),
		.gpr_8              (rf[8]),
		.gpr_9              (rf[9]),
		.gpr_10             (rf[10]),
		.gpr_11             (rf[11]),
		.gpr_12             (rf[12]),
		.gpr_13             (rf[13]),
		.gpr_14             (rf[14]),
		.gpr_15             (rf[15]),
		.gpr_16             (rf[16]),
		.gpr_17             (rf[17]),
		.gpr_18             (rf[18]),
		.gpr_19             (rf[19]),
		.gpr_20             (rf[20]),
		.gpr_21             (rf[21]),
		.gpr_22             (rf[22]),
		.gpr_23             (rf[23]),
		.gpr_24             (rf[24]),
		.gpr_25             (rf[25]),
		.gpr_26             (rf[26]),
		.gpr_27             (rf[27]),
		.gpr_28             (rf[28]),
		.gpr_29             (rf[29]),
		.gpr_30             (rf[30]),
		.gpr_31             (rf[31])
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