`timescale 1ns / 100ps

`include "constants.v"
`include "opcodes.v"

module cpu (
        clk,
        reset_n,
        inputReady,
        readM,
        writeM,
        address,
        data,
        num_inst,
        output_port,
        is_halted
    );

    input clk;     // clock
    input reset_n; // active-low reset

    // memory interface
    input inputReady;                  // if memory read is done
    output readM;                      // enable memory read
    output writeM;                     // enable memory write
    output [`WORD_SIZE - 1:0] address; // memory inout data address
    inout [`WORD_SIZE - 1:0] data;     // memory inout data

    // cpu interface
    output [`WORD_SIZE - 1:0] num_inst;    // number of instructions executed
    output [`WORD_SIZE - 1:0] output_port; // WWD output port
    output is_halted;                      // HLT indicator

    // control interface
    wire [`OPCODE_SIZE - 1:0] opcode; // operation code of current instruction
    wire [`FUNC_SIZE - 1:0] func;     // function of current R-format instruction

    wire [`STATE_SIZE - 1:0] nstate; // next control state
    wire pcwrite;                    // enable pc write
    wire irwrite;                    // enable ir write
    wire regwrite;                   // enable register write
    wire imemread;                   // enable instruction memory read
    wire dmemread;                   // enable data memory read
    wire dmemwrite;                  // enable data memory write
    wire use_rd;                     // if current instruction uses rd
    wire add_pc;                     // advance pc to next address
    wire use_aor;                    // if current instruction uses aor as alu in1
    wire use_imm;                    // if current instruction uses immediate as alu in2
    wire [`ALUOP_SIZE - 1:0] aluop;  // alu operation
    wire load;                       // if current instruction is load (LWD)
    wire branch;                     // if current instruction is branch (BNE, BEQ, BGZ, BLZ)
    wire jump;                       // if current instruciton is jump (JMP, JAL)
    wire jmpr;                       // if current instruciton is jump register (JPR, JRL)
    wire link;                       // if current instruciton links register (JAL, JRL)
    wire wwd;                        // if current instruction is WWD
    wire hlt;                        // if current instruction is HLT

    datapath datapath_unit (.clk(clk),
                            .reset_n(reset_n),
                            .readM(readM),
                            .writeM(writeM),
                            .address(address),
                            .data(data),
                            .num_inst(num_inst),
                            .output_port(output_port),
                            .is_halted(is_halted),
                            .opcode(opcode),
                            .func(func),
                            .nstate(nstate),
                            .pcwrite(pcwrite),
                            .irwrite(irwrite),
                            .regwrite(regwrite),
                            .imemread(imemread),
                            .dmemread(dmemread),
                            .dmemwrite(dmemwrite),
                            .use_rd(use_rd),
                            .add_pc(add_pc),
                            .use_aor(use_aor),
                            .use_imm(use_imm),
                            .aluop(aluop),
                            .load(load),
                            .branch(branch),
                            .jump(jump),
                            .jmpr(jmpr),
                            .link(link),
                            .wwd(wwd),
                            .hlt(hlt));

    control control_unit (.clk(clk),
                          .reset_n(reset_n),
                          .opcode(opcode),
                          .func(func),
                          .nstate(nstate),
                          .pcwrite(pcwrite),
                          .irwrite(irwrite),
                          .regwrite(regwrite),
                          .imemread(imemread),
                          .dmemread(dmemread),
                          .dmemwrite(dmemwrite),
                          .use_rd(use_rd),
                          .add_pc(add_pc),
                          .use_aor(use_aor),
                          .use_imm(use_imm),
                          .aluop(aluop),
                          .load(load),
                          .branch(branch),
                          .jump(jump),
                          .jmpr(jmpr),
                          .link(link),
                          .wwd(wwd),
                          .hlt(hlt));
endmodule
