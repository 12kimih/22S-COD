`timescale 1ns / 1ns

`include "constants.v"
`include "opcodes.v"

module datapath_v3_1 (
        clk,
        reset_n,
        opcode,
        func,
        use_rs,
        use_rt,
        use_rd,
        use_imm,
        aluop,
        regwrite,
        memread,
        memwrite,
        branch,
        jump,
        jmpr,
        link,
        wwd,
        hlt,
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

    // control interface
    output [`OPCODE_SIZE - 1:0] opcode; // operation code of current instruction
    output [`FUNC_SIZE - 1:0] func;     // function of current R-type instruction

    input use_rs;                    // if current instruction uses rs
    input use_rt;                    // if current instruction uses rt
    input use_rd;                    // if current instruction writes rd
    input use_imm;                   // if current instruction puts immediate into alu
    input [`ALUOP_SIZE - 1:0] aluop; // alu operation
    input regwrite;                  // enable register write
    input memread;                   // enable data memory read
    input memwrite;                  // enable data memory write
    input branch;                    // if current instruction is branch (BNE, BEQ, BGZ, BLZ)
    input jump;                      // if current instruciton is jump (JMP, JAL)
    input jmpr;                      // if current instruciton is jump register (JPR, JRL)
    input link;                      // if current instruciton links register (JAL, JRL)
    input wwd;                       // if current instruction is WWD
    input hlt;                       // if current instruction is HLT

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

    // pc registers
    reg [`WORD_SIZE - 1:0] pc;
    wire [`WORD_SIZE - 1:0] pcplusone;

    // ifid registers
    reg [`WORD_SIZE - 1:0] ifid_pc;
    reg [`WORD_SIZE - 1:0] ifid_pcplusone;
    wire [`WORD_SIZE - 1:0] ifid_target;
    reg [`WORD_SIZE - 1:0] ifid_predpc;

    reg ifid_nop;
    reg [`INST_SIZE - 1:0] ifid_ir;

    wire [`REG_ADDR - 1:0] regaddr1;
    wire [`REG_ADDR - 1:0] regaddr2;
    wire [`REG_ADDR - 1:0] regaddr3;
    wire [`WORD_SIZE - 1:0] regdata1;
    wire [`WORD_SIZE - 1:0] regdata2;
    wire [`WORD_SIZE - 1:0] forward1;
    wire [`WORD_SIZE - 1:0] forward2;
    wire [`WORD_SIZE - 1:0] extimm;

    // idex registers
    reg [`WORD_SIZE - 1:0] idex_pc;
    reg [`WORD_SIZE - 1:0] idex_pcplusone;
    reg [`WORD_SIZE - 1:0] idex_target;
    reg [`WORD_SIZE - 1:0] idex_predpc;
    wire [`WORD_SIZE - 1:0] idex_nextpc;

    reg idex_nop;
    reg idex_use_imm;
    reg [`ALUOP_SIZE - 1:0] idex_aluop;
    reg idex_regwrite;
    reg idex_memread;
    reg idex_memwrite;
    reg idex_branch;
    reg idex_jump;
    reg idex_jmpr;
    reg idex_link;
    reg idex_wwd;
    reg idex_hlt;

    reg [`REG_ADDR - 1:0] idex_regaddr3;
    reg [`WORD_SIZE - 1:0] idex_regdata1;
    reg [`WORD_SIZE - 1:0] idex_regdata2;
    wire [`WORD_SIZE - 1:0] idex_regdata3;
    reg [`WORD_SIZE - 1:0] idex_extimm;

    wire [`WORD_SIZE - 1:0] aluin1;
    wire [`WORD_SIZE - 1:0] aluin2;
    wire [`WORD_SIZE - 1:0] aluout;
    wire bcond;

    // exmem registers
    reg [`WORD_SIZE - 1:0] exmem_pc;
    reg [`WORD_SIZE - 1:0] exmem_pcplusone;
    reg [`WORD_SIZE - 1:0] exmem_target;
    reg [`WORD_SIZE - 1:0] exmem_predpc;
    reg [`WORD_SIZE - 1:0] exmem_nextpc;

    reg exmem_nop;
    reg exmem_regwrite;
    reg exmem_memread;
    reg exmem_memwrite;
    reg exmem_btb;
    reg exmem_link;
    reg exmem_wwd;
    reg exmem_hlt;

    reg [`REG_ADDR - 1:0] exmem_regaddr3;
    reg [`WORD_SIZE - 1:0] exmem_regdata1;
    reg [`WORD_SIZE - 1:0] exmem_regdata2;
    wire [`WORD_SIZE - 1:0] exmem_regdata3;
    reg [`WORD_SIZE - 1:0] exmem_aluout;

    // memwb registers
    reg memwb_nop;
    reg memwb_regwrite;
    reg memwb_wwd;
    reg memwb_hlt;

    reg [`REG_ADDR - 1:0] memwb_regaddr3;
    reg [`WORD_SIZE - 1:0] memwb_regdata1;
    reg [`WORD_SIZE - 1:0] memwb_regdata3;

    // BTB wires
    wire [`WORD_SIZE - 1:0] predpc;

    // hazard wires
    wire pc_stall;
    wire ifid_stall;
    wire pc_flush;
    wire ifid_flush;
    wire idex_flush;
    wire exmem_flush;
    wire memwb_flush;

    // forward wires
    wire [1:0] forward1_mux;
    wire [1:0] forward2_mux;

    BTB_AT btb_unit (.clk(clk),
                     .reset_n(reset_n),
                     .pc(pc),
                     .pcplusone(pcplusone),
                     .predpc(predpc),
                     .update_btb(exmem_btb),
                     .update_pc(exmem_pc),
                     .update_target(exmem_target));

    hazard_v3 hazard_unit (.use_rs(use_rs),
                           .use_rt(use_rt),
                           .regaddr1(regaddr1),
                           .regaddr2(regaddr2),
                           .idex_regwrite(idex_regwrite),
                           .idex_memread(idex_memread),
                           .idex_regaddr3(idex_regaddr3),
                           .exmem_predpc(exmem_predpc),
                           .exmem_nextpc(exmem_nextpc),
                           .exmem_hlt(exmem_hlt),
                           .memwb_hlt(memwb_hlt),
                           .is_halted(is_halted),
                           .pc_stall(pc_stall),
                           .ifid_stall(ifid_stall),
                           .pc_flush(pc_flush),
                           .ifid_flush(ifid_flush),
                           .idex_flush(idex_flush),
                           .exmem_flush(exmem_flush),
                           .memwb_flush(memwb_flush));

    forward forward_unit (.regaddr1(regaddr1),
                          .regaddr2(regaddr2),
                          .idex_regwrite(idex_regwrite),
                          .exmem_regwrite(exmem_regwrite),
                          .memwb_regwrite(memwb_regwrite),
                          .idex_regaddr3(idex_regaddr3),
                          .exmem_regaddr3(exmem_regaddr3),
                          .memwb_regaddr3(memwb_regaddr3),
                          .forward1_mux(forward1_mux),
                          .forward2_mux(forward2_mux));

    // >>> pc >>>
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            pc <= `WORD_SIZE'd0;
        end
        else begin
            if (pc_flush) begin
                pc <= exmem_nextpc;
            end
            else if (pc_stall) begin
                pc <= pc;
            end
            else begin
                pc <= predpc;
            end
        end
    end

    assign pcplusone = pc + `WORD_SIZE'd1;
    // <<< pc <<<

    // >>> ifid >>>
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            ifid_pc <= `WORD_SIZE'b0;
            ifid_pcplusone <= `WORD_SIZE'b0;
            ifid_predpc <= `WORD_SIZE'b0;

            ifid_nop <= 1'b1;
            ifid_ir <= `INST_SIZE'b0;
        end
        else begin
            if (ifid_flush) begin
                ifid_pc <= `WORD_SIZE'b0;
                ifid_pcplusone <= `WORD_SIZE'b0;
                ifid_predpc <= `WORD_SIZE'b0;

                ifid_nop <= 1'b1;
                ifid_ir <= `INST_SIZE'b0;
            end
            else if (ifid_stall) begin
                ifid_pc <= ifid_pc;
                ifid_pcplusone <= ifid_pcplusone;
                ifid_predpc <= ifid_predpc;

                ifid_nop <= ifid_nop;
                ifid_ir <= ifid_ir;
            end
            else begin
                ifid_pc <= pc;
                ifid_pcplusone <= pcplusone;
                ifid_predpc <= predpc;

                ifid_nop <= 1'b0;
                ifid_ir <= i_data;
            end
        end
    end

    assign ifid_target = branch ? ifid_pcplusone + extimm : jump ? {ifid_pc[15:12], ifid_ir[11:0]} : jmpr ? forward1 : ifid_pcplusone;

    assign regaddr1 = ifid_ir[11:10];
    assign regaddr2 = ifid_ir[9:8];
    assign regaddr3 = use_rd ? ifid_ir[7:6] : link ? `REG_ADDR'd2 : ifid_ir[9:8];

    RF rf_unit (.clk(clk),
                .reset_n(reset_n),
                .write(memwb_regwrite),
                .addr1(regaddr1),
                .addr2(regaddr2),
                .addr3(memwb_regaddr3),
                .data1(regdata1),
                .data2(regdata2),
                .data3(memwb_regdata3));

    assign forward1 = (forward1_mux == 2'd1) ? idex_regdata3 :
           (forward1_mux == 2'd2) ? exmem_regdata3 :
           (forward1_mux == 2'd3) ? memwb_regdata3 : regdata1;
    assign forward2 = (forward2_mux == 2'd1) ? idex_regdata3 :
           (forward2_mux == 2'd2) ? exmem_regdata3 :
           (forward2_mux == 2'd3) ? memwb_regdata3 : regdata2;

    immediate immediate_unit (.opcode(ifid_ir[15:12]),
                              .imm(ifid_ir[7:0]),
                              .extimm(extimm));
    // <<< ifid <<<

    // >>> idex >>>
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            idex_pc <= `WORD_SIZE'b0;
            idex_pcplusone <= `WORD_SIZE'b0;
            idex_target <= `WORD_SIZE'b0;
            idex_predpc <= `WORD_SIZE'b0;

            idex_nop <= 1'b1;
            idex_use_imm <= 1'b0;
            idex_aluop <= `ALUOP_ADD;
            idex_regwrite <= 1'b0;
            idex_memread <= 1'b0;
            idex_memwrite <= 1'b0;
            idex_branch <= 1'b0;
            idex_jump <= 1'b0;
            idex_jmpr <= 1'b0;
            idex_link <= 1'b0;
            idex_wwd <= 1'b0;
            idex_hlt <= 1'b0;

            idex_regaddr3 <= `REG_ADDR'b0;
            idex_regdata1 <= `WORD_SIZE'b0;
            idex_regdata2 <= `WORD_SIZE'b0;
            idex_extimm <= `WORD_SIZE'b0;
        end
        else begin
            if (idex_flush) begin
                idex_pc <= `WORD_SIZE'b0;
                idex_pcplusone <= `WORD_SIZE'b0;
                idex_target <= `WORD_SIZE'b0;
                idex_predpc <= `WORD_SIZE'b0;

                idex_nop <= 1'b1;
                idex_use_imm <= 1'b0;
                idex_aluop <= `ALUOP_ADD;
                idex_regwrite <= 1'b0;
                idex_memread <= 1'b0;
                idex_memwrite <= 1'b0;
                idex_branch <= 1'b0;
                idex_jump <= 1'b0;
                idex_jmpr <= 1'b0;
                idex_link <= 1'b0;
                idex_wwd <= 1'b0;
                idex_hlt <= 1'b0;

                idex_regaddr3 <= `REG_ADDR'b0;
                idex_regdata1 <= `WORD_SIZE'b0;
                idex_regdata2 <= `WORD_SIZE'b0;
                idex_extimm <= `WORD_SIZE'b0;
            end
            else begin
                idex_pc <= ifid_pc;
                idex_pcplusone <= ifid_pcplusone;
                idex_target <= ifid_target;
                idex_predpc <= ifid_predpc;

                idex_nop <= ifid_nop;
                idex_use_imm <= use_imm;
                idex_aluop <= aluop;
                idex_regwrite <= regwrite;
                idex_memread <= memread;
                idex_memwrite <= memwrite;
                idex_branch <= branch;
                idex_jump <= jump;
                idex_jmpr <= jmpr;
                idex_link <= link;
                idex_wwd <= wwd;
                idex_hlt <= hlt;

                idex_regaddr3 <= regaddr3;
                idex_regdata1 <= forward1;
                idex_regdata2 <= forward2;
                idex_extimm <= extimm;
            end
        end
    end

    assign idex_nextpc = ((idex_branch && bcond) || idex_jump || idex_jmpr) ? idex_target : idex_pcplusone;
    assign idex_regdata3 = idex_link ? idex_pcplusone : aluout;

    assign aluin1 = idex_regdata1;
    assign aluin2 = idex_use_imm ? idex_extimm : idex_regdata2;

    ALU alu_unit (.op(idex_aluop),
                  .in1(aluin1),
                  .in2(aluin2),
                  .out(aluout));

    assign bcond = aluout[0];
    // <<< idex <<<

    // >>> exmem >>>
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            exmem_pc <= `WORD_SIZE'b0;
            exmem_pcplusone <= `WORD_SIZE'b0;
            exmem_target <= `WORD_SIZE'b0;
            exmem_predpc <= `WORD_SIZE'b0;
            exmem_nextpc <= `WORD_SIZE'b0;

            exmem_nop <= 1'b1;
            exmem_regwrite <= 1'b0;
            exmem_memread <= 1'b0;
            exmem_memwrite <= 1'b0;
            exmem_btb <= 1'b0;
            exmem_link <= 1'b0;
            exmem_wwd <= 1'b0;
            exmem_hlt <= 1'b0;

            exmem_regaddr3 <= `REG_ADDR'b0;
            exmem_regdata1 <= `WORD_SIZE'b0;
            exmem_regdata2 <= `WORD_SIZE'b0;
            exmem_aluout <= `WORD_SIZE'b0;
        end
        else begin
            if (exmem_flush) begin
                exmem_pc <= `WORD_SIZE'b0;
                exmem_pcplusone <= `WORD_SIZE'b0;
                exmem_target <= `WORD_SIZE'b0;
                exmem_predpc <= `WORD_SIZE'b0;
                exmem_nextpc <= `WORD_SIZE'b0;

                exmem_nop <= 1'b1;
                exmem_regwrite <= 1'b0;
                exmem_memread <= 1'b0;
                exmem_memwrite <= 1'b0;
                exmem_btb <= 1'b0;
                exmem_link <= 1'b0;
                exmem_wwd <= 1'b0;
                exmem_hlt <= 1'b0;

                exmem_regaddr3 <= `REG_ADDR'b0;
                exmem_regdata1 <= `WORD_SIZE'b0;
                exmem_regdata2 <= `WORD_SIZE'b0;
                exmem_aluout <= `WORD_SIZE'b0;
            end
            else begin
                exmem_pc <= idex_pc;
                exmem_pcplusone <= idex_pcplusone;
                exmem_target <= idex_target;
                exmem_predpc <= idex_predpc;
                exmem_nextpc <= idex_nextpc;

                exmem_nop <= idex_nop;
                exmem_regwrite <= idex_regwrite;
                exmem_memread <= idex_memread;
                exmem_memwrite <= idex_memwrite;
                exmem_btb <= idex_branch || idex_jump || idex_jmpr;
                exmem_link <= idex_link;
                exmem_wwd <= idex_wwd;
                exmem_hlt <= idex_hlt;

                exmem_regaddr3 <= idex_regaddr3;
                exmem_regdata1 <= idex_regdata1;
                exmem_regdata2 <= idex_regdata2;
                exmem_aluout <= aluout;
            end
        end
    end

    assign exmem_regdata3 = exmem_memread ? d_data : exmem_link ? exmem_pcplusone : exmem_aluout;
    // <<< exmem <<<

    // >>> memwb >>>
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            memwb_nop <= 1'b1;
            memwb_regwrite <= 1'b0;
            memwb_wwd <= 1'b0;
            memwb_hlt <= 1'b0;

            memwb_regaddr3 <= `REG_ADDR'b0;
            memwb_regdata1 <= `WORD_SIZE'b0;
            memwb_regdata3 <= `WORD_SIZE'b0;
        end
        else begin
            if (memwb_flush) begin
                memwb_nop <= 1'b1;
                memwb_regwrite <= 1'b0;
                memwb_wwd <= 1'b0;
                memwb_hlt <= 1'b0;

                memwb_regaddr3 <= `REG_ADDR'b0;
                memwb_regdata1 <= `WORD_SIZE'b0;
                memwb_regdata3 <= `WORD_SIZE'b0;
            end
            else begin
                memwb_nop <= exmem_nop;
                memwb_regwrite <= exmem_regwrite;
                memwb_wwd <= exmem_wwd;
                memwb_hlt <= exmem_hlt;

                memwb_regaddr3 <= exmem_regaddr3;
                memwb_regdata1 <= exmem_regdata1;
                memwb_regdata3 <= exmem_regdata3;
            end
        end
    end
    // <<< memwb <<<

    // >>> output >>>
    assign opcode = ifid_ir[15:12];
    assign func = ifid_ir[5:0];

    assign i_readM = 1'b1;
    assign i_writeM = 1'b0;
    assign i_address = pc;
    assign d_readM = exmem_memread;
    assign d_writeM = exmem_memwrite;
    assign d_address = exmem_aluout;
    assign d_data = exmem_memwrite ? exmem_regdata2 : `WORD_SIZE'bz;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            num_inst <= `WORD_SIZE'd0;
            output_port <= `WORD_SIZE'b0;
            is_halted <= 1'b0;
        end
        else begin
            if (!memwb_nop) begin
                num_inst <= num_inst + `WORD_SIZE'd1;
            end
            if (memwb_wwd) begin
                output_port <= memwb_regdata1;
            end
            if (memwb_hlt) begin
                is_halted <= 1'b1;
            end
        end
    end
    // <<< output <<<
endmodule
