`timescale 1ns / 1ns

`include "constants.v"
`include "opcodes.v"

module datapath (
        clk,
        reset_n,
        opcode,
        func,
        nextpc_mux,
        use_regaddr1,
        use_regaddr2,
        regwrite,
        regaddr3_mux,
        regdata3_mux,
        aluop,
        aluin2_mux,
        memread,
        memwrite,
        branch,
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
    output [`FUNC_SIZE - 1:0] func;     // function of current R-format instruction

    input [1:0] nextpc_mux;          // next pc mux [0:pcplusone|1:{pc[15:12], target}|2:regdata1]
    input use_regaddr1;              // if current instruction uses regaddr1
    input use_regaddr2;              // if current instruction uses regaddr2
    input regwrite;                  // enable register write
    input [1:0] regaddr3_mux;        // register address 3 mux [0:ir[9:8]|1:ir[7:6]|2:`REG_ADDR'd2]
    input [1:0] regdata3_mux;        // register data 3 mux [0:aluout|1:mdr|2:pcplusone]
    input [`ALUOP_SIZE - 1:0] aluop; // alu operation
    input aluin2_mux;                // alu input 2 mux [0:regdata2|1:extimm]
    input memread;                   // enable data memory read
    input memwrite;                  // enable data memory write
    input branch;                    // if current instruction is branch
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
    reg ifid_nop;
    reg [`WORD_SIZE - 1:0] ifid_pc;
    reg [`WORD_SIZE - 1:0] ifid_pcplusone;
    reg [`WORD_SIZE - 1:0] ifid_predpc;

    reg [`INST_SIZE - 1:0] ifid_ir;

    wire [`REG_ADDR - 1:0] regaddr1;
    wire [`REG_ADDR - 1:0] regaddr2;
    wire [`REG_ADDR - 1:0] regaddr3;
    wire [`WORD_SIZE - 1:0] regdata1;
    wire [`WORD_SIZE - 1:0] regdata2;
    wire [`WORD_SIZE - 1:0] extimm;
    wire [`TARGET_SIZE - 1:0] target;

    // idex registers
    reg idex_nop;
    reg [`WORD_SIZE - 1:0] idex_pc;
    reg [`WORD_SIZE - 1:0] idex_pcplusone;
    reg [`WORD_SIZE - 1:0] idex_predpc;
    wire [`WORD_SIZE - 1:0] idex_nextpc;

    reg [1:0] idex_nextpc_mux;
    reg idex_regwrite;
    reg [1:0] idex_regdata3_mux;
    reg [`ALUOP_SIZE - 1:0] idex_aluop;
    reg idex_aluin2_mux;
    reg idex_memread;
    reg idex_memwrite;
    reg idex_branch;
    reg idex_wwd;
    reg idex_hlt;

    reg [`REG_ADDR - 1:0] idex_regaddr1;
    reg [`REG_ADDR - 1:0] idex_regaddr2;
    reg [`REG_ADDR - 1:0] idex_regaddr3;
    reg [`WORD_SIZE - 1:0] idex_regdata1;
    reg [`WORD_SIZE - 1:0] idex_regdata2;
    reg [`WORD_SIZE - 1:0] idex_extimm;
    reg [`TARGET_SIZE - 1:0] idex_target;

    wire [`WORD_SIZE - 1:0] aluin1;
    wire [`WORD_SIZE - 1:0] aluin2;
    wire [`WORD_SIZE - 1:0] aluout;
    wire bcond;

    // exmem registers
    reg exmem_nop;
    reg [`WORD_SIZE - 1:0] exmem_pc;
    reg [`WORD_SIZE - 1:0] exmem_pcplusone;
    reg [`WORD_SIZE - 1:0] exmem_predpc;
    reg [`WORD_SIZE - 1:0] exmem_nextpc;

    reg exmem_regwrite;
    reg [1:0] exmem_regdata3_mux;
    reg exmem_memread;
    reg exmem_memwrite;
    reg exmem_wwd;
    reg exmem_hlt;

    reg [`REG_ADDR - 1:0] exmem_regaddr3;
    reg [`WORD_SIZE - 1:0] exmem_regdata1;
    reg [`WORD_SIZE - 1:0] exmem_regdata2;
    reg [`WORD_SIZE - 1:0] exmem_aluout;

    // memwb registers
    reg memwb_nop;
    reg [`WORD_SIZE - 1:0] memwb_pcplusone;

    reg memwb_regwrite;
    reg [1:0] memwb_regdata3_mux;
    reg memwb_wwd;
    reg memwb_hlt;

    reg [`REG_ADDR - 1:0] memwb_regaddr3;
    reg [`WORD_SIZE - 1:0] memwb_regdata1;
    wire [`WORD_SIZE - 1:0] memwb_regdata3;
    reg [`WORD_SIZE - 1:0] memwb_aluout;
    reg [`WORD_SIZE - 1:0] memwb_mdr;

    // BTB wires
    wire [`WORD_SIZE - 1:0] predpc;

    // hazard wires
    wire pc_stall;
    wire ifid_stall;
    wire pc_flush;
    wire ifid_flush;
    wire idex_flush;
    wire exmem_flush;

    BTB btb_unit (.clk(clk),
                  .reset_n(reset_n),
                  .pc(pc),
                  .pcplusone(pcplusone),
                  .predpc(predpc),
                  .exmem_nop(exmem_nop),
                  .exmem_pc(exmem_pc),
                  .exmem_nextpc(exmem_nextpc));

    hazard hazard_unit (.regaddr1(regaddr1),
                        .regaddr2(regaddr2),
                        .idex_regaddr3(idex_regaddr3),
                        .exmem_regaddr3(exmem_regaddr3),
                        .memwb_regaddr3(memwb_regaddr3),
                        .use_regaddr1(use_regaddr1),
                        .use_regaddr2(use_regaddr2),
                        .idex_regwrite(idex_regwrite),
                        .exmem_regwrite(exmem_regwrite),
                        .memwb_regwrite(memwb_regwrite),
                        .exmem_predpc(exmem_predpc),
                        .exmem_nextpc(exmem_nextpc),
                        .hlt(exmem_hlt || memwb_hlt),
                        .pc_stall(pc_stall),
                        .ifid_stall(ifid_stall),
                        .pc_flush(pc_flush),
                        .ifid_flush(ifid_flush),
                        .idex_flush(idex_flush),
                        .exmem_flush(exmem_flush));

    // >>> pc >>>
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            pc <= `WORD_SIZE'd0;
        end
        else begin
            if (pc_flush) begin
                pc <= memwb_hlt ? pc : exmem_nextpc;
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
            ifid_nop <= 1'b1;
            ifid_pc <= `WORD_SIZE'b0;
            ifid_pcplusone <= `WORD_SIZE'b0;
            ifid_predpc <= `WORD_SIZE'b0;

            ifid_ir <= `INST_SIZE'b0;
        end
        else begin
            if (ifid_flush) begin
                ifid_nop <= 1'b1;
                ifid_pc <= `WORD_SIZE'b0;
                ifid_pcplusone <= `WORD_SIZE'b0;
                ifid_predpc <= `WORD_SIZE'b0;

                ifid_ir <= `INST_SIZE'b0;
            end
            else if (ifid_stall) begin
                ifid_nop <= ifid_nop;
                ifid_pc <= ifid_pc;
                ifid_pcplusone <= ifid_pcplusone;
                ifid_predpc <= ifid_predpc;

                ifid_ir <= ifid_ir;
            end
            else begin
                ifid_nop <= 1'b0;
                ifid_pc <= pc;
                ifid_pcplusone <= pcplusone;
                ifid_predpc <= predpc;

                ifid_ir <= i_data;
            end
        end
    end

    assign regaddr1 = ifid_ir[11:10];
    assign regaddr2 = ifid_ir[9:8];
    assign regaddr3 = (regaddr3_mux == 2'd0) ? ifid_ir[9:8] :
           (regaddr3_mux == 2'd1) ? ifid_ir[7:6] :
           (regaddr3_mux == 2'd2) ? `REG_ADDR'd2 : ifid_ir[9:8];

    RF rf_unit (.clk(clk),
                .reset_n(reset_n),
                .write(memwb_regwrite),
                .addr1(regaddr1),
                .addr2(regaddr2),
                .addr3(memwb_regaddr3),
                .data1(regdata1),
                .data2(regdata2),
                .data3(memwb_regdata3));

    immediate immediate_unit (.opcode(ifid_ir[15:12]),
                              .imm(ifid_ir[7:0]),
                              .extimm(extimm));

    assign target = ifid_ir[11:0];
    // <<< ifid <<<

    // >>> idex >>>
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            idex_nop <= 1'b1;
            idex_pc <= `WORD_SIZE'b0;
            idex_pcplusone <= `WORD_SIZE'b0;
            idex_predpc <= `WORD_SIZE'b0;

            idex_nextpc_mux <= 2'd0;
            idex_regwrite <= 1'b0;
            idex_regdata3_mux <= 2'd0;
            idex_aluop <= `ALUOP_ADD;
            idex_aluin2_mux <= 1'b0;
            idex_memread <= 1'b0;
            idex_memwrite <= 1'b0;
            idex_branch <= 1'b0;
            idex_wwd <= 1'b0;
            idex_hlt <= 1'b0;

            idex_regaddr1 <= `REG_ADDR'b0;
            idex_regaddr2 <= `REG_ADDR'b0;
            idex_regaddr3 <= `REG_ADDR'b0;
            idex_regdata1 <= `WORD_SIZE'b0;
            idex_regdata2 <= `WORD_SIZE'b0;
            idex_extimm <= `WORD_SIZE'b0;
            idex_target <= `TARGET_SIZE'b0;
        end
        else begin
            if (idex_flush) begin
                idex_nop <= 1'b1;
                idex_pc <= `WORD_SIZE'b0;
                idex_pcplusone <= `WORD_SIZE'b0;
                idex_predpc <= `WORD_SIZE'b0;

                idex_nextpc_mux <= 2'd0;
                idex_regwrite <= 1'b0;
                idex_regdata3_mux <= 2'd0;
                idex_aluop <= `ALUOP_ADD;
                idex_aluin2_mux <= 1'b0;
                idex_memread <= 1'b0;
                idex_memwrite <= 1'b0;
                idex_branch <= 1'b0;
                idex_wwd <= 1'b0;
                idex_hlt <= 1'b0;

                idex_regaddr1 <= `REG_ADDR'b0;
                idex_regaddr2 <= `REG_ADDR'b0;
                idex_regaddr3 <= `REG_ADDR'b0;
                idex_regdata1 <= `WORD_SIZE'b0;
                idex_regdata2 <= `WORD_SIZE'b0;
                idex_extimm <= `WORD_SIZE'b0;
                idex_target <= `TARGET_SIZE'b0;
            end
            else begin
                idex_nop <= ifid_nop;
                idex_pc <= ifid_pc;
                idex_pcplusone <= ifid_pcplusone;
                idex_predpc <= ifid_predpc;

                idex_nextpc_mux <= nextpc_mux;
                idex_regwrite <= regwrite;
                idex_regdata3_mux <= regdata3_mux;
                idex_aluop <= aluop;
                idex_aluin2_mux <= aluin2_mux;
                idex_memread <= memread;
                idex_memwrite <= memwrite;
                idex_branch <= branch;
                idex_wwd <= wwd;
                idex_hlt <= hlt;

                idex_regaddr1 <= regaddr1;
                idex_regaddr2 <= regaddr2;
                idex_regaddr3 <= regaddr3;
                idex_regdata1 <= regdata1;
                idex_regdata2 <= regdata2;
                idex_extimm <= extimm;
                idex_target <= target;
            end
        end
    end

    assign idex_nextpc = (idex_branch && bcond) ? idex_pcplusone + idex_extimm :
           (idex_nextpc_mux == 2'd0) ? idex_pcplusone :
           (idex_nextpc_mux == 2'd1) ? {idex_pc[15:12], idex_target} :
           (idex_nextpc_mux == 2'd2) ? idex_regdata1 : idex_pcplusone;

    assign aluin1 = idex_regdata1;
    assign aluin2 = idex_aluin2_mux ? idex_extimm : idex_regdata2;

    ALU alu_unit (.op(idex_aluop),
                  .in1(aluin1),
                  .in2(aluin2),
                  .out(aluout));

    assign bcond = aluout[0];
    // <<< idex <<<

    // >>> exmem >>>
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            exmem_nop <= 1'b1;
            exmem_pc <= `WORD_SIZE'b0;
            exmem_pcplusone <= `WORD_SIZE'b0;
            exmem_predpc <= `WORD_SIZE'b0;
            exmem_nextpc <= `WORD_SIZE'b0;

            exmem_regwrite <= 1'b0;
            exmem_regdata3_mux <= 2'd0;
            exmem_memread <= 1'b0;
            exmem_memwrite <= 1'b0;
            exmem_wwd <= 1'b0;
            exmem_hlt <= 1'b0;

            exmem_regaddr3 <= `REG_ADDR'b0;
            exmem_regdata1 <= `WORD_SIZE'b0;
            exmem_regdata2 <= `WORD_SIZE'b0;
            exmem_aluout <= `WORD_SIZE'b0;
        end
        else begin
            if (exmem_flush) begin
                exmem_nop <= 1'b1;
                exmem_pc <= `WORD_SIZE'b0;
                exmem_pcplusone <= `WORD_SIZE'b0;
                exmem_predpc <= `WORD_SIZE'b0;
                exmem_nextpc <= `WORD_SIZE'b0;

                exmem_regwrite <= 1'b0;
                exmem_regdata3_mux <= 2'd0;
                exmem_memread <= 1'b0;
                exmem_memwrite <= 1'b0;
                exmem_wwd <= 1'b0;
                exmem_hlt <= 1'b0;

                exmem_regaddr3 <= `REG_ADDR'b0;
                exmem_regdata1 <= `WORD_SIZE'b0;
                exmem_regdata2 <= `WORD_SIZE'b0;
                exmem_aluout <= `WORD_SIZE'b0;
            end
            else begin
                exmem_nop <= idex_nop;
                exmem_pc <= idex_pc;
                exmem_pcplusone <= idex_pcplusone;
                exmem_predpc <= idex_predpc;
                exmem_nextpc <= idex_nextpc;

                exmem_regwrite <= idex_regwrite;
                exmem_regdata3_mux <= idex_regdata3_mux;
                exmem_memread <= idex_memread;
                exmem_memwrite <= idex_memwrite;
                exmem_wwd <= idex_wwd;
                exmem_hlt <= idex_hlt;

                exmem_regaddr3 <= idex_regaddr3;
                exmem_regdata1 <= idex_regdata1;
                exmem_regdata2 <= idex_regdata2;
                exmem_aluout <= aluout;
            end
        end
    end
    // <<< exmem <<<

    // >>> memwb >>>
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            memwb_nop <= 1'b1;
            memwb_pcplusone <= `WORD_SIZE'b0;

            memwb_regwrite <= 1'b0;
            memwb_regdata3_mux <= 2'd0;
            memwb_wwd <= 1'b0;
            memwb_hlt <= 1'b0;

            memwb_regaddr3 <= `REG_ADDR'b0;
            memwb_regdata1 <= `WORD_SIZE'b0;
            memwb_aluout <= `WORD_SIZE'b0;
            memwb_mdr <= `WORD_SIZE'b0;
        end
        else begin
            if (memwb_hlt) begin
                memwb_nop <= 1'b1;
                memwb_pcplusone <= `WORD_SIZE'b0;

                memwb_regwrite <= 1'b0;
                memwb_regdata3_mux <= 2'd0;
                memwb_wwd <= 1'b0;
                memwb_hlt <= 1'b1;

                memwb_regaddr3 <= `REG_ADDR'b0;
                memwb_regdata1 <= `WORD_SIZE'b0;
                memwb_aluout <= `WORD_SIZE'b0;
                memwb_mdr <= `WORD_SIZE'b0;
            end
            else begin
                memwb_nop <= exmem_nop;
                memwb_pcplusone <= exmem_pcplusone;

                memwb_regwrite <= exmem_regwrite;
                memwb_regdata3_mux <= exmem_regdata3_mux;
                memwb_wwd <= exmem_wwd;
                memwb_hlt <= exmem_hlt;

                memwb_regaddr3 <= exmem_regaddr3;
                memwb_regdata1 <= exmem_regdata1;
                memwb_aluout <= exmem_aluout;
                memwb_mdr <= d_data;
            end
        end
    end

    assign memwb_regdata3 = (memwb_regdata3_mux == 2'd0) ? memwb_aluout :
           (memwb_regdata3_mux == 2'd1) ? memwb_mdr :
           (memwb_regdata3_mux == 2'd2) ? memwb_pcplusone : memwb_aluout;
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
