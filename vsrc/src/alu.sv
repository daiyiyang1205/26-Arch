module alu(
    input  logic [63:0] a, b,
    input  logic [2:0] ALUcontrol,
    output logic [63:0] result);  
    
    logic [31:0] temp;

    always_comb begin
        temp = 0;
        case(ALUcontrol)
            3'b000: result = a + b;
            3'b001: result = a - b;
            3'b010: result = a & b;
            3'b011: result = a | b;
            3'b100: result = a ^ b;
            3'b101: begin
                temp = a[31:0] + b[31:0];
                result = {{32{temp[31]}}, temp[31:0]};
            end
            3'b110: begin
                temp = a[31:0] - b[31:0];
                result = {{32{temp[31]}}, temp[31:0]};
            end
            default: result = 0;
        endcase
    end
endmodule
