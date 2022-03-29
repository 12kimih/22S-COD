// DEFINITIONS
`define WORD_SIZE 16 // data and address word size

// INCLUDE files
`include "opcodes.v" // "opcode.v" consists of "define" statements for the opcodes and function codes for all instructions

// MODULE DECLARATION
module cpu (
        clk,
        reset_n,
        inputReady,
        readM,
        address,
        data,
        num_inst,
        output_port
    );

    input clk;                         // clock signal
    input reset_n;                     // active-low RESET signal
    input inputReady;                  // indicates that data is ready from the input port
    output readM;                      // read from memory
    output [`WORD_SIZE - 1:0] address; // current address for data
    inout [`WORD_SIZE - 1:0] data;     // data being input or output

    // for debugging/testing purpose
    output [`WORD_SIZE - 1:0] num_inst;    // number of instruction during execution
    output [`WORD_SIZE - 1:0] output_port; // this will be used for a "WWD" instruction
endmodule
