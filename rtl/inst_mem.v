
module inst_mem(
    input [7:0] pc,
    output [31 : 0] instr
);

    reg [31 : 0] mem [0 : 127];
    
    initial begin
        mem[0] = 32'h00200093;  // NOP
        mem[1] = 32'h00300113;  // NOP
        mem[2] = 32'h00400193;  // NOP
        mem[3] = 32'h00500213;  // NOP
        mem[4] = 32'h00200093;  // ADI x1, x0, 2
        mem[5] = 32'h00300113;  // ADI x2, x0, 3
        mem[6] = 32'h00400193;  // ADI x3, x0, 4
        mem[7] = 32'h00500213;  // ADI x4, x0, 5
        mem[8] = 32'h00000613;  // ADI x12, x0, 0
        mem[9] = 32'h00168613;  // SLLI x12, x3, 1
        mem[10] = 32'h00320733; // ADD x14, x4, x3
    end

    assign instr = mem[pc>>2];
endmodule