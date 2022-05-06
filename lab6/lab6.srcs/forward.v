`timescale 1ns / 1ns

`include "constants.v"

module forward (
        regaddr1,
        regaddr2,
        idex_regwrite,
        exmem_regwrite,
        memwb_regwrite,
        idex_regaddr3,
        exmem_regaddr3,
        memwb_regaddr3,
        forward1_mux,
        forward2_mux
    );

    input [`REG_ADDR - 1:0] regaddr1;
    input [`REG_ADDR - 1:0] regaddr2;
    input idex_regwrite;
    input exmem_regwrite;
    input memwb_regwrite;
    input [`REG_ADDR - 1:0] idex_regaddr3;
    input [`REG_ADDR - 1:0] exmem_regaddr3;
    input [`REG_ADDR - 1:0] memwb_regaddr3;

    output reg [1:0] forward1_mux;
    output reg [1:0] forward2_mux;

    always @(*) begin
        if (regaddr1 == idex_regaddr3 && idex_regwrite) begin
            forward1_mux = 2'd1;
        end
        else if (regaddr1 == exmem_regaddr3 && exmem_regwrite) begin
            forward1_mux = 2'd2;
        end
        else if (regaddr1 == memwb_regaddr3 && memwb_regwrite) begin
            forward1_mux = 2'd3;
        end
        else begin
            forward1_mux = 2'd0;
        end
    end

    always @(*) begin
        if (regaddr2 == idex_regaddr3 && idex_regwrite) begin
            forward2_mux = 2'd1;
        end
        else if (regaddr2 == exmem_regaddr3 && exmem_regwrite) begin
            forward2_mux = 2'd2;
        end
        else if (regaddr2 == memwb_regaddr3 && memwb_regwrite) begin
            forward2_mux = 2'd3;
        end
        else begin
            forward2_mux = 2'd0;
        end
    end
endmodule
