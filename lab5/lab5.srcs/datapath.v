`timescale 1ns / 100ps

`include "constants.v"
`include "opcodes.v"

module datapath (
        clk,
        reset_n,
        readM,
        writeM,
        address,
        data,
        num_inst,
        output_port,
        is_halted,
        opcode,
        func,
        nstate,
        pcwrite,
        irwrite,
        regwrite,
        imemread,
        dmemread,
        dmemwrite,
        use_rd,
        add_pc,
        use_aor,
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

    // memory interface
    output readM;                      // enable memory read
    output writeM;                     // enable memory write
    output [`WORD_SIZE - 1:0] address; // memory inout data address
    inout [`WORD_SIZE - 1:0] data;     // memory inout data

    // cpu interface
    output reg [`WORD_SIZE - 1:0] num_inst;    // number of instructions executed
    output reg [`WORD_SIZE - 1:0] output_port; // WWD output port
    output reg is_halted;                      // HLT indicator

    // control interface
    output [`OPCODE_SIZE - 1:0] opcode; // operation code of current instruction
    output [`FUNC_SIZE - 1:0] func;     // function of current R-format instruction

    input [`STATE_SIZE - 1:0] nstate; // next control state
    input pcwrite;                    // enable pc write
    input irwrite;                    // enable ir write
    input regwrite;                   // enable register write
    input imemread;                   // enable instruction memory read
    input dmemread;                   // enable data memory read
    input dmemwrite;                  // enable data memory write
    input use_rd;                     // if current instruction uses rd
    input add_pc;                     // advance pc to next address
    input use_aor;                    // if current instruction uses aor as alu in1
    input use_imm;                    // if current instruction uses immediate as alu in2
    input [`ALUOP_SIZE - 1:0] aluop;  // alu operation
    input load;                       // if current instruction is load (LWD)
    input branch;                     // if current instruction is branch (BNE, BEQ, BGZ, BLZ)
    input jump;                       // if current instruciton is jump (JMP, JAL)
    input jmpr;                       // if current instruciton is jump register (JPR, JRL)
    input link;                       // if current instruciton links register (JAL, JRL)
    input wwd;                        // if current instruction is WWD
    input hlt;                        // if current instruction is HLT

    reg [`WORD_SIZE - 1:0] pc;
    reg [`INST_SIZE - 1:0] ir;
    reg [`WORD_SIZE - 1:0] mdr;
    reg [`WORD_SIZE - 1:0] aor;

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
            pc <= `WORD_SIZE'b0;
        end
        else begin
            if (pcwrite) begin
                pc <= (branch && !aluout[0]) ? pc : jump ? {pc[15:12], ir[11:0]} : jmpr ? regdata1 : aor;
            end
        end
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            ir <= `INST_SIZE'b0;
        end
        else begin
            if (irwrite) begin
                ir <= data;
            end
        end
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            mdr <= `WORD_SIZE'b0;
        end
        else begin
            mdr <= data;
        end
    end

    assign regaddr1 = ir[11:10];
    assign regaddr2 = ir[9:8];
    assign regaddr3 = use_rd ? ir[7:6] : link ? `REG_ADDR'd2 : ir[9:8];
    assign regdata3 = load ? mdr : aor;

    RF rf (.clk(clk),
           .reset_n(reset_n),
           .write(regwrite),
           .addr1(regaddr1),
           .addr2(regaddr2),
           .addr3(regaddr3),
           .data1(regdata1),
           .data2(regdata2),
           .data3(regdata3));

    immediate immediate_unit (.opcode(ir[15:12]),
                              .imm(ir[7:0]),
                              .extimm(extimm));

    assign aluin1 = add_pc ? pc : use_aor ? aor : regdata1;
    assign aluin2 = add_pc ? `WORD_SIZE'd1 : use_imm ? extimm : regdata2;

    ALU alu (.op(aluop),
             .in1(aluin1),
             .in2(aluin2),
             .out(aluout));

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            aor <= `WORD_SIZE'b0;
        end
        else begin
            aor <= aluout;
        end
    end

    assign opcode = ir[15:12];
    assign func = ir[5:0];

    assign readM = imemread || dmemread;
    assign writeM = dmemwrite;
    assign address = imemread ? pc : aor;
    assign data = dmemwrite ? regdata2 : `WORD_SIZE'bz;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            num_inst <= -`WORD_SIZE'd1;
            output_port <= `WORD_SIZE'b0;
            is_halted <= 1'b0;
        end
        else begin
            if (nstate == `STATE_IF) begin
                num_inst <= num_inst + `WORD_SIZE'd1;
            end
            if (wwd) begin
                output_port <= regdata1;
            end
            if (hlt) begin
                is_halted <= 1'b1;
            end
        end
    end
endmodule
