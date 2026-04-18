/*************************************************************************
 * @Copyright (c) 2026 by hello-yuki265, All Rights Reserved. 
 * @Author       : hello-yuki265
 * @Github       : 2658476808@qq.com
 * @Date         : 2026-04-17 12:35:51
 * @LastEditors  : hello-yuki265 2658476808@qq.com
 * @LastEditTime : 2026-04-19 02:36:55
 * @FilePath     : \RV_simple\rtl\data_mem.v
 * @Description  : 
 *************************************************************************/

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