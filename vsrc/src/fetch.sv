`ifdef VERILATOR
`include "include/common.sv"
`include "src/mux4.sv"
`include "src/mux3.sv"
`endif

module fetch import common::*;(
    input  logic clk, reset,
    input  logic step, // 这个信号用来同步整个 CPU 的时序，当其为 1 时，整个 CPU 流水线向前移动一个指令。
    output logic fetch_ok, // 表示当前模块是否已经准备好接受下一条指令了
    // 实际上 step = fetch_ok & decode_ok & execute_ok & memory_ok & writeback_ok; 也就是说，只有当五个阶段都准备好接受下一条指令了，step 才会为 1。
    input  logic others_ok,
    input  logic [1:0] nextpcsrc,
    input  logic [1:0] epc, 
    input  logic stall,
    input  logic [1:0] csrstall,
    input  logic [1:0] estall,
    input  logic [63:0] pcinit,
    input  logic [63:0] pcbranch,
    input  logic [63:0] pcjal,
    input  logic [63:0] pcjalr,
    input  logic [63:0] mtvec, mepc,
    input  ibus_resp_t ibus_resp,
    output ibus_req_t ibus_req,
    output logic [63:0] nowpc,
    output logic [31:0] instr);

logic [63:0] pc, tmppc, nextpc;

logic [31:0] nextinstr;

mux4 pcsrc1(pc + 4, pcbranch, pcjal, pcjalr, nextpcsrc, tmppc);

mux3 pcsrc2(tmppc, mtvec, mepc + 4, epc, nextpc);

always_ff @(posedge clk) begin
    if (reset) begin
        pc <= pcinit;
        fetch_ok <= 1;
        ibus_req.valid <= 0;
        ibus_req.addr <= 0;
    end else if (step) begin
        fetch_ok <= 0;
        ibus_req.valid <= 1;
        ibus_req.addr <= pc;
    end else begin
        if (fetch_ok) begin
            // 在等其他模块
        end
        else if (ibus_resp.data_ok & ibus_resp.addr_ok) begin // 指令取完了
            nextinstr <= ibus_resp.data;
            ibus_req.valid <= 0;
        end
        else if (ibus_req.valid == 0 && others_ok) begin // 指令取完了并且其他模块也完成了
            // 情况1：load-use阻塞
            if (stall) begin
                fetch_ok <= 1;
            end
            // 情况2：csr阻塞
            else if (csrstall >= 1) begin
                instr <= 32'b0;
                fetch_ok <= 1;
            end
            // 情况3：ecall, mret阻塞
            else if (estall >= 1) begin
                fetch_ok <= 1;
            end
            // 情况4：发生普通跳转
            else if (nextpcsrc != 0) begin
                instr <= 32'b0;
                pc <= nextpc;
                fetch_ok <= 1;
            end
            // 情况5：发生特权跳转
            else if (epc != 0) begin
                instr <= 32'b0;
                pc <= nextpc;
                fetch_ok <= 1;
            end
            // 情况6：取当前pc指向的指令
            else begin
                instr <= nextinstr;
                nowpc <= pc;
                pc <= nextpc;
                fetch_ok <= 1;
            end
        end
    end
end

endmodule
