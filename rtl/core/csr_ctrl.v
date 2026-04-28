/*************************************************************************
 * @Copyright (c) 2026 by hello-yuki265, All Rights Reserved. 
 * @Author       : hello-yuki265
 * @Github       : 2658476808@qq.com
 * @Date         : 2026-04-20 23:24:30
 * @LastEditors  : hello-yuki265 2658476808@qq.com
 * @LastEditTime : 2026-04-21 21:05:25
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
    
    
    wire csrrw = csr_dec_bus[`CSR_DEC_CSRRW] | csr_dec_bus[`CSR_DEC_CSRRWI];
    wire csrrs = csr_dec_bus[`CSR_DEC_CSRRS] | csr_dec_bus[`CSR_DEC_CSRRSI];
    wire csrrc = csr_dec_bus[`CSR_DEC_CSRRC] | csr_dec_bus[`CSR_DEC_CSRRCI];
    wire csrrwi = csr_dec_bus[`CSR_DEC_CSRRWI];
    wire csrrsi = csr_dec_bus[`CSR_DEC_CSRRSI];
    wire csrrci = csr_dec_bus[`CSR_DEC_CSRRCI];
    wire csr_isimm = csr_dec_bus[`CSR_DEC_CSRRWI] | csr_dec_bus[`CSR_DEC_CSRRSI] | csr_dec_bus[`CSR_DEC_CSRRCI];
    wire [4:0] csr_rs1imm = csr_dec_bus[`CSR_DEC_RS1IMM];
    wire [4:0] csr_rd = csr_dec_bus[`CSR_DEC_RD];
    assign csr_idx = csr_dec_bus[`CSR_DEC_IDX];


    wire csr_wr_en = csrrw 
                    // Only write while rs1 != x0 or imm != 0
                    | ((csrrs | csrrc) & !(csr_rs1imm == 5'b0)); 
                    
                    // Only read while rd != x0
    wire csr_rd_en = (csrrw & csr_rd != 5'b0) 
                    | csrrs | csrrc;


    assign csr_wb_dat = (csrrw & ~csr_isimm) ? csr_i_rs1_dat :
                        (csrrs & ~csr_isimm) ? (csr_rd_dat | csr_i_rs1_dat) :
                        (csrrc & ~csr_isimm) ? (csr_rd_dat & ~csr_i_rs1_dat) :
                        csrrwi ? {27'b0, csr_rs1imm} :
                        csrrsi ? (csr_rd_dat | {27'b0, csr_rs1imm}) :
                        csrrci ? (csr_rd_dat & ~{27'b0, csr_rs1imm}) :
                        {`MXLEN{1'b0}};


    

endmodule