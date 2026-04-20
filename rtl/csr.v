
`include "glb_define.v"
module csr(
    clk,
    rst_n,

    csr_wr_en,
    csr_wb_dat,
    csr_rd_en,
    csr_rd_dat,
    csr_idx,

    // single enable
    sgl_cause_en,
    sgl_cause_val,
    sgl_mepc_en,
    sgl_mepc_val,
    sgl_mscratch_en

);

    input clk;
    input rst_n;

    input csr_wr_en;
    input [`MXLEN-1:0] csr_wb_dat;
    input csr_rd_en;
    output [`MXLEN-1:0] csr_rd_dat;
    input [11:0] csr_idx;

    input sgl_cause_en;
    input [`MXLEN-1:0] sgl_cause_val;
    input sgl_mepc_en;
    input [`MXLEN-1:0] sgl_mepc_val;
    input sgl_mscratch_en;


    


    // --------------------------------------
    // mstatus 
    // --------------------------------------
    wire sel_mstatus = csr_idx == 12'h300;

    wire [`MXLEN-1:0] csr_mstatus;
    assign csr_mstatus[31]    = 1'b0;    //SD
    assign csr_mstatus[30:23] = 8'b0;           // Reserved
    assign csr_mstatus[22:17] = 6'b0;           // TSR--MPRV
    assign csr_mstatus[16:15] = 2'b0;    // XS
    assign csr_mstatus[14:13] = 2'b0;    // FS
    assign csr_mstatus[12:11] = 2'b11;          // MPP 
    assign csr_mstatus[10:9]  = 2'b0;           // Reserved
    assign csr_mstatus[8]     = 1'b0;           // SPP
    assign csr_mstatus[7]     = 1'b0;  // MPIE
    assign csr_mstatus[6]     = 1'b0;           // Reserved
    assign csr_mstatus[5]     = 1'b0;           // SPIE 
    assign csr_mstatus[4]     = 1'b0;           // UPIE 
    assign csr_mstatus[3]     = 1'b0;   // MIE
    assign csr_mstatus[2]     = 1'b0;           // Reserved
    assign csr_mstatus[1]     = 1'b0;           // SIE 
    assign csr_mstatus[0]     = 1'b0;           // UIE 

    

    // --------------------------------------
    // mcause
    // --------------------------------------
    wire sel_mcause = csr_idx == 12'h342;
    wire wr_mcause = sel_mcause & csr_wr_en;
    wire rd_mcause = sel_mcause & csr_rd_en;
    wire cause_en = wr_mcause | sgl_cause_en;
    wire [`MXLEN-1:0] csr_mcause;
    wire [`MXLEN-1:0] csr_mcause_nxt = sgl_cause_en ? sgl_cause_val : csr_wb_dat; 
    dff_r #(`MXLEN) dff_r_mcause (clk, rst_n, cause_en, csr_mcause_nxt, csr_mcause);

    // --------------------------------------
    // mepc
    // --------------------------------------
    wire sel_mepc = csr_idx == 12'h341;
    wire wr_mepc = sel_mepc & csr_wr_en;
    wire rd_mepc = sel_mepc & csr_rd_en;
    wire mepc_en = wr_mepc | sgl_mepc_en;
    wire [`MXLEN-1:0] csr_mepc;
    wire [`MXLEN-1:0] csr_mepc_nxt = sgl_mepc_en ? sgl_mepc_val : csr_wb_dat; //TODO:暂时先不管其他输入
    dff_r #(`MXLEN) dff_r_mepc (clk, rst_n, mepc_en, csr_mepc_nxt, csr_mepc);


    // --------------------------------------
    // mtvec
    // --------------------------------------
    wire sel_mtvec = csr_idx == 12'h305;
    wire wr_mtvec = sel_mtvec & csr_wr_en;
    wire rd_mtvec = sel_mtvec & csr_rd_en;
    wire [`MXLEN-1:0] csr_mtvec;
    wire [`MXLEN-1:0] csr_mtvec_nxt = csr_wb_dat;
    dff_r #(`MXLEN) dff_r_mtvec (clk, rst_n, wr_mtvec, csr_mtvec_nxt, csr_mtvec);

    // --------------------------------------
    // mscratch
    // --------------------------------------
    wire sel_mscratch = csr_idx == 12'h340;
    wire wr_mscratch = sel_mscratch & csr_wr_en;
    wire rd_mscratch = sel_mscratch & csr_rd_en;
    wire [`MXLEN-1:0] csr_mscratch;
    wire [`MXLEN-1:0] csr_mscratch_nxt = csr_wb_dat;
    dff_r #(`MXLEN) dff_r_mscratch (clk, rst_n, wr_mscratch, csr_mscratch_nxt, csr_mscratch);


    // --------------------------------------
    // csr rd data mux
    // --------------------------------------
    assign csr_rd_dat = rd_mtvec ? csr_mtvec :
                        rd_mcause ? csr_mcause :
                        rd_mepc ? csr_mepc :
                        rd_mscratch ? csr_mscratch :
                        32'b0; //默认返回0
endmodule