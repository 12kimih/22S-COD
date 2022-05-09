`timescale 1ns / 100ps

`include "constants.v"
`include "opcodes.v"

// 983 cycles
module cpu (
        clk,
        reset_n,
        i_readM,
        i_writeM,
        i_address,
        i_data,
        d_readM,
        d_writeM,
        d_address,
        d_data,
        num_inst,
        output_port,
        is_halted
    );

    input clk;     // clock
    input reset_n; // active-low reset

    // instruction memory interface
    output i_readM;                      // enable instruction memory read
    output i_writeM;                     // enable instruction memory write
    output [`WORD_SIZE - 1:0] i_address; // instruction memory inout data address
    inout [`WORD_SIZE - 1:0] i_data;     // instruction memory inout data

    // data memory interface
    output d_readM;                      // enable data memory read
    output d_writeM;                     // enable data memory write
    output [`WORD_SIZE - 1:0] d_address; // data memory inout data address
    inout [`WORD_SIZE - 1:0] d_data;     // data memory inout data

    // cpu interface
    output [`WORD_SIZE - 1:0] num_inst;    // number of instructions executed
    output [`WORD_SIZE - 1:0] output_port; // WWD output port
    output is_halted;                      // HLT indicator

    // control interface
    wire [`OPCODE_SIZE - 1:0] opcode; // operation code of current instruction
    wire [`FUNC_SIZE - 1:0] func;     // function of current R-type instruction

    wire regwrite;                  // enable register write
    wire memread;                   // enable data memory read
    wire memwrite;                  // enable data memory write
    wire use_rd;                    // if current instruction writes rd
    wire use_imm;                   // if current instruction puts immediate into alu
    wire [`ALUOP_SIZE - 1:0] aluop; // alu operation
    wire branch;                    // if current instruction is branch (BNE, BEQ, BGZ, BLZ)
    wire jump;                      // if current instruciton is jump (JMP, JAL)
    wire jmpr;                      // if current instruciton is jump register (JPR, JRL)
    wire link;                      // if current instruciton links register (JAL, JRL)
    wire wwd;                       // if current instruction is WWD
    wire hlt;                       // if current instruction is HLT

    datapath datapath_unit (.clk(clk),
                            .reset_n(reset_n),
                            .i_readM(i_readM),
                            .i_writeM(i_writeM),
                            .i_address(i_address),
                            .i_data(i_data),
                            .d_readM(d_readM),
                            .d_writeM(d_writeM),
                            .d_address(d_address),
                            .d_data(d_data),
                            .num_inst(num_inst),
                            .output_port(output_port),
                            .is_halted(is_halted),
                            .opcode(opcode),
                            .func(func),
                            .regwrite(regwrite),
                            .memread(memread),
                            .memwrite(memwrite),
                            .use_rd(use_rd),
                            .use_imm(use_imm),
                            .aluop(aluop),
                            .branch(branch),
                            .jump(jump),
                            .jmpr(jmpr),
                            .link(link),
                            .wwd(wwd),
                            .hlt(hlt));

    control control_unit (.opcode(opcode),
                          .func(func),
                          .regwrite(regwrite),
                          .memread(memread),
                          .memwrite(memwrite),
                          .use_rd(use_rd),
                          .use_imm(use_imm),
                          .aluop(aluop),
                          .branch(branch),
                          .jump(jump),
                          .jmpr(jmpr),
                          .link(link),
                          .wwd(wwd),
                          .hlt(hlt));
endmodule
