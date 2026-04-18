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
`define IMM_MUX_I  (2'b00)
`define IMM_MUX_S  (2'b01)
`define IMM_MUX_B  (2'b10)
`define IMM_MUX_J  (2'b11)

// -------------------
// ALU_MUX
// -------------------
`define ALU_MUX_RS2 (1'b0)
`define ALU_MUX_IMM (1'b1)

// --------------------
// RES_MUX
// --------------------
`define RES_MUX_MEM (2'b00)
`define RES_MUX_ALU (2'b01)
`define RES_MUX_PCPLUS4 (2'b10)
`define RES_MUX_IMM (2'b11)

// -------------------
// PC_MUX
// -------------------
`define PC_MUX_NORM (1'b0)
`define PC_MUX_RES  (1'b1)




`endif 