/*************************************************************************
 * @Copyright (c) 2026 by hello-yuki265, All Rights Reserved. 
 * @Author       : hello-yuki265
 * @Github       : 2658476808@qq.com
 * @Date         : 2026-04-20 23:24:30
 * @LastEditors  : hello-yuki265 2658476808@qq.com
 * @LastEditTime : 2026-04-21 00:20:34
 * @FilePath     : \RV_simple\rtl\csr_ctrl.v
 * @Description  : 
 *************************************************************************/

`include "glb_define.v"
module csr_ctrl(
    clk,
    rst_n,

    // csr interface
    csr_dec_bus,


    // csr ctrl signal
    csr_wr_en,
    csr_rd_en,
    csr_idx,

    csr_i_rs1_dat,
    csr_rd_dat,
    csr_wb_dat
);

    input clk;
    input rst_n;

    input [`CSR_DEC_INFO_WIDTH-1:0] csr_dec_bus;

    output csr_wr_en;
    output csr_rd_en;
    output [11:0] csr_idx;

    input [`MXLEN-1:0] csr_i_rs1_dat;
    input [`MXLEN-1:0] csr_rd_dat;
    output [`MXLEN-1:0] csr_wb_dat;
    
    
    wire csrrw = csr_dec_bus[`CSR_DEC_CSRRW];
    wire csrrs = csr_dec_bus[`CSR_DEC_CSRRS];
    wire csrrc = csr_dec_bus[`CSR_DEC_CSRRC];
    wire csrrwi = csr_dec_bus[`CSR_DEC_CSRRWI];
    wire csrrsi = csr_dec_bus[`CSR_DEC_CSRRSI];
    wire csrrci = csr_dec_bus[`CSR_DEC_CSRRCI];
    wire [4:0] csrimm = csr_dec_bus[`CSR_DEC_IMM];
    assign csr_idx = csr_dec_bus[`CSR_DEC_IDX];

    wire csr_wr_en = csrrw | csrrs | csrrc | csrrwi | csrrsi | csrrci;
    wire csr_rd_en = csrrw | csrrs | csrrc | csrrwi | csrrsi | csrrci;

    assign csr_wb_dat = csrrw ? csr_i_rs1_dat :
                        csrrs ? (csr_rd_dat | csr_i_rs1_dat) :
                        csrrc ? (csr_rd_dat & ~csr_i_rs1_dat) :
                        csrrwi ? {27'b0, csrimm} :
                        csrrsi ? (csr_rd_dat | {27'b0, csrimm}) :
                        csrrci ? (csr_rd_dat & ~{27'b0, csrimm}) :
                        {`MXLEN{1'b0}};


    

endmodule