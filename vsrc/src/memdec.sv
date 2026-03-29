`ifdef VERILATOR
`include "include/common.sv"
`endif

module memdec import common::*;(
    input  logic [2:0] funct3,
    output logic signextend,
    output msize_t memsize);

always_comb
    case(funct3)
        3'b000: begin
            signextend = 1;
            memsize = MSIZE1;
        end
        
        3'b001: begin
            signextend = 1;
            memsize = MSIZE2;
        end

        3'b010: begin
            signextend = 1;
            memsize = MSIZE4;
        end

        3'b011: begin
            signextend = 1;
            memsize = MSIZE8;
        end

        3'b100: begin
            signextend = 0;
            memsize = MSIZE1;
        end

        3'b101: begin
            signextend = 0;
            memsize = MSIZE2;
        end

        3'b110: begin
            signextend = 0;
            memsize = MSIZE4;
        end
        
        default: begin
            signextend = 1;
            memsize = MSIZE8;
        end
    endcase
endmodule
