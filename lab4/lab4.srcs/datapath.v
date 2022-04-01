module datapath (
        clk,
        reset_n,
        inputReady,
        readM,
        address,
        data,
        num_inst,
        output_port,
        opcode,
        func,
        pcmux,
        aluop,
        aluin1mux,
        aluin2mux,
        regwrite,
        regaddr3mux,
        regdata3mux,
        wwd
    );

    input clk;     // clock
    input reset_n; // active-low reset

    input inputReady;                  // if memory read is done
    output reg readM;                  // enable memory read
    output [`WORD_SIZE - 1:0] address; // memory data address
    inout [`WORD_SIZE - 1:0] data;     // memory inout data

    output reg [`WORD_SIZE - 1:0] num_inst;    // number of instructions executed
    output reg [`WORD_SIZE - 1:0] output_port; // WWD output port

    output [`OPCODE_SIZE - 1:0] opcode; // opcode of current instruction
    output [`FUNC_SIZE - 1:0] func;     // func of current R-format instruction

    input [1:0] pcmux;               // PC mux [0 = pc + 1|1 = aluout|2 = {PC[15:12], IR[11:0]}|3 = regdata1]
    input [`ALUOP_SIZE - 1:0] aluop; // ALU operation code
    input [1:0] aluin1mux;           // ALU input 1 [0 = regdata1|1 = extimm|2 = PC|3 = 0]
    input [1:0] aluin2mux;           // ALU input 2 [0 = regdata2|1 = extimm|2 = regdata1|3 = 0]
    input regwrite;                  // enable register write
    input [1:0] regaddr3mux;         // write register mux [0 = IR[9:8]|1 = IR[7:6]|2 = 2]
    input [1:0] regdata3mux;         // write data mux [0 = aluout|1 = memdata1|2 = PC|3 = input_port]
    input wwd;                       // if current instruction is WWD

    // >>> PC >>>
    reg [`WORD_SIZE - 1:0] PC;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            PC <= -`WORD_SIZE'd1;
        end
        else begin
            PC <= (pcmux == 2'd0) ? PC + `WORD_SIZE'd1 :
               (pcmux == 2'd1) ? aluout :
               (pcmux == 2'd2) ? {PC[15:12], IR[11:0]} : regdata1;
        end
    end
    // <<< PC <<<

    // >>> IR >>>
    reg [`WORD_SIZE - 1:0] IR;

    always @(posedge clk or negedge reset_n or posedge inputReady) begin
        if (!reset_n) begin
            IR <= {`OPCODE_NOP, `OPERAND_SIZE'b0};
            readM <= 1'b0;
            num_inst <= -`WORD_SIZE'd1;
        end
        else if (inputReady) begin
            IR <= data;
            readM <= 1'b0;
            num_inst <= num_inst + `WORD_SIZE'd1;
        end
        else begin
            IR <= {`OPCODE_NOP, `OPERAND_SIZE'b0};
            readM <= 1'b1;
        end
    end
    // <<< IR <<<

    // >>> RF >>>
    wire [`REG_ADDR - 1:0] regaddr1;
    wire [`REG_ADDR - 1:0] regaddr2;
    wire [`REG_ADDR - 1:0] regaddr3;
    wire [`WORD_SIZE - 1:0] regdata1;
    wire [`WORD_SIZE - 1:0] regdata2;
    wire [`WORD_SIZE - 1:0] regdata3;

    assign regaddr1 = IR[11:10];
    assign regaddr2 = IR[9:8];
    assign regaddr3 = (regaddr3mux == 2'd0) ? IR[9:8] :
           (regaddr3mux == 2'd1) ? IR[7:6] :
           (regaddr3mux == 2'd2) ? `REG_ADDR'd2 : IR[9:8];
    assign regdata3 = (regdata3mux == 2'd0) ? aluout :
           (regdata3mux == 2'd1) ? aluout :
           (regdata3mux == 2'd2) ? PC : aluout;

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
    wire [`WORD_SIZE - 1:0] extimm;

    immediate immediate_unit (.opcode(IR[15:12]),
                              .imm(IR[7:0]),
                              .extimm(extimm));
    // <<< immediate <<<

    // >>> ALU >>>
    wire [`WORD_SIZE - 1:0] aluin1;
    wire [`WORD_SIZE - 1:0] aluin2;
    wire [`WORD_SIZE - 1:0] aluout;

    assign aluin1 = (aluin1mux == 2'd0) ? regdata1 :
           (aluin1mux == 2'd1) ? extimm :
           (aluin1mux == 2'd2) ? PC : `WORD_SIZE'b0;
    assign aluin2 = (aluin2mux == 2'd0) ? regdata2 :
           (aluin2mux == 2'd1) ? extimm :
           (aluin2mux == 2'd2) ? regdata1 : `WORD_SIZE'b0;

    ALU alu (.OP(aluop),
             .A(aluin1),
             .B(aluin2),
             .Cin(1'b0),
             .C(aluout),
             .Cout());
    // <<< ALU <<<

    // >>> output >>>
    assign address = PC;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            output_port <= `WORD_SIZE'b0;
        end
        else begin
            output_port <= wwd ? regdata1 : `WORD_SIZE'b0;
        end
    end

    assign opcode = IR[15:12];
    assign func = IR[5:0];
    // <<< output <<<
endmodule
