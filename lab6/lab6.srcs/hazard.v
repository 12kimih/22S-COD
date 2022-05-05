`timescale 1ns / 1ns

`include "constants.v"

module hazard (
        regaddr1,
        regaddr2,
        idex_regaddr3,
        exmem_regaddr3,
        memwb_regaddr3,
        use_regaddr1,
        use_regaddr2,
        idex_regwrite,
        exmem_regwrite,
        memwb_regwrite,
        pc_stall,
        ifid_stall,
        exmem_predpc,
        exmem_nextpc,
        hlt,
        pc_flush,
        ifid_flush,
        idex_flush,
        exmem_flush
    );

    // data hazard signals
    input [`REG_ADDR - 1:0] regaddr1;
    input [`REG_ADDR - 1:0] regaddr2;
    input [`REG_ADDR - 1:0] idex_regaddr3;
    input [`REG_ADDR - 1:0] exmem_regaddr3;
    input [`REG_ADDR - 1:0] memwb_regaddr3;
    input use_regaddr1;
    input use_regaddr2;
    input idex_regwrite;
    input exmem_regwrite;
    input memwb_regwrite;

    output reg pc_stall;
    output reg ifid_stall;

    // control hazard signals
    input [`WORD_SIZE - 1:0] exmem_predpc;
    input [`WORD_SIZE - 1:0] exmem_nextpc;
    input hlt;

    output reg pc_flush;
    output reg ifid_flush;
    output reg idex_flush;
    output reg exmem_flush;

    // >>> data hazard >>>
    always @(*) begin
        if (regaddr1 == idex_regaddr3 && use_regaddr1 && idex_regwrite) begin
            pc_stall = 1'b1;
            ifid_stall = 1'b1;
        end
        else if (regaddr2 == idex_regaddr3 && use_regaddr2 && idex_regwrite) begin
            pc_stall = 1'b1;
            ifid_stall = 1'b1;
        end
        else if (regaddr1 == exmem_regaddr3 && use_regaddr1 && exmem_regwrite) begin
            pc_stall = 1'b1;
            ifid_stall = 1'b1;
        end
        else if (regaddr2 == exmem_regaddr3 && use_regaddr2 && exmem_regwrite) begin
            pc_stall = 1'b1;
            ifid_stall = 1'b1;
        end
        else if (regaddr1 == memwb_regaddr3 && use_regaddr1 && memwb_regwrite) begin
            pc_stall = 1'b1;
            ifid_stall = 1'b1;
        end
        else if (regaddr2 == memwb_regaddr3 && use_regaddr2 && memwb_regwrite) begin
            pc_stall = 1'b1;
            ifid_stall = 1'b1;
        end
        else begin
            pc_stall = 1'b0;
            ifid_stall = 1'b0;
        end
    end
    // <<< data hazard <<<

    // >>> control hazard >>>
    always @(*) begin
        if (exmem_predpc != exmem_nextpc || hlt) begin
            pc_flush = 1'b1;
            ifid_flush = 1'b1;
            idex_flush = 1'b1;
            exmem_flush = 1'b1;
        end
        else begin
            pc_flush = 1'b0;
            ifid_flush = 1'b0;
            idex_flush = 1'b0;
            exmem_flush = 1'b0;
        end
    end
    // <<< control hazard <<<
endmodule
