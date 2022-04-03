`timescale 1ns / 100ps

`include "constants.v"
`include "opcodes.v"

module cpu (
        clk,
        reset_n,
        readM,
        writeM,
        inputReady,
        address,
        data,
        num_inst,
        output_port,
        is_halted
    );

    input clk;     // clock
    input reset_n; // active-low reset

    output readM;                    // enable memory read
    output writeM;                   // enable memory write
    input inputReady;                // if memory read is done
    output [`WORD_SIZE-1:0] address; // memory inout data address
    inout [`WORD_SIZE-1:0] data;     // memory inout data

    output [`WORD_SIZE-1:0] num_inst;    // number of instructions executed
    output [`WORD_SIZE-1:0] output_port; // WWD output port
    output is_halted;                    // HLT indicator

endmodule
