module comparer(
    input  logic [63:0] a,
    input  logic [63:0] b,
    input  logic [2:0] funct3,
    output logic brch);

always_comb begin
    case (funct3)
        3'b000: if (a == b) brch = 1;
                else brch = 0;
        3'b001: if (a != b) brch = 1;
                else brch = 0;
        3'b100: if ($signed(a) < $signed(b)) brch = 1;
                else brch = 0;
        3'b101: if ($signed(a) >= $signed(b)) brch = 1;
                else brch = 0;
        3'b110: if (a < b) brch = 1;
                else brch = 0;
        3'b111: if (a >= b) brch = 1;
                else brch = 0;
        default: brch = 0;
    endcase
end

endmodule
