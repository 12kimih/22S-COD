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

    output readM;                      // enable memory read
    output writeM;                     // enable memory write
    input inputReady;                  // if memory read is done
    output [`WORD_SIZE - 1:0] address; // memory inout data address
    inout [`WORD_SIZE - 1:0] data;     // memory inout data

    output [`WORD_SIZE - 1:0] num_inst;    // number of instructions executed
    output [`WORD_SIZE - 1:0] output_port; // WWD output port
    output is_halted;                      // HLT indicator

    wire [`OPCODE_SIZE - 1:0] opcode; // operation code of current instruction
    wire [`FUNC_SIZE - 1:0] func;     // function of current R-format instruction

    wire pcwrite;                   // PC write
    wire [1:0] pcmux;               // PC mux [0:AOR|1:{PC[15:12], IR[11:0]}|2:regdata1]
    wire memaddrmux;                // memory address mux [0:PC|1:AOR]
    wire irwrite;                   // IR write
    wire regwrite;                  // enable register write
    wire [1:0] regaddr3mux;         // register address 3 mux [0:IR[9:8]|1:IR[7:6]|2:`REG_ADDR'd2]
    wire regdata3mux;               // register data 3 mux [0:AOR|1:MDR]
    wire [`ALUOP_SIZE - 1:0] aluop; // ALU operation
    wire aluin1mux;                 // ALU input 1 [0:regdata1|1:PC]
    wire [1:0] aluin2mux;           // ALU input 2 [0:regdata2|1:extimm|2:`WORD_SIZE'd1]
    wire branch;                    // if current instruction is branch
    wire wwd;                       // if current instruction is WWD

    datapath datapath_unit (.clk(clk),
                            .reset_n(reset_n),
                            .opcode(opcode),
                            .func(func),
                            .pcwrite(pcwrite),
                            .pcmux(pcmux),
                            .memwrite(writeM),
                            .memaddrmux(memaddrmux),
                            .irwrite(irwrite),
                            .regwrite(regwrite),
                            .regaddr3mux(regaddr3mux),
                            .regdata3mux(regaddr3mux),
                            .aluop(aluop),
                            .aluin1mux(aluin1mux),
                            .aluin2mux(aluin2mux),
                            .branch(branch),
                            .wwd(wwd),
                            .inputReady(inputReady),
                            .address(address),
                            .data(data),
                            .output_port(output_port));

    control control_unit (.clk(clk),
                          .reset_n(reset_n),
                          .opcode(opcode),
                          .func(func),
                          .pcwrite(pcwrite),
                          .pcmux(pcmux),
                          .memread(readM),
                          .memwrite(writeM),
                          .memaddrmux(memaddrmux),
                          .irwrite(irwrite),
                          .regwrite(regwrite),
                          .regaddr3mux(regaddr3mux),
                          .regdata3mux(regdata3mux),
                          .aluop(aluop),
                          .aluin1mux(aluin1mux),
                          .aluin2mux(aluin2mux),
                          .branch(branch),
                          .wwd(wwd),
                          .hlt(is_halted),
                          .num_inst(num_inst));
endmodule
