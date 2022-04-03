`timescale 1ns / 100ps

`include "constants.v"

module RF (
        clk,
        reset_n,
        write,
        addr1,
        addr2,
        addr3,
        data1,
        data2,
        data3
    );

    input clk;
    input reset_n;

    input write;
    input [`REG_ADDR - 1:0] addr1;
    input [`REG_ADDR - 1:0] addr2;
    input [`REG_ADDR - 1:0] addr3;
    output reg [`WORD_SIZE - 1:0] data1;
    output reg [`WORD_SIZE - 1:0] data2;
    input [`WORD_SIZE - 1:0] data3;

    reg [`WORD_SIZE - 1:0] rf [0:`REG_SIZE - 1];

    always @(*) begin
        data1 = rf[addr1];
        data2 = rf[addr2];
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            rf[0] <= `WORD_SIZE'b0;
            rf[1] <= `WORD_SIZE'b0;
            rf[2] <= `WORD_SIZE'b0;
            rf[3] <= `WORD_SIZE'b0;
        end
        else begin
            rf[addr3] <= write ? data3 : rf[addr3];
        end
    end
endmodule
