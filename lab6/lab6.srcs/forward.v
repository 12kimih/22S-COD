`timescale 1ns / 1ns

`include "constants.v"

module forward (
        regaddr1,
        regaddr2,
        idex_regwrite,
        idex_regaddr3,
        exmem_regwrite,
        exmem_regaddr3,
        memwb_regwrite,
        memwb_regaddr3,
        fwd1_mux,
        fwd2_mux
    );

    input [`REG_ADDR - 1:0] regaddr1;
    input [`REG_ADDR - 1:0] regaddr2;
    input idex_regwrite;
    input [`REG_ADDR - 1:0] idex_regaddr3;
    input exmem_regwrite;
    input [`REG_ADDR - 1:0] exmem_regaddr3;
    input memwb_regwrite;
    input [`REG_ADDR - 1:0] memwb_regaddr3;

    output reg [1:0] fwd1_mux;
    output reg [1:0] fwd2_mux;

    always @(*) begin
        if (idex_regwrite && regaddr1 == idex_regaddr3) begin
            fwd1_mux = 2'd1;
        end
        if (exmem_regwrite && regaddr1 == exmem_regaddr3) begin
            fwd1_mux = 2'd2;
        end
        else if (memwb_regwrite && regaddr1 == memwb_regaddr3) begin
            fwd1_mux = 2'd3;
        end
        else begin
            fwd1_mux = 2'd0;
        end
    end

    always @(*) begin
        if (idex_regwrite && regaddr2 == idex_regaddr3) begin
            fwd2_mux = 2'd1;
        end
        if (exmem_regwrite && regaddr2 == exmem_regaddr3) begin
            fwd2_mux = 2'd2;
        end
        else if (memwb_regwrite && regaddr2 == memwb_regaddr3) begin
            fwd2_mux = 2'd3;
        end
        else begin
            fwd2_mux = 2'd0;
        end
    end
endmodule
