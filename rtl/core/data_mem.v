/*************************************************************************
 * @Copyright (c) 2026 by hello-yuki265, All Rights Reserved. 
 * @Author       : hello-yuki265
 * @Github       : 2658476808@qq.com
 * @Date         : 2026-04-17 12:35:51
 * @LastEditors  : hello-yuki265 2658476808@qq.com
 * @LastEditTime : 2026-04-19 11:20:22
 * @FilePath     : \RV_simple\rtl\data_mem.v
 * @Description  : 
 *************************************************************************/

module data_mem(
    input clk,
    input rst_n,

    input [31:0] addr,
    input        w_en,
    input [31:0] w_data,
    input [2:0] load_type,
    input [2:0] store_type,

    output [31:0] rd_data

);

    reg [7:0] mem [0:511];

    // -----------------------
    // 读数据逻辑
    // -----------------------
    assign rd_data = load_type == 3'b010 ? {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]} : 
                     load_type == 3'b000 ? {{24{mem[addr][7]}}, mem[addr]} :
                     load_type == 3'b001 ? {{16{mem[addr+1][7]}}, mem[addr+1], mem[addr]} :
                     load_type == 3'b100 ? {24'b0, mem[addr]} :
                     load_type == 3'b101 ? {16'b0, mem[addr+1], mem[addr]} : 
                     32'b0; //默认返回0
    
    // -----------------------
    // 写数据逻辑        
    // -----------------------
    wire [3:0] store_we = store_type == 3'b000 ? 4'b0001 : 
                            store_type == 3'b001 ? 4'b0011 :
                            store_type == 3'b010 ? 4'b1111 : 
                            4'b0000; //默认不写

    always @(posedge clk) begin
        if (w_en) begin
            mem[addr] <= store_we[0] ? w_data[7:0] : mem[addr];
            mem[addr+1] <= store_we[1] ? w_data[15:8] : mem[addr+1];
            mem[addr+2] <= store_we[2] ? w_data[23:16] : mem[addr+2];
            mem[addr+3] <= store_we[3] ? w_data[31:24] : mem[addr+3];
        end
    end

endmodule