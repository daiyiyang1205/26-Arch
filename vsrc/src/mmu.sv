`ifdef VERILATOR
`include "include/common.sv"
`endif

module mmu import common::*;(
    input  logic clk, reset,
    output logic trint, swint, exint,
    input  logic [1:0] mode,
    input  logic [63:0] satp,
    input  cbus_req_t vreq,
    output logic [63:0] paddr,
    output cbus_resp_t presp);

logic mmu_valid;

cbus_req_t preq;

cbus_req_t preq_mmu;

assign mmu_valid = (mode == 2'b11 && satp[63:60] == 4'b1000);

// 非 MMU: 直接组合赋值；MMU: 使用寄存器
assign preq = mmu_valid ? preq_mmu : vreq;

logic [3:0] status;

logic [63:0] base1, base2, base3;

logic [63:0] id1, id2, id3;

logic [63:0] data1, data2, data3;

cbus_req_t req1, req2, req3;

cbus_resp_t resp1, resp2, resp3;

assign base1 = {8'b0, satp[43:0], 12'b0};

assign id1 = {55'b0, vreq.addr[38:30]};

RAMHelper2 ram1(
    .clk, .reset, .oreq(req1), .oresp(resp1), .trint, .swint, .exint
);

assign base2 = {8'b0, data1[53:10], 12'b0};

assign id2 = {55'b0, vreq.addr[29:21]};

RAMHelper2 ram2(
    .clk, .reset, .oreq(req2), .oresp(resp2), .trint, .swint, .exint
);

assign base3 = {8'b0, data2[53:10], 12'b0};

assign id3 = {55'b0, vreq.addr[20:12]};

RAMHelper2 ram3(
    .clk, .reset, .oreq(req3), .oresp(resp3), .trint, .swint, .exint
);

assign paddr = {8'b0, data3[53:10], vreq.addr[11:0]};

RAMHelper2 pram(
    .clk, .reset, .oreq(preq), .oresp(presp), .trint, .swint, .exint
);

always_ff @(posedge clk) begin
    if (reset) begin
        status <= 0;
        req1 <= 0;
        req2 <= 0;
        req3 <= 0;
        preq_mmu <= 0;
    end
    else if (mmu_valid) begin
        // 启用mmu
        case(status)
            4'b0000: begin // 情况0, 等待vreq.valid信号, 并发出第1次寻址请求
                if (vreq.valid) begin
                    req1.valid <= 1;
                    req1.size <= MSIZE8;
                    req1.addr <= base1 + (id1 << 3);
                    req1.len <= MLEN1;
                    req1.burst <= AXI_BURST_FIXED;
                    status <= 4'b0001;
                end
            end

            4'b0001: begin // 情况1, 等待第1次寻址结果
                if (resp1.ready && resp1.last) begin
                    data1 <= resp1.data;
                    req1.valid <= 0;
                    status <= 4'b0010;
                end
            end

            4'b0010: begin // 情况2, 发出第2次寻址请求
                req2.valid <= 1;
                req2.size <= MSIZE8;
                req2.addr <= base2 + (id2 << 3);
                req2.len <= MLEN1;
                req2.burst <= AXI_BURST_FIXED;
                status <= 4'b0011;
            end

            4'b0011: begin // 情况3, 等待第2次寻址结果
                if (resp2.ready && resp2.last) begin
                    data2 <= resp2.data;
                    req2.valid <= 0;
                    status <= 4'b0100;
                end
            end

                4'b0100: begin // 情况4, 发出第3次寻址请求
                req3.valid <= 1;
                req3.size <= MSIZE8;
                req3.addr <= base3 + (id3 << 3);
                req3.len <= MLEN1;
                req3.burst <= AXI_BURST_FIXED;
                status <= 4'b0101;
            end

            4'b0101: begin // 情况5, 等待第3次寻址结果
                if (resp3.ready && resp3.last) begin
                    data3 <= resp3.data;
                    req3.valid <= 0;
                    status <= 4'b0110;
                end
            end

            4'b0110: begin // 情况6, 发出物理地址请求
                preq_mmu.valid <= 1;
                preq_mmu.is_write <= vreq.is_write;
                preq_mmu.size <= vreq.size;
                preq_mmu.addr <= paddr;
                preq_mmu.strobe <= vreq.strobe;
                preq_mmu.data <= vreq.data;
                preq_mmu.len <= vreq.len;
                preq_mmu.burst <= vreq.burst;
                status <= 4'b0111;
            end

            4'b0111: begin // 情况7, 等待物理地址请求
                if (presp.ready && presp.last) begin
                    preq_mmu.valid <= 0;
                    status <= 4'b1000;
                end
            end

            4'b1000: begin // 情况8, 等待虚拟地址结束请求
                if (!vreq.valid) begin
                    status <= 4'b0000;
                end
            end
            default: ;
        endcase
    end
end
    
endmodule
