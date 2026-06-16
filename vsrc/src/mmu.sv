`ifdef VERILATOR
`include "include/common.sv"
`endif

module mmu_v import common::*;(
    input  logic clk, reset,
    input  logic [1:0] mode,
    input  logic [63:0] satp,
    input  cbus_req_t vreq,
    output cbus_resp_t vresp,
    output cbus_req_t oreq,
    input  cbus_resp_t oresp,
    output logic [63:0] paddr
);

    logic mmu_valid;
    cbus_req_t  oreq_reg;          // 分时复用的请求寄存器

    logic [3:0] status;
    logic [63:0] base1, base2, base3;
    logic [63:0] id1, id2, id3;
    logic [63:0] data1, data2, data3;

    assign mmu_valid = (mode == 2'b00 && satp[63:60] == 4'b1000);

    // 组合逻辑：根据工作模式选择请求来源
    assign oreq = mmu_valid ? oreq_reg : vreq;

    // 地址计算（组合）
    assign base1 = {8'b0, satp[43:0], 12'b0};
    assign id1   = {55'b0, vreq.addr[38:30]};

    assign base2 = {8'b0, data1[53:10], 12'b0};
    assign id2   = {55'b0, vreq.addr[29:21]};

    assign base3 = {8'b0, data2[53:10], 12'b0};
    assign id3   = {55'b0, vreq.addr[20:12]};

    assign paddr = mmu_valid ? {8'b0, data3[53:10], vreq.addr[11:0]} : vreq.addr;

    // 仅当 MMU 使能且处于物理地址响应阶段时，才向外部暴露响应
    assign vresp = mmu_valid ? 
                    ((status == 4'b0111) ? oresp : cbus_resp_t'{ready:0, last:0, data:0})
                    : oresp;

    always_ff @(posedge clk) begin
        if (reset) begin
            status    <= 4'b0000;
            oreq_reg  <= '0;
            data1     <= '0;
            data2     <= '0;
            data3     <= '0;
        end
        else if (!mmu_valid) begin
            // 非 MMU 模式或模式切换时复位状态机
            status   <= 4'b0000;
            oreq_reg <= '0;
        end
        else begin
            case (status)
                4'b0000: begin // 等待虚拟请求，发起第一级页表读
                    if (vreq.valid) begin
                        oreq_reg.valid   <= 1'b1;
                        oreq_reg.size    <= MSIZE8;
                        oreq_reg.addr    <= base1 + (id1 << 3);
                        oreq_reg.len     <= MLEN1;
                        oreq_reg.burst   <= AXI_BURST_FIXED;
                        // 读请求无需写信号，保持默认 0
                        oreq_reg.is_write <= 1'b0;
                        oreq_reg.strobe  <= '0;
                        oreq_reg.data    <= '0;
                        status <= 4'b0001;
                    end
                end

                4'b0001: begin // 等待第一级页表结果
                    if (oresp.ready && oresp.last) begin
                        data1 <= oresp.data;
                        oreq_reg.valid <= 1'b0;
                        status <= 4'b0010;
                    end
                end

                4'b0010: begin // 发起第二级页表读
                    oreq_reg.valid <= 1'b1;
                    oreq_reg.size  <= MSIZE8;
                    oreq_reg.addr  <= base2 + (id2 << 3);
                    oreq_reg.len   <= MLEN1;
                    oreq_reg.burst <= AXI_BURST_FIXED;
                    status <= 4'b0011;
                end

                4'b0011: begin // 等待第二级页表结果
                    if (oresp.ready && oresp.last) begin
                        data2 <= oresp.data;
                        oreq_reg.valid <= 1'b0;
                        status <= 4'b0100;
                    end
                end

                4'b0100: begin // 发起第三级页表读
                    oreq_reg.valid <= 1'b1;
                    oreq_reg.size  <= MSIZE8;
                    oreq_reg.addr  <= base3 + (id3 << 3);
                    oreq_reg.len   <= MLEN1;
                    oreq_reg.burst <= AXI_BURST_FIXED;
                    status <= 4'b0101;
                end

                4'b0101: begin // 等待第三级页表结果
                    if (oresp.ready && oresp.last) begin
                        data3 <= oresp.data;
                        oreq_reg.valid <= 1'b0;
                        status <= 4'b0110;
                    end
                end

                4'b0110: begin // 发出最终的物理地址请求
                    oreq_reg.valid    <= 1'b1;
                    oreq_reg.is_write <= vreq.is_write;
                    oreq_reg.size     <= vreq.size;
                    oreq_reg.addr     <= paddr;
                    oreq_reg.strobe   <= vreq.strobe;
                    oreq_reg.data     <= vreq.data;
                    oreq_reg.len      <= vreq.len;
                    oreq_reg.burst    <= vreq.burst;
                    status <= 4'b0111;
                end

                4'b0111: begin // 等待物理地址响应结束
                    if (oresp.ready && oresp.last) begin
                        oreq_reg.valid <= 1'b0;
                        status <= 4'b1000;
                    end
                end

                4'b1000: begin // 等待虚拟请求撤销
                    if (!vreq.valid) begin
                        status <= 4'b0000;
                    end
                end

                default: status <= 4'b0000;
            endcase
        end
    end

endmodule
