module alu(
    input  logic [63:0] a, b,
    input  logic [3:0] ALUcontrol,
    output logic [63:0] result);  
    
    logic [31:0] temp;

    always_comb begin
        temp = 0;
        case(ALUcontrol)
            4'b0000: result = a + b;
            4'b0001: result = a - b;
            4'b0010: result = a & b;
            4'b0011: result = a | b;
            4'b0100: result = a ^ b;
            4'b0101: begin
                temp = a[31:0] + b[31:0];
                result = {{32{temp[31]}}, temp};
            end
            4'b0110: begin
                temp = a[31:0] - b[31:0];
                result = {{32{temp[31]}}, temp};
            end

            4'b0111: result = ($signed(a) < $signed(b)) ? 1 : 0;
            4'b1000: result = (a < b) ? 1 : 0;

            4'b1001: result = a << b[5:0];                // 逻辑左移
            4'b1010: result = a >> b[5:0];                // 逻辑右移
            4'b1011: result = $signed(a) >>> b[5:0];      // 算术右移

            4'b1100: begin
                temp = a[31:0] << b[4:0];                 // 32位逻辑左移
                result = {{32{temp[31]}}, temp};
            end
            4'b1101: begin
                temp = a[31:0] >> b[4:0];                 // 32位逻辑右移
                result = {{32{temp[31]}}, temp};
            end
            4'b1110: begin
                temp = $signed(a[31:0]) >>> b[4:0];       // 32位算术右移
                result = {{32{temp[31]}}, temp};
            end
            
            default: result = 0;
        endcase
    end
endmodule