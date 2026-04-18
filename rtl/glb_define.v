/*************************************************************************
 * @Copyright (c) 2026 by hello-yuki265, All Rights Reserved. 
 * @Author       : hello-yuki265
 * @Github       : 2658476808@qq.com
 * @Date         : 2026-04-18 16:36:22
 * @LastEditors  : hello-yuki265 2658476808@qq.com
 * @LastEditTime : 2026-04-19 02:37:09
 * @FilePath     : \RV_simple\rtl\glb_define.v
 * @Description  : 
 *************************************************************************/

`ifndef _GLB_DEFINE_
`define _GLB_DEFINE_

// `define RV64I


// ================================
// ALU operation def
// ================================
`define ALU_ADD     (4'b0000)
`define ALU_SUB     (4'b0001)
`define ALU_SLL     (4'b0010)
`define ALU_SLT     (4'b0011)
`define ALU_SLTU    (4'b0100)   
`define ALU_XOR     (4'b0101)
`define ALU_SRL     (4'b0110)
`define ALU_SRA     (4'b0111)
`define ALU_OR      (4'b1000)
`define ALU_AND     (4'b1001)

// ================================
// MUX item def
// ================================
// -------------------
// IMM_MUX
// -------------------
`define IMM_MUX_I  (3'b000)
`define IMM_MUX_S  (3'b001)
`define IMM_MUX_B  (3'b010)
`define IMM_MUX_J  (3'b011)
`define IMM_MUX_U  (3'b100)

// -------------------
// ALU_MUX
// -------------------
`define ALU_MUX_SRC0_RS1 (1'b0)
`define ALU_MUX_SRC0_PC  (1'b1)
`define ALU_MUX_SRC1_RS2 (1'b0)
`define ALU_MUX_SRC1_IMM (1'b1)

// --------------------
// WB_MUX
// --------------------
`define WB_MUX_MEM (2'b00)
`define WB_MUX_ALU (2'b01)
`define WB_MUX_PCPLUS4 (2'b10)
`define WB_MUX_IMM (2'b11)

// -------------------
// PC_MUX
// -------------------
`define PC_MUX_NORM (2'b00)
`define PC_MUX_PLUSIMM  (2'b01)
`define PC_MUX_ALU  (2'b10)




`endif 