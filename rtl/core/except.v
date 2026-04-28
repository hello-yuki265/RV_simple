/*************************************************************************
 * @Copyright (c) 2026 by hello-yuki265, All Rights Reserved. 
 * @Author       : hello-yuki265
 * @Github       : 2658476808@qq.com
 * @Date         : 2026-04-21 15:13:57
 * @LastEditors  : hello-yuki265 2658476808@qq.com
 * @LastEditTime : 2026-04-22 12:26:05
 * @FilePath     : \RV_simple\rtl\except.v
 * @Description  : 
 *************************************************************************/
`include "glb_define.v"
 module except(
    input clk,
    input rst_n,

    input [`PC_WIDTH-1:0]trap_pc,
    input is_trap,
    input is_ret,
    input [`TRAP_DEC_INFO_WIDTH-1:0] trap_dec_bus,
    
    input [`MXLEN-1:0] trap_i_mtvec_val, 
    input [`MXLEN-1:0] trap_i_mepc_val,
    
    output trap_cause_en,
    output [`MXLEN-1:0] trap_cause_val,
    output trap_mepc_en,
    output [`MXLEN-1:0] trap_mepc_val,
    output trap_mstatus_en,
    output trap_mret_en,
    output trap_mscratch_en,

    output [`PC_WIDTH-1:0]trap_targ_pc
);

    wire ecall = trap_dec_bus[`TRAP_DEC_ECALL];
    wire ebreak = trap_dec_bus[`TRAP_DEC_EBREAK];
    wire uret = trap_dec_bus[`TRAP_DEC_URET];
    wire sret = trap_dec_bus[`TRAP_DEC_SRET];
    wire mret = trap_dec_bus[`TRAP_DEC_MRET];

    
    // set cause val
    assign trap_cause_en = ecall | ebreak;
    assign trap_cause_val = ecall ? 32'd3 :
                            ebreak ? 32'd11 :
                            32'd0; // 目前只考虑软件异常，不考虑中断

    // set epc to current trap pc
    assign trap_mepc_en = ecall | ebreak;
    assign trap_mepc_val = trap_pc;

    
    assign trap_mscratch_en = ecall | ebreak;
    assign trap_mstatus_en = ecall | ebreak;
    assign trap_mret_en = mret;

    wire [`PC_WIDTH-1:0] handler_base = {trap_i_mtvec_val[31:2], 2'b0};
    wire [1:0] mtvec_mode = trap_i_mtvec_val[1:0]; //mode==0: Directed
                                                   //mode==1: Vectored
                                                   //other: Reserved 
    wire [`PC_WIDTH-1:0] offset = (trap_cause_val<<2);
    assign trap_targ_pc = mret ? trap_i_mepc_val :
                            (trap_cause_val[`MXLEN-1] & mtvec_mode==2'b01) ? handler_base + offset :
                            handler_base;
endmodule