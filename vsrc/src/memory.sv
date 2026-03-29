`ifdef VERILATOR
`include "include/common.sv"
`include "src/mux2.sv"
`endif

module memory import common::*;(
    input  logic clk, reset,
    input  logic step, // 这个信号用来同步整个 CPU 的时序，当其为 1 时，整个 CPU 流水线向前移动一个指令。
    output logic memory_ok, // 表示当前模块是否已经准备好接受下一条指令了
    // 实际上 step = fetch_ok & decode_ok & execute_ok & memory_ok & writeback_ok; 也就是说，只有当五个阶段都准备好接受下一条指令了，step 才会为 1。
    input  logic re,
    input  logic we,
    input  logic signextend,
    input  msize_t size,
    input  logic memtoreg,
    input  logic [63:0] aluresult,
    input  logic [63:0] writedata,
	input  dbus_resp_t dbus_resp,
    output dbus_req_t  dbus_req,
    output logic [63:0] result
    );

logic [2:0] offset;

assign offset = aluresult[2:0];

logic [3:0] sizenum;

logic [7:0] strobe;

logic [63:0] aligned_writedata;

always_comb begin
    case (size)
        MSIZE1: sizenum = 1;
        MSIZE2: sizenum = 2;
        MSIZE4: sizenum = 4;
        MSIZE8: sizenum = 8;
        default: sizenum = 8;
    endcase
    strobe = 8'b0;
    for (int i = 0; i < sizenum; i++) begin
        if (32'(offset) + i < 8)
            strobe[32'(offset) + i] = 1'b1;
    end
    aligned_writedata = writedata << (offset * 8);
end

logic busy;

logic [63:0] readdata;

always_ff @(posedge clk) begin
    if (reset) begin
        memory_ok <= 1;
        dbus_req.valid <= 0;
        dbus_req.addr <= 0;
        dbus_req.strobe <= 0;
        dbus_req.data <= 0;
        busy <= 0;
    end else if (step) begin
        memory_ok <= 0; // 先把 execute_ok 置为 0，表示我们正在处理当前指令，还没有准备好接受下一条指令了。
        busy <= 1;
    end else if (busy) begin
        // read
        if (re) begin
            dbus_req.valid <= 1; // 置为 1，表示我们要求读数据了。
            dbus_req.addr <= aluresult;
            dbus_req.size <= size;
            dbus_req.strobe <= 8'b0;
            dbus_req.data <= 0;
            busy <= 0;
        end

        //write
        else if (we) begin
            dbus_req.valid <= 1; // 置为 1，表示我们要求写数据了。
            dbus_req.addr <= aluresult;
            dbus_req.size <= size;
            dbus_req.strobe <= strobe;
            dbus_req.data <= aligned_writedata;
            busy <= 0;
        end

        // no read and write
        else begin
            busy <= 0;
        end
    end
    else begin
        // 这里对应：要么我们还没执行好指令，要么我们执行好指令了，在等其他模块
        if (memory_ok) begin
            // 在等其他模块
        end else begin
            if (re) begin
                if (dbus_resp.data_ok & dbus_resp.addr_ok) begin
                    readdata <= dbus_resp.data;
                    dbus_req.valid <= 0;
                    memory_ok <= 1;
                end
            end

            else if (we) begin
                if (dbus_resp.data_ok & dbus_resp.addr_ok) begin
                    dbus_req.valid <= 0;
                    memory_ok <= 1;
                end
            end

            else if (!re & !we) begin
                memory_ok <= 1;
            end
        end
    end
end

logic [63:0] aligned_readdata;

assign aligned_readdata = readdata >> (offset * 8);

logic [63:0] memresult;

always_comb begin
    case (size)
        MSIZE1: 
            if (signextend) memresult = {{56{aligned_readdata[7]}}, aligned_readdata[7:0]};
            else memresult = {{56{1'b0}}, aligned_readdata[7:0]};
        MSIZE2:
            if (signextend) memresult = {{48{aligned_readdata[15]}}, aligned_readdata[15:0]};
            else memresult = {{48{1'b0}}, aligned_readdata[15:0]};
        MSIZE4:
            if (signextend) memresult = {{32{aligned_readdata[31]}}, aligned_readdata[31:0]};
            else memresult = {{32{1'b0}}, aligned_readdata[31:0]};
        MSIZE8: memresult = aligned_readdata;
        default: memresult = aligned_readdata;
    endcase
end

mux2 memtoregmux(aluresult, memresult, memtoreg, result);

endmodule