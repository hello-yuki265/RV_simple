/*************************************************************************
 * @Copyright (c) 2026 by hello-yuki265, All Rights Reserved. 
 * @Author       : hello-yuki265
 * @Github       : 2658476808@qq.com
 * @Date         : 2026-04-21 15:13:57
 * @LastEditors  : hello-yuki265 2658476808@qq.com
 * @LastEditTime : 2026-09-29 19:38:13
 * @FilePath     : \RV_simple\rtl\core\except.v
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
    input [`INT_TYPE_NUM-1:0] trap_interrupt,
    
    input [`MXLEN-1:0] trap_i_mtvec_val, 
    input [`MXLEN-1:0] trap_i_mepc_val,
    input [`MXLEN-1:0] trap_i_mstatus_val,

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

    // set interrupt
    // 外部中断触发，且mie为1时，才触发中断
    wire external_interrupt = trap_i_mstatus_val[3] & (|trap_interrupt);
    
    // set cause val
    wire interrupt = ecall | ebreak | external_interrupt;
    assign trap_cause_en = ecall | ebreak | external_interrupt;
    wire [30:0] trap_cause_exception = ecall ? 31'd3 :
                                    ebreak ? 31'd11 :
                                    external_interrupt ? 31'd11 : 
                                    31'd0; 
    assign trap_cause_val = {}

    // set epc to current trap pc
    assign trap_mepc_en = ecall | ebreak | external_interrupt;
    assign trap_mepc_val = trap_pc;

    
    assign trap_mscratch_en = ecall | ebreak | external_interrupt;
    assign trap_mstatus_en = ecall | ebreak | external_interrupt;
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