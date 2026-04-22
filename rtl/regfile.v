/*************************************************************************
 * @Copyright (c) 2026 by hello-yuki265, All Rights Reserved. 
 * @Author       : hello-yuki265
 * @Github       : 2658476808@qq.com
 * @Date         : 2026-04-17 12:11:10
 * @LastEditors  : hello-yuki265 2658476808@qq.com
 * @LastEditTime : 2026-04-22 15:53:41
 * @FilePath     : \RV_simple\rtl\regfile.v
 * @Description  : 
 *************************************************************************/

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
    // 这里判断rs1==rd一起解决了访存的流水冲突
    // --------------------
    assign rs1_data = rs1 == 5'b0 ? 32'b0 : 
                        (rs1 == rd) ? rd_data :
                        register[rs1];
    assign rs2_data = rs2 == 5'b0 ? 32'b0 : 
                        (rs2 == rd) ? rd_data : 
                        register[rs2];

    // ----------------------
    // 写寄存器堆
    // ----------------------
    always @(posedge clk or negedge rst_n) begin
        if (rd_write) begin
            // x0始终为0
            register[rd] = rd == 5'b0 ? 32'b0 : rd_data;
        end
    end

endmodule