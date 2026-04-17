
module regfile(
    input clk,
    input rst_n,

    // ----------------------------
    // 读取端口
    // ----------------------------
    input [4:0] rs1,
    input [4:0] rs2,

    // ----------------------------
    // 写入端口
    // ----------------------------
    input [4:0] rd, //目标寄存器地址
    input [31:0] rd_data,//写入数据
    input rd_write,      //写入使能

    // ---------------------------
    // 输出端口
    // ---------------------------
    output [31:0] rs1_data,
    output [31:0] rs2_data
);

    // -------------------
    // 寄存器堆定义
    // -------------------
    reg [31:0] register[0:31];

    // -------------------
    // 设置zero寄存器为0
    // -------------------
    initial begin
        register[0] = 0; //zero寄存器恒为0
    end

    // --------------------
    // 读取寄存器堆
    // --------------------
    assign rs1_data = register[rs1];
    assign rs2_data = register[rs2];

    // ----------------------
    // 写寄存器堆
    // ----------------------
    always @(*) begin
        if (rd_write) begin
            register[rd] = rd_data;
        end
    end

endmodule