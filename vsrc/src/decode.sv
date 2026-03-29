`ifdef VERILATOR
`include "include/common.sv"
`include "src/mux2.sv"
`endif

module decode import common::*;(
    input  logic clk, reset,
    input  logic step, // 这个信号用来同步整个 CPU 的时序，当其为 1 时，整个 CPU 流水线向前移动一个指令。
    output logic decode_ok, // 表示当前模块是否已经准备好接受下一条指令了
    // 实际上 step = fetch_ok & decode_ok & execute_ok & memory_ok & writeback_ok; 也就是说，只有当五个阶段都准备好接受下一条指令了，step 才会为 1。
    input  logic [31:0] instr,
    input  logic regwrite,
    input  logic immcat,
    input  logic [4:0] writeAddr3,
    input  logic [63:0] writeData3,
    output logic [63:0] readData1,
    output logic [63:0] readData2,
    output logic [4:0] writeRegD,
    output logic [63:0] seimm,
    output logic [63:0] seuimm,
    output logic [63:0] next_reg[31:0]); // 输出寄存器

logic [63:0] rf[31:0]; // 主寄存器

logic [4:0] readAddr1;
logic [4:0] readAddr2;

logic [11:0] dimm, aimm;

logic [19:0] uimm;

logic [63:0] sedimm, seaimm;

assign readAddr1 = instr[19:15];
assign readAddr2 = instr[24:20];

assign readData1 = (readAddr1 == 0) ? 0 : next_reg[readAddr1];
assign readData2 = (readAddr2 == 0) ? 0 : next_reg[readAddr2];
assign writeRegD = instr[11:7];

assign dimm = instr[31:20];
assign aimm = {instr[31:25], instr[11:7]};
assign uimm = instr[31:12];

assign sedimm = {{52{dimm[11]}}, dimm};
assign seaimm = {{52{aimm[11]}}, aimm};

mux2 immmux(sedimm, seaimm, immcat, seimm);

assign seuimm = {{32{uimm[19]}}, uimm, 12'b0};

always_comb begin
	for (int i = 0; i < 32; i++) begin
		if (regwrite && (i != 0) && (i[4:0] == writeAddr3)) begin
			next_reg[i[4:0]] = writeData3; // 用组合逻辑向next_reg写入
		end else begin
			next_reg[i[4:0]] = rf[i[4:0]]; // 复制其他没有写入的寄存器
		end
	end
end

always_ff @(posedge clk) begin
    if (reset) begin
        decode_ok <= 1;
    end else if (step) begin
        decode_ok <= 0; // 先把 decode_ok 置为 0，表示我们正在处理当前指令，还没有准备好接受下一条指令了。
        if (regwrite && writeAddr3 != 0) rf[writeAddr3] <= writeData3;
    end else begin
        // 这里对应：要么我们还没译码好指令，要么我们译码好指令了，在等其他模块
        if (decode_ok) begin
            // 在等其他模块
        end else begin
            decode_ok <= 1;
        end
    end
end

endmodule