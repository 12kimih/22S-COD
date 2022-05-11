`timescale 1ns / 100ps

`include "constants.v"
`include "opcodes.v"

module datapath (
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
        is_halted,
        opcode,
        func,
        regwrite,
        memread,
        memwrite,
        use_rd,
        use_imm,
        aluop,
        load,
        branch,
        jump,
        jmpr,
        link,
        wwd,
        hlt
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
    output reg [`WORD_SIZE - 1:0] num_inst;    // number of instructions executed
    output reg [`WORD_SIZE - 1:0] output_port; // WWD output port
    output reg is_halted;                      // HLT indicator

    // control interface
    output [`OPCODE_SIZE - 1:0] opcode; // operation code of current instruction
    output [`FUNC_SIZE - 1:0] func;     // function of current R-type instruction

    input regwrite;                  // enable register write
    input memread;                   // enable data memory read
    input memwrite;                  // enable data memory write
    input use_rd;                    // if current instruction uses rd
    input use_imm;                   // if current instruction uses immediate
    input [`ALUOP_SIZE - 1:0] aluop; // alu operation
    input load;                      // if current instruction loads memory data into register (LWD)
    input branch;                    // if current instruction contains branch control flow (BNE, BEQ, BGZ, BLZ)
    input jump;                      // if current instruciton contains jump control flow (JMP, JAL)
    input jmpr;                      // if current instruciton contains jump register control flow (JPR, JRL)
    input link;                      // if current instruciton links register to next address (JAL, JRL)
    input wwd;                       // if current instruction writes output port (WWD)
    input hlt;                       // if current instruction halts the machine (HLT)

    reg [`WORD_SIZE - 1:0] pc;
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

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            pc <= `WORD_SIZE'd0;
        end
        else begin
            pc <= (branch && aluout[0]) ? pcplusone + extimm : jump ? {pc[15:12], i_data[11:0]} : jmpr ? regdata1 : pcplusone;
        end
    end

    assign pcplusone = pc + `WORD_SIZE'd1;

    assign regaddr1 = i_data[11:10];
    assign regaddr2 = i_data[9:8];
    assign regaddr3 = use_rd ? i_data[7:6] : link ? `REG_ADDR'd2 : i_data[9:8];
    assign regdata3 = load ? d_data : link ? pcplusone : aluout;

    RF rf (.clk(clk),
           .reset_n(reset_n),
           .write(regwrite),
           .addr1(regaddr1),
           .addr2(regaddr2),
           .addr3(regaddr3),
           .data1(regdata1),
           .data2(regdata2),
           .data3(regdata3));

    immediate immediate_unit (.opcode(i_data[15:12]),
                              .imm(i_data[7:0]),
                              .extimm(extimm));

    assign aluin1 = regdata1;
    assign aluin2 = use_imm ? extimm : regdata2;

    ALU alu (.op(aluop),
             .in1(aluin1),
             .in2(aluin2),
             .out(aluout));

    assign opcode = i_data[15:12];
    assign func = i_data[5:0];

    assign i_readM = 1'b1;
    assign i_writeM = 1'b0;
    assign i_address = pc;

    assign d_readM = memread;
    assign d_writeM = memwrite;
    assign d_address = aluout;
    assign d_data = memwrite ? regdata2 : `WORD_SIZE'bz;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            num_inst <= `WORD_SIZE'd0;
            output_port <= `WORD_SIZE'b0;
            is_halted <= 1'b0;
        end
        else begin
            num_inst <= num_inst + `WORD_SIZE'd1;
            if (wwd) begin
                output_port <= regdata1;
            end
            if (hlt) begin
                is_halted <= 1'b1;
            end
        end
    end
endmodule
