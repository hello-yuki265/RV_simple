/*************************************************************************
 * @Copyright (c) 2026 by hello-yuki265, All Rights Reserved. 
 * @Author       : hello-yuki265
 * @Github       : 2658476808@qq.com
 * @Date         : 2026-04-20 19:53:30
 * @LastEditors  : hello-yuki265 2658476808@qq.com
 * @LastEditTime : 2026-04-20 19:54:06
 * @FilePath     : \RV_simple\rtl\base_comp\dff_nr.v
 * @Description  : 
 *************************************************************************/

module dff_nr #(parameter WIDTH = 32)(
    input clk,
    input ena,
    input [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);
    always @(posedge clk) begin
        if (ena) begin
            q <= d;
        end
    end

endmodule