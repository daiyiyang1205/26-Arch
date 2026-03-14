`ifdef VERILATOR
`include "include/common.sv"
`endif

module execute import common::*;(
    input  logic clk, reset,
    input  logic step, // 这个信号用来同步整个 CPU 的时序，当其为 1 时，整个 CPU 流水线向前移动一个指令。
    output logic execute_ok, // 表示当前模块是否已经准备好接受下一条指令了
    // 实际上 step = fetch_ok & decode_ok & execute_ok & memory_ok & writeback_ok; 也就是说，只有当五个阶段都准备好接受下一条指令了，step 才会为 1。
    input  logic alusrc,
    input  logic [2:0] alucontrol,
    input  logic [63:0] readData1,
    input  logic [63:0] readData2,
    input  logic [63:0] seimm,
    output logic [63:0] result);

logic [63:0] srca, srcb;

assign srca = readData1;

mux2 srcbmux(readData2, seimm, alusrc, srcb);

alu alu(srca, srcb, alucontrol, result);

always_ff @(posedge clk) begin
    if (reset) begin
        execute_ok <= 1;
    end else if (step) begin
        execute_ok <= 0; // 先把 execute_ok 置为 0，表示我们正在处理当前指令，还没有准备好接受下一条指令了。
    end else begin
        // 这里对应：要么我们还没执行好指令，要么我们执行好指令了，在等其他模块
        if (execute_ok) begin
            // 在等其他模块
        end else begin
            execute_ok <= 1;
        end
    end
end

endmodule