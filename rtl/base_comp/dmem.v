/*************************************************************************
 * @Copyright (c) 2026 by hello-yuki265, All Rights Reserved. 
 * @Author       : hello-yuki265
 * @Github       : 2658476808@qq.com
 * @Date         : 2026-04-28 12:46:35
 * @LastEditors  : hello-yuki265 2658476808@qq.com
 * @LastEditTime : 2026-04-28 14:06:28
 * @FilePath     : \RV_simple\rtl\base_comp\dmem.v
 * @Description  : 
 *************************************************************************/
module dram #(parameter WIDTH = 32, DEPTH = 1024)(
    input clk,
    input rst_n,

    input wr_en,
    input [$clog2(DEPTH)-1:0] waddr,
    input [WIDTH-1:0] wdata,
    
    input rd_en,
    input [$clog2(DEPTH)-1:0] raddr,
    output [WIDTH-1:0] rdata
);

    reg [WIDTH-1:0] mem_array [0:DEPTH-1];
    // always @(posedge clk or negedge rst_n) begin
    //     if (!rst_n) begin
    //         rdata <= 0;
    //     end else if (rd_en) begin
    //         rdata <= mem_array[raddr];
    //     end
    // end
    assign rdata = rd_en ? mem_array[raddr] : {WIDTH{1'b0}};

    always @(posedge clk) begin
        if (wr_en) begin
            mem_array[waddr] <= wdata;
        end
    end


endmodule