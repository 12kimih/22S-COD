`timescale 1ns / 1ns

`include "constants.v"

module hazard_v2 (
        ifid_use_rs,
        ifid_use_rt,
        ifid_regaddr1,
        ifid_regaddr2,
        idex_regwrite,
        idex_memread,
        idex_regaddr3,
        exmem_predpc,
        exmem_nextpc,
        exmem_hlt,
        memwb_hlt,
        pc_stall,
        ifid_stall,
        pc_flush,
        ifid_flush,
        idex_flush,
        exmem_flush,
        memwb_flush
    );

    // data hazard conditions
    input ifid_use_rs;
    input ifid_use_rt;
    input [`REG_ADDR - 1:0] ifid_regaddr1;
    input [`REG_ADDR - 1:0] ifid_regaddr2;
    input idex_regwrite;
    input idex_memread;
    input [`REG_ADDR - 1:0] idex_regaddr3;

    // control hazard conditions
    input [`WORD_SIZE - 1:0] exmem_predpc;
    input [`WORD_SIZE - 1:0] exmem_nextpc;
    input exmem_hlt;
    input memwb_hlt;

    // hazard resolution
    output pc_stall;
    output ifid_stall;
    output pc_flush;
    output ifid_flush;
    output idex_flush;
    output exmem_flush;
    output memwb_flush;

    reg [`HAZARD_V2_SIGSET - 1:0] sigset;

    assign {pc_stall, ifid_stall, pc_flush, ifid_flush, idex_flush, exmem_flush, memwb_flush} = sigset;

    always @(*) begin
        if (memwb_hlt) begin
            sigset = {1'b1, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1};
        end
        else if (exmem_hlt || exmem_predpc != exmem_nextpc) begin
            sigset = {1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0};
        end
        else if (ifid_regaddr1 == idex_regaddr3 && ifid_use_rs && idex_regwrite && idex_memread) begin
            sigset = {1'b1, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0};
        end
        else if (ifid_regaddr2 == idex_regaddr3 && ifid_use_rt && idex_regwrite && idex_memread) begin
            sigset = {1'b1, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0};
        end
        else begin
            sigset = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
        end
    end
endmodule
