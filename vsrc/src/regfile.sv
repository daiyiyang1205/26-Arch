module regfile(
    input  logic clk, we,
    input  logic [4:0] readAddr1,
    input  logic [4:0] readAddr2,
    output logic [63:0] readData1,
    output logic [63:0] readData2,
    input  logic [4:0] writeAddr3,
    input  logic [63:0] writeData3);  
    
    logic [63:0] rf[31:0];
    
    assign readData1 = (readAddr1 == 0) ? 0 : rf[readAddr1];
    assign readData2 = (readAddr2 == 0) ? 0 : rf[readAddr2];
    
    always_ff @(posedge clk)
        if (we) rf[writeAddr3] <= writeData3;
endmodule
