`timescale 1ns / 100ps

`include "constants.v"
`include "opcodes.v"

module cpu (
        clk,
        reset_n,
        readM,
        inputReady,
        address,
        data,
        num_inst,
        output_port
    );

    input clk;     // clock
    input reset_n; // active-low reset

    output readM;                      // enable memory read
    input inputReady;                  // if memory read is done
    output [`WORD_SIZE - 1:0] address; // memory inout data address
    inout [`WORD_SIZE - 1:0] data;     // memory inout data

    output [`WORD_SIZE - 1:0] num_inst;    // number of instructions executed
    output [`WORD_SIZE - 1:0] output_port; // WWD output port

    wire [`OPCODE_SIZE - 1:0] opcode; // opcode of current instruction
    wire [`FUNC_SIZE - 1:0] func;     // func of current R-format instruction

    wire [1:0] pcmux;               // PC mux [0:PC + `WORD_SIZE'd1|1:aluout|2:{PC[15:12], IR[11:0]}|3:regdata1]
    wire [`ALUOP_SIZE - 1:0] aluop; // ALU operation code
    wire [1:0] aluin1mux;           // ALU input 1 [0:regdata1|1:extimm|2:PC|3:`WORD_SIZE'b0]
    wire [1:0] aluin2mux;           // ALU input 2 [0:regdata2|1:extimm|2:regdata1|3:`WORD_SIZE'b0]
    wire regwrite;                  // enable register write
    wire [1:0] regaddr3mux;         // write register mux [0:IR[9:8]|1:IR[7:6]|2:`REG_ADDR'd2]
    wire [1:0] regdata3mux;         // write data mux [0:aluout|1:memdata1|2:PC|3:input_port]
    wire wwd;                       // if current instruction is WWD

    datapath datapath_unit (.clk(clk),
                            .reset_n(reset_n),
                            .readM(readM),
                            .inputReady(inputReady),
                            .address(address),
                            .data(data),
                            .num_inst(num_inst),
                            .output_port(output_port),
                            .opcode(opcode),
                            .func(func),
                            .pcmux(pcmux),
                            .aluop(aluop),
                            .aluin1mux(aluin1mux),
                            .aluin2mux(aluin2mux),
                            .regwrite(regwrite),
                            .regaddr3mux(regaddr3mux),
                            .regdata3mux(regdata3mux),
                            .wwd(wwd));

    control control_unit (.opcode(opcode),
                          .func(func),
                          .pcmux(pcmux),
                          .aluop(aluop),
                          .aluin1mux(aluin1mux),
                          .aluin2mux(aluin2mux),
                          .regwrite(regwrite),
                          .regaddr3mux(regaddr3mux),
                          .regdata3mux(regdata3mux),
                          .wwd(wwd));
endmodule
