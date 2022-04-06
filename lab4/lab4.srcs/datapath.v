`timescale 1ns / 100ps

`include "constants.v"
`include "opcodes.v"

module datapath (
        clk,
        reset_n,
        opcode,
        func,
        pcmux,
        d_memwrite,
        regwrite,
        regaddr3mux,
        regdata3mux,
        aluop,
        aluin2mux,
        branch,
        wwd,
        hlt,
        i_memread,
        i_inputReady,
        d_inputReady,
        i_address,
        d_address,
        i_data,
        d_data,
        num_inst,
        output_port
    );

    input clk;     // clock
    input reset_n; // active-low reset

    output [`OPCODE_SIZE - 1:0] opcode; // operation code of current instruction
    output [`FUNC_SIZE - 1:0] func;     // function of current R-format instruction

    input [1:0] pcmux;               // PC mux [0:pcplusone|1:{PC[15:12], IR[11:0]}|2:regdata1]
    input d_memwrite;                // enable data memory write
    input regwrite;                  // enable register write
    input [1:0] regaddr3mux;         // register address 3 mux [0:IR[9:8]|1:IR[7:6]|2:`REG_ADDR'd2]
    input [1:0] regdata3mux;         // register data 3 mux [0:aluout|1:MDR|2:pcplusone]
    input [`ALUOP_SIZE - 1:0] aluop; // ALU operation
    input aluin2mux;                 // ALU input 2 [0:regdata2|1:extimm]
    input branch;                    // if current instruction is branch
    input wwd;                       // if current instruction is WWD
    input hlt;                       // if current instruction is HLT

    output reg i_memread;                // enable instruction memory read
    input i_inputReady;                  // if instruction memory read is done
    input d_inputReady;                  // if data memory read is done
    output [`WORD_SIZE - 1:0] i_address; // instruction memory inout data address
    output [`WORD_SIZE - 1:0] d_address; // data memory inout data address
    inout [`WORD_SIZE - 1:0] i_data;     // instruction memory inout data
    inout [`WORD_SIZE - 1:0] d_data;     // data memory inout data

    output reg [`WORD_SIZE - 1:0] num_inst;    // number of instructions executed
    output reg [`WORD_SIZE - 1:0] output_port; // WWD output port

    reg [`WORD_SIZE - 1:0] PC;
    reg [`INST_SIZE - 1:0] IR;
    reg [`WORD_SIZE - 1:0] MDR;

    wire [`WORD_SIZE - 1:0] pcplusone;

    wire [`REG_ADDR - 1:0] regaddr1;
    wire [`REG_ADDR - 1:0] regaddr2;
    wire [`REG_ADDR - 1:0] regaddr3;
    wire [`WORD_SIZE - 1:0] regdata1;
    wire [`WORD_SIZE - 1:0] regdata2;
    wire [`WORD_SIZE - 1:0] regdata3;

    wire [`WORD_SIZE - 1:0] extimm;

    wire [`WORD_SIZE - 1:0] aluin1;
    wire [`WORD_SIZE - 1:0] aluin2;
    wire [`WORD_SIZE - 1:0] aluout;
    wire bcond;

    // >>> PC >>>
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            PC <= -`WORD_SIZE'd1;
        end
        else begin
            if (!hlt) begin
                PC <= (branch && bcond) ? pcplusone + extimm :
                   (pcmux == 2'd0) ? pcplusone :
                   (pcmux == 2'd1) ? {PC[15:12], IR[11:0]} :
                   (pcmux == 2'd2) ? regdata1 : pcplusone;
            end
        end
    end

    assign pcplusone = PC + `WORD_SIZE'd1;
    // <<< PC <<<

    // >>> IR >>>
    always @(posedge i_inputReady or posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            IR <= `INST_SIZE'b0;
            i_memread <= 1'b0;
        end
        else begin
            IR <= i_inputReady ? i_data : `INST_SIZE'b0;
            i_memread <= i_inputReady ? 1'b0 : 1'b1;
        end
    end
    // <<< IR <<<

    // >>> MDR >>>
    always @(posedge d_inputReady or posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            MDR <= `WORD_SIZE'b0;
        end
        else begin
            MDR <= d_inputReady ? d_data : `WORD_SIZE'b0;
        end
    end
    // <<< MDR <<<

    // >>> RF >>>
    assign regaddr1 = IR[11:10];
    assign regaddr2 = IR[9:8];
    assign regaddr3 = (regaddr3mux == 2'd0) ? IR[9:8] :
           (regaddr3mux == 2'd1) ? IR[7:6] :
           (regaddr3mux == 2'd2) ? `REG_ADDR'd2 : IR[9:8];
    assign regdata3 = (regdata3mux == 2'd0) ? aluout :
           (regdata3mux == 2'd1) ? MDR :
           (regdata3mux == 2'd2) ? pcplusone : aluout;

    RF rf (.clk(clk),
           .reset_n(reset_n),
           .write(regwrite),
           .addr1(regaddr1),
           .addr2(regaddr2),
           .addr3(regaddr3),
           .data1(regdata1),
           .data2(regdata2),
           .data3(regdata3));
    // <<< RF <<<

    // >>> immediate >>>
    immediate immediate_unit (.opcode(IR[15:12]),
                              .imm(IR[7:0]),
                              .extimm(extimm));
    // <<< immediate <<<

    // >>> ALU >>>
    assign aluin1 = regdata1;
    assign aluin2 = aluin2mux ? extimm : regdata2;

    ALU alu (.op(aluop),
             .in1(aluin1),
             .in2(aluin2),
             .out(aluout));

    assign bcond = aluout[0];
    // <<< ALU <<<

    // >>> output >>>
    assign opcode = IR[15:12];
    assign func = IR[5:0];

    assign i_address = PC;
    assign d_address = aluout;
    assign d_data = d_memwrite ? regdata2 : `WORD_SIZE'bz;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            num_inst <= -`WORD_SIZE'd1;
            output_port <= `WORD_SIZE'b0;
        end
        else begin
            num_inst <= num_inst + `WORD_SIZE'd1;
            if (wwd) begin
                output_port <= regdata1;
            end
        end
    end
    // <<< output <<<
endmodule
