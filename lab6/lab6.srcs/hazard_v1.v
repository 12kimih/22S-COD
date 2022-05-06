`timescale 1ns / 1ns

`include "constants.v"

module hazard_v1 (
        use_regaddr1,
        use_regaddr2,
        regaddr1,
        regaddr2,
        idex_regwrite,
        exmem_regwrite,
        memwb_regwrite,
        idex_regaddr3,
        exmem_regaddr3,
        memwb_regaddr3,
        exmem_predpc,
        exmem_nextpc,
        hlt,
        pc_stall,
        ifid_stall,
        pc_flush,
        ifid_flush,
        idex_flush,
        exmem_flush
    );

    // data hazard conditions
    input use_regaddr1;
    input use_regaddr2;
    input [`REG_ADDR - 1:0] regaddr1;
    input [`REG_ADDR - 1:0] regaddr2;
    input idex_regwrite;
    input exmem_regwrite;
    input memwb_regwrite;
    input [`REG_ADDR - 1:0] idex_regaddr3;
    input [`REG_ADDR - 1:0] exmem_regaddr3;
    input [`REG_ADDR - 1:0] memwb_regaddr3;

    // control hazard conditions
    input [`WORD_SIZE - 1:0] exmem_predpc;
    input [`WORD_SIZE - 1:0] exmem_nextpc;
    input hlt;

    // hazard resolution
    output pc_stall;
    output ifid_stall;
    output pc_flush;
    output ifid_flush;
    output idex_flush;
    output exmem_flush;

    reg [`HAZARD_SIGSET - 1:0] sigset;

    always @(*) begin
        if (exmem_predpc != exmem_nextpc || hlt) begin
            sigset = {1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1};
        end
        else if (regaddr1 == idex_regaddr3 && use_regaddr1 && idex_regwrite) begin
            sigset = {1'b1, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0};
        end
        else if (regaddr2 == idex_regaddr3 && use_regaddr2 && idex_regwrite) begin
            sigset = {1'b1, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0};
        end
        else if (regaddr1 == exmem_regaddr3 && use_regaddr1 && exmem_regwrite) begin
            sigset = {1'b1, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0};
        end
        else if (regaddr2 == exmem_regaddr3 && use_regaddr2 && exmem_regwrite) begin
            sigset = {1'b1, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0};
        end
        else if (regaddr1 == memwb_regaddr3 && use_regaddr1 && memwb_regwrite) begin
            sigset = {1'b1, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0};
        end
        else if (regaddr2 == memwb_regaddr3 && use_regaddr2 && memwb_regwrite) begin
            sigset = {1'b1, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0};
        end
        else begin
            sigset = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
        end
    end

    assign {pc_stall, ifid_stall, pc_flush, ifid_flush, idex_flush, exmem_flush} = sigset;
endmodule
