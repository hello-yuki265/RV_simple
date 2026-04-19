/*************************************************************************
 * @Copyright (c) 2026 by hello-yuki265, All Rights Reserved. 
 * @Author       : hello-yuki265
 * @Github       : 2658476808@qq.com
 * @Date         : 2026-04-18 16:36:22
 * @LastEditors  : hello-yuki265 2658476808@qq.com
 * @LastEditTime : 2026-04-19 14:49:44
 * @FilePath     : \RV_simple\rtl\glb_define.v
 * @Description  : 
 *************************************************************************/

`ifndef _GLB_DEFINE_
`define _GLB_DEFINE_

// `define RV64I


// ================================
// ALU operation def
// ================================
`define ALU_OP_NUM    10
`define ALU_MASK_WIDTH   4
`define ALU_MASK_ADD     (`ALU_MASK_WIDTH'd0)
`define ALU_MASK_SUB     (`ALU_MASK_WIDTH'd1)
`define ALU_MASK_SLL     (`ALU_MASK_WIDTH'd2)
`define ALU_MASK_SLT     (`ALU_MASK_WIDTH'd3)
`define ALU_MASK_SLTU    (`ALU_MASK_WIDTH'd4)   
`define ALU_MASK_XOR     (`ALU_MASK_WIDTH'd5)
`define ALU_MASK_SRL     (`ALU_MASK_WIDTH'd6)
`define ALU_MASK_SRA     (`ALU_MASK_WIDTH'd7)
`define ALU_MASK_OR      (`ALU_MASK_WIDTH'd8)
`define ALU_MASK_AND     (`ALU_MASK_WIDTH'd9)

`define ALU_ADD     (`ALU_OP_NUM'b00_0000_0001)
`define ALU_SUB     (`ALU_OP_NUM'b00_0000_0010)
`define ALU_SLL     (`ALU_OP_NUM'b00_0000_0100)
`define ALU_SLT     (`ALU_OP_NUM'b00_0000_1000)
`define ALU_SLTU    (`ALU_OP_NUM'b00_0001_0000)   
`define ALU_XOR     (`ALU_OP_NUM'b00_0010_0000)
`define ALU_SRL     (`ALU_OP_NUM'b00_0100_0000)
`define ALU_SRA     (`ALU_OP_NUM'b00_1000_0000)
`define ALU_OR      (`ALU_OP_NUM'b01_0000_0000)
`define ALU_AND     (`ALU_OP_NUM'b10_0000_0000)
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