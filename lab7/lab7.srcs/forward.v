`timescale 1ns / 1ns

`include "constants.v"

module forward (
        ifid_regaddr1,
        ifid_regaddr2,
        idex_regwrite,
        exmem_regwrite,
        memwb_regwrite,
        idex_regaddr3,
        exmem_regaddr3,
        memwb_regaddr3,
        ifid_forward1_mux,
        ifid_forward2_mux
    );

    input [`REG_ADDR - 1:0] ifid_regaddr1;
    input [`REG_ADDR - 1:0] ifid_regaddr2;
    input idex_regwrite;
    input exmem_regwrite;
    input memwb_regwrite;
    input [`REG_ADDR - 1:0] idex_regaddr3;
    input [`REG_ADDR - 1:0] exmem_regaddr3;
    input [`REG_ADDR - 1:0] memwb_regaddr3;

    output reg [1:0] ifid_forward1_mux;
    output reg [1:0] ifid_forward2_mux;

    always @(*) begin
        if (ifid_regaddr1 == idex_regaddr3 && idex_regwrite) begin
            ifid_forward1_mux = 2'd1;
        end
        else if (ifid_regaddr1 == exmem_regaddr3 && exmem_regwrite) begin
            ifid_forward1_mux = 2'd2;
        end
        else if (ifid_regaddr1 == memwb_regaddr3 && memwb_regwrite) begin
            ifid_forward1_mux = 2'd3;
        end
        else begin
            ifid_forward1_mux = 2'd0;
        end
    end

    always @(*) begin
        if (ifid_regaddr2 == idex_regaddr3 && idex_regwrite) begin
            ifid_forward2_mux = 2'd1;
        end
        else if (ifid_regaddr2 == exmem_regaddr3 && exmem_regwrite) begin
            ifid_forward2_mux = 2'd2;
        end
        else if (ifid_regaddr2 == memwb_regaddr3 && memwb_regwrite) begin
            ifid_forward2_mux = 2'd3;
        end
        else begin
            ifid_forward2_mux = 2'd0;
        end
    end
endmodule
