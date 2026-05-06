`ifdef VERILATOR
`include "include/common.sv"
`include "include/csr.sv"
`include "src/mux2.sv"
`include "src/mux3.sv"
`endif

module decode import common::*, csr_pkg::*;(
    input  logic clk, reset,
    input  logic step, // 这个信号用来同步整个 CPU 的时序，当其为 1 时，整个 CPU 流水线向前移动一个指令。
    output logic decode_ok, // 表示当前模块是否已经准备好接受下一条指令了
    // 实际上 step = fetch_ok & decode_ok & execute_ok & memory_ok & writeback_ok; 也就是说，只有当五个阶段都准备好接受下一条指令了，step 才会为 1。
    input  logic [31:0] instr,
    input  logic regwrite,
    input  logic csrwrite,
    input  logic regwritecsr,
    input  logic [1:0] immsrc,
    input  logic [4:0] writeAddr3,
    input  logic [11:0] writecsrW,
    input  logic [63:0] memresult,
    input  logic [63:0] csrresult,
    output logic [63:0] readData1,
    output logic [63:0] readData2,
    output logic [4:0] writeRegD,
    output logic [63:0] seimm,
    output logic [63:0] seIimm,
    output logic [63:0] seBimm,
    output logic [63:0] seJimm,
    output logic [63:0] next_reg[31:0],
    output logic [63:0] readcsrData,
    output logic [11:0] writecsrD,
    output logic [63:0] zeimm,
    output logic [63:0] next_mstatus, next_mepc, next_mtval, next_mtvec, 
                next_mcause, next_satp, next_mip, next_mie, next_mscratch,
    output logic [63:0] next_sie, next_sip, next_sepc, next_stval, next_stvec,
			    next_scause, next_sscratch, next_mideleg, next_medeleg); // 输出寄存器

logic [63:0] rf[31:0]; // 主寄存器

logic [4:0] readAddr1;
logic [4:0] readAddr2;

logic [11:0] Iimm, Simm;

logic [19:0] Uimm;

logic [12:0] Bimm;

logic [20:0] Jimm;

logic [63:0] seSimm, seUimm;

logic [63:0] writeData3;

// csr

logic [63:0] mstatus, mepc, mtval, mtvec,
            mcause, satp, mip, mie, mscratch, mcycle;

logic [63:0] next_mcycle;

logic [11:0] readcsr;

logic [4:0] zimm;

logic [63:0] sie, sip, sepc, stval, stvec,
			scause, sscratch, mideleg, medeleg;

assign readAddr1 = instr[19:15];
assign readAddr2 = instr[24:20];

assign readData1 = (readAddr1 == 0) ? 0 : next_reg[readAddr1];
assign readData2 = (readAddr2 == 0) ? 0 : next_reg[readAddr2];
assign writeRegD = instr[11:7];

