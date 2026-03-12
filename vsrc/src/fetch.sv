`ifdef VERILATOR
`include "include/common.sv"
`endif

module fetch import common::*;(
    input  logic clk, reset,
    input  logic step, // 这个信号用来同步整个 CPU 的时序，当其为 1 时，整个 CPU 流水线向前移动一个指令。
    output logic fetch_ok, // 表示当前模块是否已经准备好接受下一条指令了
    // 实际上 step = fetch_ok & decode_ok & execute_ok & mem_ok & writeback_ok; 也就是说，只有当五个阶段都准备好接受下一条指令了，step 才会为 1。
    input  logic [63:0] pcinit,
    input  ibus_resp_t ibus_resp,
    output ibus_req_t ibus_req);

logic [63:0] pc;

logic [31:0] instr;

always_ff @(posedge clk) begin
    if (reset) begin
        pc <= pcinit;
    end else if (step) begin
        fetch_ok <= 0; // 先把 fetch_ok 置为 0，表示我们正在处理当前指令，还没有准备好接受下一条指令了。
        ibus_req.valid <= 1; // 置为 1，表示我们要求取指令了。
        ibus_req.addr <= pc; // 把我们要取指令的地址放在 addr 上。
    end else begin
        // 这里对应：要么我们还没取好指令，要么我们取好指令了，在等其他模块
        if (fetch_ok) begin
            // 在等其他模块
        end else if (ibus_resp.data_ok & ibus_resp.addr_ok) begin
            instr <= ibus_resp.data; // 从 data 上读取到我们要取的指令了。
            fetch_ok <= 1; // 取好指令了，我们把 fetch_ok 置为 1，表示我们已经准备好接受下一条指令了。
            ibus_req.valid <= 0; // 取好指令了，我们把 valid 置为 0，表示我们不再要求取指令了。
            pc <= pc + 4; // 取好指令了，我们把 pc 加 4，准备取下一条指令了。
        end
    end
end

endmodule