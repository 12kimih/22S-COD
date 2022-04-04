`timescale 1ns / 100ps

`include "constants.v"
`include "opcodes.v"

module datapath (
        clk,
        reset_n,
        opcode,
        func,
        pcwrite,
        pcmux,
        memwrite,
        memaddrmux,
        irwrite,
        regwrite,
        regaddr3mux,
        regdata3mux,
        aluop,
        aluin1mux,
        aluin2mux,
        branch,
        wwd,
        inputReady,
        address,
        data,
        output_port
    );

    input clk;     // clock
    input reset_n; // active-low reset

    output [`OPCODE_SIZE - 1:0] opcode; // operation code of current instruction
    output [`FUNC_SIZE - 1:0] func;     // function of current R-format instruction

    input pcwrite;                   // PC write
    input [1:0] pcmux;               // PC mux [0:AOR|1:{PC[15:12], IR[11:0]}|2:regdata1]
    input memwrite;                  // enable memory write
    input memaddrmux;                // memory address mux [0:PC|1:AOR]
    input irwrite;                   // IR write
    input regwrite;                  // enable register write
    input [1:0] regaddr3mux;         // register address 3 mux [0:IR[9:8]|1:IR[7:6]|2:`REG_ADDR'd2]
    input regdata3mux;               // register data 3 mux [0:AOR|1:MDR]
    input [`ALUOP_SIZE - 1:0] aluop; // ALU operation
    input [1:0] aluin1mux;           // ALU input 1 [0:regdata1|1:PC|2:AOR]
    input [1:0] aluin2mux;           // ALU input 2 [0:regdata2|1:extimm|2:`WORD_SIZE'd1]
    input branch;                    // if current instruction is branch
    input wwd;                       // if current instruction is WWD

    input inputReady;                  // if memory read is done
    output [`WORD_SIZE - 1:0] address; // memory inout data address
    inout [`WORD_SIZE - 1:0] data;     // memory inout data

    output reg [`WORD_SIZE - 1:0] output_port; // WWD output port

    reg [`WORD_SIZE - 1:0] PC;
    reg [`INST_SIZE - 1:0] IR;
    reg [`WORD_SIZE - 1:0] MDR;
    reg [`WORD_SIZE - 1:0] AOR;

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
            PC <= `WORD_SIZE'b0;
        end
        else begin
            if (pcwrite || (branch && bcond)) begin
                PC <= (pcmux == 2'd0) ? AOR :
                   (pcmux == 2'd1) ? {PC[15:12], IR[11:0]} :
                   (pcmux == 2'd2) ? regdata1 : AOR;
            end
        end
    end
    // <<< PC <<<

    // >>> IR >>>
    always @(posedge inputReady or negedge reset_n) begin
        if (!reset_n) begin
            IR <= `INST_SIZE'b0;
        end
        else begin
            if (irwrite) begin
                IR <= data;
            end
        end
    end
    // <<< IR <<<

    // >>> MDR >>>
    always @(posedge inputReady or negedge reset_n) begin
        if (!reset_n) begin
            MDR <= `WORD_SIZE'b0;
        end
        else begin
            MDR <= data;
        end
    end
    // <<< MDR <<<

    // >>> RF >>>
    assign regaddr1 = IR[11:10];
    assign regaddr2 = IR[9:8];
    assign regaddr3 = (regaddr3mux == 2'd0) ? IR[9:8] :
           (regaddr3mux == 2'd1) ? IR[7:6] :
           (regaddr3mux == 2'd2) ? `REG_ADDR'd2 : IR[9:8];
    assign regdata3 = regdata3mux ? MDR : AOR;

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
    assign aluin1 = (aluin1mux == 2'd0) ? regdata1 :
           (aluin1mux == 2'd1) ? PC :
           (aluin1mux == 2'd2) ? AOR : regdata1;
    assign aluin2 = (aluin2mux == 2'd0) ? regdata2 :
           (aluin2mux == 2'd1) ? extimm :
           (aluin2mux == 2'd2) ? `WORD_SIZE'd1 : regdata2;
    assign bcond = aluout[0];

    ALU alu (.op(aluop),
             .in1(aluin1),
             .in2(aluin2),
             .out(aluout));
    // <<< ALU <<<

    // >>> AOR >>>
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            AOR <= `WORD_SIZE'b0;
        end
        else begin
            AOR <= aluout;
        end
    end
    // <<< AOR <<<

    // >>> output >>>
    assign opcode = IR[15:12];
    assign func = IR[5:0];

    assign address = memaddrmux ? AOR : PC;
    assign data = memwrite ? regdata2 : `WORD_SIZE'bz;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            output_port <= `WORD_SIZE'b0;
        end
        else begin
            if (wwd) begin
                output_port <= regdata1;
            end
        end
    end
    // <<< output <<<
endmodule