assign Iimm = instr[31:20];
assign Simm = {instr[31:25], instr[11:7]};
assign Uimm = instr[31:12];
assign Bimm = {instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
assign Jimm = {instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};

assign seIimm = {{52{Iimm[11]}}, Iimm};
assign seSimm = {{52{Simm[11]}}, Simm};
assign seUimm = {{32{Uimm[19]}}, Uimm, 12'b0};

mux3 immmux(seIimm, seSimm, seUimm, immsrc, seimm);

assign seBimm = {{51{Bimm[12]}}, Bimm};
assign seJimm = {{43{Jimm[20]}}, Jimm};

// csr

assign readcsr = instr[31:20];

always_comb begin
    case (readcsr)
        CSR_MIE:      readcsrData = next_mie;
        CSR_MIP:      readcsrData = next_mip;
        CSR_MTVEC:    readcsrData = next_mtvec;
        CSR_MSTATUS:  readcsrData = next_mstatus;
        CSR_MSCRATCH: readcsrData = next_mscratch;
        CSR_MEPC:     readcsrData = next_mepc;
        CSR_SATP:     readcsrData = next_satp;
        CSR_MCAUSE:   readcsrData = next_mcause;
        CSR_MCYCLE:   readcsrData = next_mcycle;
        CSR_MTVAL:    readcsrData = next_mtval;

        CSR_MEDELEG:  readcsrData = next_medeleg;
        CSR_MIDELEG:  readcsrData = next_mideleg;
        CSR_STVEC:    readcsrData = next_stvec;
        CSR_SSCRATCH: readcsrData = next_sscratch;
        CSR_SEPC:     readcsrData = next_sepc;
        CSR_SCAUSE:   readcsrData = next_scause;
        CSR_STVAL:    readcsrData = next_stval;
        CSR_SIE:      readcsrData = next_sie;
        CSR_SIP:      readcsrData = next_sip;
        default:      readcsrData = 0;
    endcase
end

assign zimm = instr[19:15];

assign zeimm = {59'b0, zimm};

assign writecsrD = instr[31:20];

mux2 regwritemux(memresult, csrresult, regwritecsr, writeData3); 

always_comb begin
	for (int i = 0; i < 32; i++) begin
		if (regwrite && (i != 0) && (i[4:0] == writeAddr3)) begin
			next_reg[i[4:0]] = writeData3; // 用组合逻辑向next_reg写入
		end else begin
			next_reg[i[4:0]] = rf[i[4:0]]; // 复制其他没有写入的寄存器
		end
	end
end

// csr

always_comb begin
    next_mie      = mie;
    next_mip      = mip;
    next_mtvec    = mtvec;
    next_mstatus  = mstatus;
    next_mscratch = mscratch;
    next_mepc     = mepc;
    next_mcause   = mcause;
    next_mtval    = mtval;
    next_mcycle   = mcycle;
    next_stvec    = stvec;
    next_sscratch = sscratch;
    next_sepc     = sepc;
    next_scause   = scause;
    next_stval    = stval;
    next_sie      = sie;
    next_sip      = sip;
    next_mideleg  = mideleg;
    next_medeleg  = medeleg;
    next_satp     = satp;

    if (csrwrite) begin
        case (writecsrW)
            CSR_MIE:      next_mie      = memresult;
            CSR_MIP:      next_mip      = memresult & MIP_MASK;
            CSR_MTVEC:    next_mtvec    = memresult & MTVEC_MASK;
            CSR_MSTATUS:  next_mstatus  = memresult & MSTATUS_MASK;
            CSR_MSCRATCH: next_mscratch = memresult;
            CSR_MEPC:     next_mepc     = memresult;
            CSR_MCAUSE:   next_mcause   = memresult;
            CSR_MTVAL:    next_mtval    = memresult;
            CSR_MCYCLE:   next_mcycle   = memresult;
            CSR_STVEC:    next_stvec    = memresult;
            CSR_SSCRATCH: next_sscratch = memresult;
            CSR_SEPC:     next_sepc     = memresult;
            CSR_SCAUSE:   next_scause   = memresult;
            CSR_STVAL:    next_stval    = memresult;
            CSR_SIE:      next_sie      = memresult;
            CSR_SIP:      next_sip      = memresult;
            CSR_MIDELEG:  next_mideleg  = memresult & MIDELEG_MASK;
            CSR_MEDELEG:  next_medeleg  = memresult & MEDELEG_MASK;
            CSR_SATP:     next_satp     = memresult;
            default: ;
        endcase
    end
end

always_ff @(posedge clk) begin
    if (reset) begin
        decode_ok <= 1;
    end else if (step) begin
        decode_ok <= 0; // 先把 decode_ok 置为 0，表示我们正在处理当前指令，还没有准备好接受下一条指令了。
        if (regwrite && writeAddr3 != 0) rf[writeAddr3] <= writeData3;
        if (csrwrite) begin
            case (writecsrW)
                CSR_MIE:        mie      <= memresult;
                CSR_MIP:        mip      <= memresult & MIP_MASK;
                CSR_MTVEC:      mtvec    <= memresult & MTVEC_MASK;
                CSR_MSTATUS:    mstatus  <= memresult & MSTATUS_MASK;
                CSR_MSCRATCH:   mscratch <= memresult;
                CSR_MEPC:       mepc     <= memresult;
                CSR_SATP:       satp     <= memresult;
                CSR_MCAUSE:     mcause   <= memresult;
                CSR_MCYCLE:     mcycle   <= memresult;
                CSR_MTVAL:      mtval    <= memresult;

                CSR_STVEC:      stvec    <= memresult;
                CSR_SSCRATCH:   sscratch <= memresult;
                CSR_SEPC:       sepc     <= memresult;
                CSR_SCAUSE:     scause   <= memresult;
                CSR_STVAL:      stval    <= memresult;
                CSR_SIE:        sie      <= memresult;
                CSR_SIP:        sip      <= memresult;

                CSR_MIDELEG:    mideleg  <= memresult & MIDELEG_MASK;
                CSR_MEDELEG:    medeleg  <= memresult & MEDELEG_MASK;

                default:        mcycle   <= mcycle + 1;
            endcase
        end
        else mcycle <= mcycle + 1;
    end else begin
        mcycle <= mcycle + 1;
        // 这里对应：要么我们还没译码好指令，要么我们译码好指令了，在等其他模块
        if (decode_ok) begin
            // 在等其他模块
        end else begin
            decode_ok <= 1;
        end
    end
end

endmodule