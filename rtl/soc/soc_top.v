module soc_top(
    input clk,
    input rst_n,

    input [31:0] instr_wr,
    input wr_en,
    input [9:0] waddr
);

    wire [31:0] pc;
    wire [31:0] instr;
    wire [7:0] interrupt;
    assign interrupt = 8'b0;

    simple_core  simple_core_inst (
    .clk(clk),
    .rst_n(rst_n),
    .pc(pc),
    .instr(instr),
    .interrupt(interrupt)
    );

    dram # (
    .WIDTH(32),
    .DEPTH(1024)
    )
    u_instr_ram (
    .clk(clk),
    .rst_n(rst_n),
    .wr_en(wr_en),
    .waddr(waddr),
    .wdata(instr_wr),
    .rd_en(1'b1),
    .raddr(pc[11:2]),
    .rdata(instr)
    );


endmodule
