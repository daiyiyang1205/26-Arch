`ifdef VERILATOR
`include "include/common.sv"
`include "src/controller.sv"
`include "src/enreg.sv"
`include "src/stallreg.sv"
`include "src/comparer.sv"
`include "src/fetch.sv"
`include "src/decode.sv"
`include "src/execute.sv"
`include "src/memory.sv"
`endif

module datapath import common::*;(
    input  logic clk, reset,
    input  logic [63:0] pcinit,
    input  ibus_resp_t ibus_resp,
    input  dbus_resp_t dbus_resp,
    output ibus_req_t  ibus_req,
    output dbus_req_t  dbus_req,
    output logic [63:0] next_reg[31:0],
    output logic valid,
    output logic [63:0] pcW,
    output logic [31:0] instrW,
    output logic regwriteW,
    output logic [4:0] writeRegW,
    output logic [63:0] memresultW,
    output logic mem,
    output logic [63:0] aluresultW,
    output logic [63:0] next_mstatus, next_mepc, next_mtval, next_mtvec, 
                    next_mcause, next_satp, next_mip, next_mie, next_mscratch,
    output logic [63:0] next_sie, next_sip, next_sepc, next_stval, next_stvec,
			        next_scause, next_sscratch, next_mideleg, next_medeleg);

// pipeline control signal

logic step, fetch_ok, decode_ok, execute_ok, memory_ok, writeback_ok;

logic others_ok;

assign step = fetch_ok & decode_ok & execute_ok & memory_ok & writeback_ok;

assign others_ok = decode_ok & execute_ok & memory_ok & writeback_ok;

// load-use stall

logic stall;

logic [4:0] readAddr1, readAddr2;

assign readAddr1 = instrD[19:15];

assign readAddr2 = instrD[24:20];

assign stall = memreadE & (writeRegE != 0) 
                & ((writeRegE == readAddr1) || (writeRegE == readAddr2)); 

// csr stall

logic [1:0] stallcnt;

always_ff @(posedge clk) begin
    if (reset) begin
        stallcnt <= 0;
    end else if (step) begin
        if (instrF[6:0] == 7'b1110011) begin
            stallcnt <= 2;
        end
        else if (stallcnt >= 1) stallcnt <= stallcnt - 1;
    end
end

// controller

logic regwriteD, regwriteE, regwriteM;

logic csrwriteD, csrwriteE, csrwriteM, csrwriteW;

logic regwritecsrD, regwritecsrE, regwritecsrM, regwritecsrW;

logic [1:0] immsrc;

logic csrimmD, csrimmE;

logic oldcsrD, oldcsrE;

logic [1:0] alusrcaD, alusrcaE;

logic [1:0] alusrcbD, alusrcbE;

logic [3:0] alucontrolD, alucontrolE;

logic memreadD, memreadE, memreadM, memreadW;

logic memwriteD, memwriteE, memwriteM, memwriteW;

logic signextendD, signextendE, signextendM;

msize_t memsizeD, memsizeE, memsizeM;

logic memtoregD, memtoregE, memtoregM;

logic brch;

logic [1:0] nextpcsrc;

controller ctlr(clk, reset,
            instrD[6:0], 
            instrD[14:12], 
            instrD[31:25],
            brch,
            regwriteD,
            csrwriteD,
            regwritecsrD,
            immsrc,
            csrimmD,
            oldcsrD,
            alusrcaD,
            alusrcbD,
            alucontrolD,
            memreadD,
            memwriteD,
            signextendD,
            memsizeD,
            memtoregD,
            nextpcsrc);

stallreg #(20) cregDE(clk, reset, step, stall,
                {regwriteD, csrwriteD, regwritecsrD, 
                csrimmD, oldcsrD, alusrcaD, alusrcbD, alucontrolD,
                memreadD, memwriteD, signextendD, memsizeD, memtoregD},
                {regwriteE, csrwriteE, regwritecsrE, 
                csrimmE, oldcsrE, alusrcaE, alusrcbE, alucontrolE,
                memreadE, memwriteE, signextendE, memsizeE, memtoregE});

enreg #(10) cregEM(clk, reset, step,
                {regwriteE, csrwriteE, regwritecsrE, 
                memreadE, memwriteE, signextendE, memsizeE, memtoregE}, 
                {regwriteM, csrwriteM, regwritecsrM, 
                memreadM, memwriteM, signextendM, memsizeM, memtoregM});

enreg #(5) cregMW(clk, reset, step,
                {regwriteM, csrwriteM, regwritecsrM, memreadM, memwriteM},
                {regwriteW, csrwriteW, regwritecsrW, memreadW, memwriteW});

assign mem = memreadW | memwriteW;

// datapath

logic [63:0] pcF, pcD, pcE, pcM;

logic [31:0] instrF, instrD, instrE, instrM;

logic [63:0] readData1D, readData1E;

logic [63:0] readData2D, readData2E, readData2M;

logic [4:0] writeRegD, writeRegE, writeRegM;

logic [11:0] writecsrD, writecsrE, writecsrM, writecsrW;

logic [63:0] seimmD, seimmE;

logic [63:0] aluresultE, aluresultM;

logic [63:0] memresultM;

logic [63:0] csrresultD, csrresultE, csrresultM, csrresultW;

logic [63:0] seIimm, seBimm, seJimm;

logic [63:0] zeimmD, zeimmE;

logic [63:0] pcbranch, pcjal, pcjalr;

fetch fetch(clk, reset, step,
            fetch_ok,
            others_ok,
            nextpcsrc,
            stall,
            stallcnt,
            pcinit,
            pcbranch,
            pcjal,
            pcjalr,
            ibus_resp,
            ibus_req,
            pcF, 
            instrF);

enreg #(96) dregFD(clk, reset, step,
                {pcF, instrF},
                {pcD, instrD});

decode decode(clk, reset, step,
            decode_ok,
            instrD,
            regwriteW,
            csrwriteW,
            regwritecsrW,
            immsrc,
            writeRegW,
            writecsrW,
            memresultW,
            csrresultW,
            readData1D,
            readData2D,
            writeRegD,
            seimmD,
            seIimm, 
            seBimm, 
            seJimm,
            next_reg,
            csrresultD,
            writecsrD,
            zeimmD,
            next_mstatus, next_mepc, next_mtval, next_mtvec, 
            next_mcause, next_satp, next_mip, next_mie, next_mscratch,
            next_sie, next_sip, next_sepc, next_stval, next_stvec,
			next_scause, next_sscratch, next_mideleg, next_medeleg);

// forward

logic [63:0] true_readData1D, true_readData2D;

logic [4:0] sreg1, sreg2;

assign sreg2 = instrD[24:20];
assign sreg1 = instrD[19:15];

always_comb begin
    true_readData1D = readData1D;
    true_readData2D = readData2D;
    if (regwriteM && writeRegM != 0) begin
        if (writeRegM == sreg1) true_readData1D = memresultM;
        if (writeRegM == sreg2) true_readData2D = memresultM;
    end
    if (regwriteE && writeRegE != 0) begin
        if (writeRegE == sreg1) true_readData1D = aluresultE;
        if (writeRegE == sreg2) true_readData2D = aluresultE;
    end
end

// branch & jal & jalr

assign pcbranch = pcD + seBimm;

assign pcjal = pcD + seJimm;

assign pcjalr = (true_readData1D + seIimm) & (~1);

// comparer

comparer cmp(true_readData1D, true_readData2D, instrD[14:12], brch);

stallreg #(433) dregDE(clk, reset, step, stall,
                {true_readData1D, true_readData2D, writeRegD, seimmD,
                csrresultD, writecsrD, zeimmD,
                pcD, instrD},
                {readData1E, readData2E, writeRegE, seimmE,
                csrresultE, writecsrE, zeimmE,
                pcE, instrE});

execute execute(clk, reset, step,
                execute_ok,
                csrimmE,
                oldcsrE,
                alusrcaE,
                alusrcbE,
                alucontrolE,
                readData1E,
                readData2E,
                seimmE,
                pcE,
                zeimmE,
                csrresultE,
                aluresultE);

enreg #(305) dregEM(clk, reset, step,
                {aluresultE, readData2E, writeRegE,
                csrresultE, writecsrE,
                pcE, instrE},
                {aluresultM, readData2M, writeRegM,
                csrresultM, writecsrM,
                pcM, instrM});

memory memory(clk, reset, step,
            memory_ok,
            memreadM,
            memwriteM,
            signextendM,
            memsizeM,
            memtoregM,
            aluresultM,
            readData2M,
            dbus_resp,
            dbus_req,
            memresultM);

enreg #(305) dregMW(clk, reset, step,
                {memresultM, writeRegM,
                csrresultM, writecsrM, 
                pcM, instrM, aluresultM},
                {memresultW, writeRegW, 
                csrresultW, writecsrW,
                pcW, instrW, aluresultW});

always_ff @(posedge clk) begin
    if (reset) begin
        writeback_ok <= 1;
    end else if (step) begin
        writeback_ok <= 0; // 先把 writeback_ok 置为 0，表示我们正在处理当前指令，还没有准备好接受下一条指令了。
    end else begin
        // 这里对应：要么我们还没执行好指令，要么我们执行好指令了，在等其他模块
        if (writeback_ok) begin
            // 在等其他模块
        end else begin
            writeback_ok <= 1;
        end
    end
end

// difftest pin

assign valid = step & (instrW != 0);
    
endmodule
