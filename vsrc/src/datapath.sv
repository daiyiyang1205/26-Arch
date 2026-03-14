`ifdef VERILATOR
`include "include/common.sv"
`endif

module datapath import common::*;(
    input  logic clk, reset,
    input  logic [63:0] pcinit,
    input  ibus_resp_t ibus_resp,
    output ibus_req_t ibus_req);

// pipeline control signal

logic step, fetch_ok, decode_ok, execute_ok, memory_ok, writeback_ok;

assign step = fetch_ok & decode_ok & execute_ok & memory_ok & writeback_ok;

// controller

logic regwriteD, regwriteE, regwriteM, regwriteW;

logic alusrcD, alusrcE;

logic [2:0] alucontrolD, alucontrolE;

controller con(clk, reset,
            instrD[6:0], 
            instrD[14:12], 
            instrD[31:25],
            regwriteD,
            alusrcD,
            alucontrolD);

enreg #(5) cregDE(clk, reset, step,
                {regwriteD, alusrcD, alucontrolD},
                {regwriteE, alusrcE, alucontrolE});

enreg #(1) cregEM(clk, reset, step,
                regwriteE,
                regwriteM);

enreg #(1) cregMW(clk, reset, step,
                regwriteM,
                regwriteW);

// datapath

logic [31:0] instrF, instrD;

logic [63:0] readData1D, readData2D, readData1E, readData2E;

logic [4:0] writeRegD, writeRegE, writeRegM, writeRegW;

logic [63:0] seimmD, seimmE;

logic [63:0] aluresultE, aluresultM, aluresultW;

fetch fetch(clk, reset, step,
            fetch_ok,
            instrF,
            pcinit,
            ibus_resp,
            ibus_req);

enreg #(32) dregFD(clk, reset, step,
                instrF,
                instrD);

decode decode(clk, reset, step,
            decode_ok,
            instrD,
            regwriteW,
            writeRegW,
            aluresultW,
            readData1D,
            readData2D,
            writeRegD,
            seimmD);

// forward

logic [63:0] true_readData1D, true_readData2D;

logic [4:0] sreg1, sreg2;

assign sreg1 = instrD[24:20];
assign sreg2 = instrD[19:15];

always_comb begin
    true_readData1D = readData1D;
    true_readData2D = readData2D;
    if (regwriteM && writeRegM != 0) begin
        if (writeRegM == sreg1) true_readData1D = aluresultM;
        if (writeRegM == sreg2) true_readData2D = aluresultM;
    end
    if (regwriteE && writeRegE != 0) begin
        if (writeRegE == sreg1) true_readData1D = aluresultE;
        if (writeRegE == sreg2) true_readData2D = aluresultE;
    end
end

enreg #(197) dregDE(clk, reset, step,
                {true_readData1D, true_readData2D, writeRegD, seimmD},
                {readData1E, readData2E, writeRegE, seimmE});

execute execute(clk, reset, step,
                execute_ok,
                alusrcE,
                alucontrolE,
                readData1E,
                readData2E,
                seimmE,
                aluresultE);

enreg #(69) dregEM(clk, reset, step,
                {aluresultE, writeRegE},
                {aluresultM, writeRegM});

memory memory(clk, reset, step,
            memory_ok);

enreg #(69) dregMW(clk, reset, step,
                {aluresultM, writeRegM},
                {aluresultW, writeRegW});

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
    
endmodule
