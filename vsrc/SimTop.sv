`ifdef VERILATOR
`include "include/common.sv"
`include "src/core.sv"
`include "src/mmu.sv"
`include "util/IBusToCBus.sv"
`include "util/DBusToCBus.sv"
`include "util/CBusArbiter.sv"

module SimTop import common::*;(
  input         clock,
  input         reset,
  input  [63:0] io_logCtrl_log_begin,
  input  [63:0] io_logCtrl_log_end,
  input  [63:0] io_logCtrl_log_level,
  input         io_perfInfo_clean,
  input         io_perfInfo_dump,
  output        io_uart_out_valid,
  output [7:0]  io_uart_out_ch,
  output        io_uart_in_valid,
  input  [7:0]  io_uart_in_ch
);

    cbus_req_t  oreq;
    cbus_resp_t oresp;
    logic trint, swint, exint;

    ibus_req_t  ireq;
    ibus_resp_t iresp;
    dbus_req_t  dreq;
    dbus_resp_t dresp;
    cbus_req_t  icreq,  dcreq;
    cbus_resp_t icresp, dcresp;

    logic [1:0] mode;
	  logic [63:0] satp;

    logic [63:0] paddr;

    core core(
      .clk(clock), .reset, .ireq, .iresp, .dreq, .dresp, .trint, .swint, .exint,
      .next_mode(mode), .next_satp(satp), .paddr
    );

    IBusToCBus icvt(.*);
    DBusToCBus dcvt(.*);
    CBusArbiter mux(
        .clk(clock), .reset,
        .ireqs({icreq, dcreq}),
        .iresps({icresp, dcresp}),
        .*
    );

    mmu mmu(.clk(clock), .reset,
            .trint, .swint, .exint,
            .mode, .satp,
            .vreq(oreq),
            .paddr,
            .presp(oresp));

    assign {io_uart_out_valid, io_uart_out_ch, io_uart_in_valid} = '0;

endmodule
`endif