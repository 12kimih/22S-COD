`timescale 1ns / 1ns

`include "constants.v"
`include "opcodes.v"

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

    output [`WORD_SIZE - 1:0] num_inst;    // number of instructions executed
    output [`WORD_SIZE - 1:0] output_port; // WWD output port
    output is_halted;                      // HLT indicator

    // control interface
    wire [`OPCODE_SIZE - 1:0] opcode; // operation code of current instruction
    wire [`FUNC_SIZE - 1:0] func;     // function of current R-format instruction

    wire [1:0] nextpc_mux;          // next pc mux [0:pcplusone|1:{pc[15:12], target}|2:regdata1]
    wire use_regaddr1;              // if current instruction uses regaddr1
    wire use_regaddr2;              // if current instruction uses regaddr2
    wire regwrite;                  // enable register write
    wire [1:0] regaddr3_mux;        // register address 3 mux [0:ir[9:8]|1:ir[7:6]|2:`REG_ADDR'd2]
    wire [1:0] regdata3_mux;        // register data 3 mux [0:aluout|1:mdr|2:pcplusone]
    wire [`ALUOP_SIZE - 1:0] aluop; // alu operation
    wire aluin2_mux;                // alu input 2 mux [0:regdata2|1:extimm]
    wire memread;                   // enable data memory read
    wire memwrite;                  // enable data memory write
    wire branch;                    // if current instruction is branch
    wire wwd;                       // if current instruction is WWD
    wire hlt;                       // if current instruction is HLT

    datapath datapath_unit (.clk(clk),
                            .reset_n(reset_n),
                            .opcode(opcode),
                            .func(func),
                            .nextpc_mux(nextpc_mux),
                            .use_regaddr1(use_regaddr1),
                            .use_regaddr2(use_regaddr2),
                            .regwrite(regwrite),
                            .regaddr3_mux(regaddr3_mux),
                            .regdata3_mux(regdata3_mux),
                            .aluop(aluop),
                            .aluin2_mux(aluin2_mux),
                            .memread(memread),
                            .memwrite(memwrite),
                            .branch(branch),
                            .wwd(wwd),
                            .hlt(hlt),
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
                            .is_halted(is_halted));

    control control_unit (.opcode(opcode),
                          .func(func),
                          .nextpc_mux(nextpc_mux),
                          .use_regaddr1(use_regaddr1),
                          .use_regaddr2(use_regaddr2),
                          .regwrite(regwrite),
                          .regaddr3_mux(regaddr3_mux),
                          .regdata3_mux(regdata3_mux),
                          .aluop(aluop),
                          .aluin2_mux(aluin2_mux),
                          .memread(memread),
                          .memwrite(memwrite),
                          .branch(branch),
                          .wwd(wwd),
                          .hlt(hlt));
endmodule
