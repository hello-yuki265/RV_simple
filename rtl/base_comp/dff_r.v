/*************************************************************************
 * @Copyright (c) 2026 by hello-yuki265, All Rights Reserved. 
 * @Author       : hello-yuki265
 * @Github       : 2658476808@qq.com
 * @Date         : 2026-04-20 19:52:48
 * @LastEditors  : hello-yuki265 2658476808@qq.com
 * @LastEditTime : 2026-04-20 19:53:24
 * @FilePath     : \RV_simple\rtl\base_comp\dff_r.v
 * @Description  : 
 *************************************************************************/

module dff_r #(parameter WIDTH = 32)(
    input clk,
    input rst_n,
    input ena,
    input [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= {WIDTH{1'b0}};
        end else if (ena)begin
            q <= d;
        end
    end

endmodule