
module data_mem(
    input clk,
    input rst_n,

    input [31:0] addr,
    input        w_en,
    input [31:0] w_data,

    output [31:0] rd_data

);

    reg [31:0] mem [0:31];

    assign rd_data = mem[addr];

    always @(*) begin
        if (w_en) begin
            mem[addr] = w_data;
        end
    end

endmodule