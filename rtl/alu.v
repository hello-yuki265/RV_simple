
module alu(
    input clk,
    input rst_n,

    // ----------------
    // 输入
    // ----------------
    input [2:0]  alu_ctrl,   //计算模式选择,
                           //00: add

    input [31:0] src0,  //源0
    input [31:0] src1,  //源1

    output reg [31:0] res
);

    // -----------------
    // alu运算逻辑
    // -----------------
    // TODO: 暂时只实现加法
    always @(*) begin
        case(alu_ctrl)
            3'b000: res = src0 + src1;
            3'b001: res = src0 - src1;
        endcase
    end


endmodule