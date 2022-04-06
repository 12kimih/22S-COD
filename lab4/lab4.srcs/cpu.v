`timescale 1ns / 100ps

`include "constants.v"
`include "opcodes.v"

module cpu (
        clk,
        reset_n,
        i_readM,
        d_readM,
        d_writeM,
        i_inputReady,
        d_inputReady,
        i_address,
        d_address,
        i_data,
        d_data,
        num_inst,
        output_port,
        is_halted
    );

    input clk;     // clock
    input reset_n; // active-low reset

    output i_readM;                      // enable instruction memory read
    output d_readM;                      // enable data memory read
    output d_writeM;                     // enable data memory write
    input i_inputReady;                  // if instruction memory read is done
    input d_inputReady;                  // if data memory read is done
    output [`WORD_SIZE - 1:0] i_address; // instruction memory inout data address
    output [`WORD_SIZE - 1:0] d_address; // data memory inout data address
    inout [`WORD_SIZE - 1:0] i_data;     // instruction memory inout data
    inout [`WORD_SIZE - 1:0] d_data;     // data memory inout data

    output [`WORD_SIZE - 1:0] num_inst;    // number of instructions executed
    output [`WORD_SIZE - 1:0] output_port; // WWD output port
    output is_halted;                      // HLT indicator

    wire [`OPCODE_SIZE - 1:0] opcode; // operation code of current instruction
    wire [`FUNC_SIZE - 1:0] func;     // function of current R-format instruction

    wire [1:0] pcmux;               // PC mux [0:pcplusone|1:{PC[15:12], IR[11:0]}|2:regdata1]
    wire regwrite;                  // enable register write
    wire [1:0] regaddr3mux;         // register address 3 mux [0:IR[9:8]|1:IR[7:6]|2:`REG_ADDR'd2]
    wire [1:0] regdata3mux;         // register data 3 mux [0:aluout|1:MDR|2:pcplusone]
    wire [`ALUOP_SIZE - 1:0] aluop; // ALU operation
    wire aluin2mux;                 // ALU input 2 [0:regdata2|1:extimm]
    wire branch;                    // if current instruction is branch
    wire wwd;                       // if current instruction is WWD

    datapath datapath_unit (.clk(clk),
                            .reset_n(reset_n),
                            .opcode(opcode),
                            .func(func),
                            .pcmux(pcmux),
                            .d_memwrite(d_writeM),
                            .regwrite(regwrite),
                            .regaddr3mux(regaddr3mux),
                            .regdata3mux(regdata3mux),
                            .aluop(aluop),
                            .aluin2mux(aluin2mux),
                            .branch(branch),
                            .wwd(wwd),
                            .hlt(is_halted),
                            .i_memread(i_readM),
                            .i_inputReady(i_inputReady),
                            .d_inputReady(d_inputReady),
                            .i_address(i_address),
                            .d_address(d_address),
                            .i_data(i_data),
                            .d_data(d_data),
                            .num_inst(num_inst),
                            .output_port(output_port));

    control control_unit (.opcode(opcode),
                          .func(func),
                          .pcmux(pcmux),
                          .d_memread(d_readM),
                          .d_memwrite(d_writeM),
                          .regwrite(regwrite),
                          .regaddr3mux(regaddr3mux),
                          .regdata3mux(regdata3mux),
                          .aluop(aluop),
                          .aluin2mux(aluin2mux),
                          .branch(branch),
                          .wwd(wwd),
                          .hlt(is_halted));
endmodule
