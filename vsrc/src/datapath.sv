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
    output logic [63:0] aluresultW);

// pipeline control signal

logic step, fetch_ok, decode_ok, execute_ok, memory_ok, writeback_ok;

logic others_ok;

assign step = fetch_ok & decode_ok & execute_ok & memory_ok & writeback_ok;

assign others_ok = decode_ok & execute_ok & memory_ok & writeback_ok;

// stall

logic stall;

logic [4:0] readAddr1, readAddr2;

assign readAddr1 = instrD[19:15];

assign readAddr2 = instrD[24:20];

assign stall = memreadE & (writeRegE != 0) 
                & ((writeRegE == readAddr1) || (writeRegE == readAddr2)); 

// controller

logic regwriteD, regwriteE, regwriteM;

logic [1:0] immsrc;

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
            immsrc,
            alusrcaD,
            alusrcbD,
            alucontrolD,
            memreadD,
            memwriteD,
            signextendD,
            memsizeD,
            memtoregD,
            nextpcsrc);

stallreg #(16) cregDE(clk, reset, step, stall,
                {regwriteD, alusrcaD, alusrcbD, alucontrolD,
                memreadD, memwriteD, signextendD, memsizeD, memtoregD},
                {regwriteE, alusrcaE, alusrcbE, alucontrolE,
                memreadE, memwriteE, signextendE, memsizeE, memtoregE});

enreg #(8) cregEM(clk, reset, step,
                {regwriteE, memreadE, memwriteE, 
                signextendE, memsizeE, memtoregE}, 
                {regwriteM, memreadM, memwriteM, 
                signextendM, memsizeM, memtoregM});

enreg #(3) cregMW(clk, reset, step,
                {regwriteM, memreadM, memwriteM},
                {regwriteW, memreadW, memwriteW});

assign mem = memreadW | memwriteW;

// datapath

logic [63:0] pcF, pcD, pcE, pcM;

logic [31:0] instrF, instrD, instrE, instrM;

logic [63:0] readData1D, readData1E;

logic [63:0] readData2D, readData2E, readData2M;

logic [4:0] writeRegD, writeRegE, writeRegM;

logic [63:0] seimmD, seimmE;

logic [63:0] aluresultE, aluresultM;

logic [63:0] memresultM;

logic [63:0] seIimm, seBimm, seJimm;

logic [63:0] pcbranch, pcjal, pcjalr;

fetch fetch(clk, reset, step,
            fetch_ok,
            others_ok,
            nextpcsrc,
            stall,
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
            immsrc,
            writeRegW,
            memresultW,
            readData1D,
            readData2D,
            writeRegD,
            seimmD,
            seIimm, 
            seBimm, 
            seJimm,
            next_reg);

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

stallreg #(293) dregDE(clk, reset, step, stall,
                {true_readData1D, true_readData2D, writeRegD, seimmD, pcD, instrD},
                {readData1E, readData2E, writeRegE, seimmE, pcE, instrE});

execute execute(clk, reset, step,
                execute_ok,
                alusrcaE,
                alusrcbE,
                alucontrolE,
                readData1E,
                readData2E,
                seimmE,
                pcE,
                aluresultE);

enreg #(229) dregEM(clk, reset, step,
                {aluresultE, readData2E, writeRegE, pcE, instrE},
                {aluresultM, readData2M, writeRegM, pcM, instrM});

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

enreg #(229) dregMW(clk, reset, step,
                {memresultM, writeRegM, pcM, instrM, aluresultM},
                {memresultW, writeRegW, pcW, instrW, aluresultW});

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
