`timescale 1ns / 100ps

`include "constants.v"

module cpu_tb;
    reg clk;     // clock
    reg reset_n; // active-low reset

    wire readM;                      // enable memory read
    reg inputReady;                  // if memory read is done
    wire [`WORD_SIZE - 1:0] address; // memory inout data address
    wire [`WORD_SIZE - 1:0] data;    // memory inout data

    wire [`WORD_SIZE - 1:0] num_inst;    // number of instructions executed
    wire [`WORD_SIZE - 1:0] output_port; // WWD output port

    reg [`WORD_SIZE - 1:0] outputData; // memory read data

    // instantiate the unit under test
    cpu UUT (.clk(clk),
             .reset_n(reset_n),
             .readM(readM),
             .inputReady(inputReady),
             .address(address),
             .data(data),
             .num_inst(num_inst),
             .output_port(output_port));

    // initialize inputs
    initial begin
        clk = 0;
        inputReady = 0;
        reset_n = 1;
        #(`PERIOD1 / 4) reset_n = 0;
        #`PERIOD1 reset_n = 1;
    end

    // generate the clock
    always #(`PERIOD1 / 2) clk = ~clk;

    // model the memory device
    reg [`WORD_SIZE - 1:0] memory [0:`MEMORY_SIZE - 1];

    // model the read process for the memory device
    assign data = readM ? outputData : `WORD_SIZE'bz;
    always begin
        outputData = `WORD_SIZE'bz;
        #`PERIOD1;
        forever begin
            wait(readM == 1);
            #`READ_DELAY;
            outputData = memory[address];
            inputReady = 1;
            #(`STABLE_TIME);
            outputData = `WORD_SIZE'bz;
            inputReady = 0;
        end // of forever loop
    end // of always block for memory read

    // store programs and data in the memory
    initial begin
        #`PERIOD1; // delay for a while
        memory[0] = 16'h6000;  // LHI $0, 0
        memory[1] = 16'h6101;  // LHI $1, 1
        memory[2] = 16'h6202;  // LHI $2, 2
        memory[3] = 16'h6303;  // LHI $3, 3
        memory[4] = 16'hf01c;  // WWD $0
        memory[5] = 16'hf41c;  // WWD $1
        memory[6] = 16'hf81c;  // WWD $2
        memory[7] = 16'hfc1c;  // WWD $3
        memory[8] = 16'h4204;  // ADI $2, $0, 4
        memory[9] = 16'h47fc;  // ADI $3, $1, -4
        memory[10] = 16'hf81c; // WWD $2
        memory[11] = 16'hfc1c; // WWD $3
        memory[12] = 16'hf6c0; // ADD $3, $1, $2
        memory[13] = 16'hf180; // ADD $2, $0, $1
        memory[14] = 16'hf81c; // WWD $2
        memory[15] = 16'hfc1c; // WWD $3
        memory[16] = 16'h9015; // JMP 21
        memory[17] = 16'hf01c; // WWD $0
        memory[18] = 16'hf180; // ADD $2, $0, $1
        memory[19] = 16'hf180; // ADD $2, $0, $1
        memory[20] = 16'hf180; // ADD $2, $0, $1
        memory[21] = 16'h6000; // LHI $0, 0
        memory[22] = 16'h4000; // ADI $0, $0, 0
        memory[23] = 16'hfd80; // ADD $2, $3, $1
        memory[24] = 16'hf01c; // WWD $0
        memory[25] = 16'hf41c; // WWD $1
        memory[26] = 16'hf81c; // WWD $2
        memory[27] = 16'hfc1c; // WWD $3
        #(`PERIOD1 * 30);
        $finish();
    end

    // always process to check the results of the tests
    always @(posedge clk) begin
        $display("num_inst %d", num_inst);
        case (num_inst)
            16'd5: // for testing WWD $0
                if (output_port == 16'd0)
                    $display("PASS");
                else
                    $display("FAIL[%d/%d]", output_port, 16'd0);
            16'd6: // for testing WWD $1
                if (output_port == 16'd256)
                    $display("PASS");
                else
                    $display("FAIL[%d/%d]", output_port, 16'd256);
            16'd7: // for testing WWD $2
                if (output_port == 16'd512)
                    $display("PASS");
                else
                    $display("FAIL[%d/%d]", output_port, 16'd512);
            16'd8: // for testing WWD $3
                if (output_port == 16'd768)
                    $display("PASS");
                else
                    $display("FAIL[%d/%d]", output_port, 16'd768);
            16'd11: // for testing WWD $2
                if (output_port == 16'd4)
                    $display("PASS");
                else
                    $display("FAIL[%d/%d]", output_port, 16'd4);
            16'd12: // for testing WWD $3
                if (output_port == 16'd252)
                    $display("PASS");
                else
                    $display("FAIL[%d/%d]", output_port, 16'd252);
            16'd15: // for testing WWD $2
                if (output_port == 16'd256)
                    $display("PASS");
                else
                    $display("FAIL[%d/%d]", output_port, 16'd256);
            16'd16: // for testing WWD $3
                if (output_port == 16'd260)
                    $display("PASS");
                else
                    $display("FAIL[%d/%d]", output_port, 16'd260);
            16'd21: // for testing WWD $0
                if (output_port == 16'd0)
                    $display("PASS");
                else
                    $display("FAIL[%d/%d]", output_port, 16'd0);
            16'd22: // for testing WWD $1
                if (output_port == 16'd256)
                    $display("PASS");
                else
                    $display("FAIL[%d/%d]", output_port, 16'd256);
            16'd23: // for testing WWD $2
                if (output_port == 16'd516)
                    $display("PASS");
                else
                    $display("FAIL[%d/%d]", output_port, 16'd516);
            16'd24: // for testing WWD $3
                if (output_port == 16'd260)
                    $display("PASS");
                else
                    $display("FAIL[%d/%d]", output_port, 16'd260);
        endcase
    end
endmodule
