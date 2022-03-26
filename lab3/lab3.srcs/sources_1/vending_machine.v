`include "vending_machine_def.v"

module vending_machine(
        clk,     // Clock signal
        reset_n, // Reset signal (active-low)

        i_input_coin,     // coin is inserted.
        i_select_item,    // item is selected.
        i_trigger_return, // change-return is triggered

        o_available_item, // Sign of the item availability
        o_output_item,    // Sign of the item withdrawal
        o_return_coin,    // Sign of the coin return
        o_current_total);

    // Ports Declaration
    input clk;
    input reset_n;

    input [`kNumCoins - 1:0] i_input_coin;
    input [`kNumItems - 1:0] i_select_item;
    input i_trigger_return;

    output reg [`kNumItems - 1:0] o_available_item;
    output reg [`kNumItems - 1:0] o_output_item;
    output reg [`kReturnCoins - 1:0] o_return_coin;
    output reg [`kTotalBits - 1:0] o_current_total;

    // Net constant values (prefix kk & CamelCase)
    wire [31:0] kkItemPrice [`kNumItems - 1:0]; // Price of each item
    wire [31:0] kkCoinValue [`kNumCoins - 1:0]; // Value of each coin

    assign kkItemPrice[0] = 400;
    assign kkItemPrice[1] = 500;
    assign kkItemPrice[2] = 1000;
    assign kkItemPrice[3] = 2000;
    assign kkCoinValue[0] = 100;
    assign kkCoinValue[1] = 500;
    assign kkCoinValue[2] = 1000;

    // Internal states. You may add your own reg variables.
    reg [`kNumItems - 1:0] output_item;
    reg [`kTotalBits - 1:0] current_total;
    reg [`kCoinBits - 1:0] num_coins [`kNumCoins - 1:0]; // use if needed

    // Combinational circuit
    always @(*) begin
        output_item = i_select_item & o_available_item;
        if (i_input_coin != `kNumCoins'b0) begin
            case (i_input_coin)
                `kNumCoins'b1: current_total = o_current_total + kkCoinValue[0];
                `kNumCoins'b10: current_total = o_current_total + kkCoinValue[1];
                `kNumCoins'b100: current_total = o_current_total + kkCoinValue[2];
                default: current_total = o_current_total;
            endcase
        end
        else if (output_item != `kNumItems'b0) begin
            case (output_item)
                `kNumItems'b1: current_total = o_current_total - kkItemPrice[0];
                `kNumItems'b10: current_total = o_current_total - kkItemPrice[1];
                `kNumItems'b100: current_total = o_current_total - kkItemPrice[2];
                `kNumItems'b1000: current_total = o_current_total - kkItemPrice[3];
                default: current_total = o_current_total;
            endcase
        end
        else if (i_trigger_return) begin
            current_total = `kTotalBits'b0;
        end
        else begin
            current_total = o_current_total;
        end
    end

    // Sequential circuit
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // TODO: reset all states.
            o_available_item <= `kNumItems'b0;
            o_output_item <= `kNumItems'b0;
            o_current_total <= `kTotalBits'b0;
            o_return_coin <= `kReturnCoins'b0;
            num_coins[0] <= `kCoinBits'b0;
            num_coins[1] <= `kCoinBits'b0;
            num_coins[2] <= `kCoinBits'b0;
        end
        else begin
            // TODO: update all states.
            o_available_item <= (current_total >= kkItemPrice[3]) ? `kNumItems'b1111 :
                             (current_total >= kkItemPrice[2]) ? `kNumItems'b111 :
                             (current_total >= kkItemPrice[1]) ? `kNumItems'b11 :
                             (current_total >= kkItemPrice[0]) ? `kNumItems'b1 : `kNumItems'b0;
            o_output_item <= output_item;
            o_current_total <= current_total;
            if (i_trigger_return) begin
                o_return_coin <= num_coins[0] + num_coins[1] + num_coins[2];
                num_coins[0] <= `kCoinBits'b0;
                num_coins[1] <= `kCoinBits'b0;
                num_coins[2] <= `kCoinBits'b0;
            end
            else begin
                o_return_coin <= `kReturnCoins'b0;
                if (i_input_coin != `kNumCoins'b0) begin
                    case (i_input_coin)
                        `kNumCoins'b1:
                            if (num_coins[0] == `kCoinBits'd4 && num_coins[1] == `kCoinBits'd1) begin
                                num_coins[0] <= `kCoinBits'd0;
                                num_coins[1] <= `kCoinBits'd0;
                                num_coins[2] <= num_coins[2] + `kCoinBits'd1;
                            end
                            else if (num_coins[0] == `kCoinBits'd4) begin
                                num_coins[0] <= `kCoinBits'd0;
                                num_coins[1] <= num_coins[1] + `kCoinBits'd1;
                            end
                            else begin
                                num_coins[0] <= num_coins[0] + `kCoinBits'd1;
                            end
                        `kNumCoins'b10:
                            if (num_coins[1] == `kCoinBits'd1) begin
                                num_coins[1] <= `kCoinBits'd0;
                                num_coins[2] <= num_coins[2] + `kCoinBits'd1;
                            end
                            else begin
                                num_coins[1] <= num_coins[1] + `kCoinBits'd1;
                            end
                        `kNumCoins'b100:
                            num_coins[2] <= num_coins[2] + `kCoinBits'd1;
                    endcase
                end
                else if (output_item != `kNumItems'b0) begin
                    case (output_item)
                        `kNumItems'b1:
                            if (num_coins[0] < `kCoinBits'd4 && num_coins[1] == `kCoinBits'd0) begin
                                num_coins[0] <= num_coins[0] + `kCoinBits'd5 - `kCoinBits'd4;
                                num_coins[1] <= num_coins[1] + `kCoinBits'd2 - `kCoinBits'd1;
                                num_coins[2] <= num_coins[2] - `kCoinBits'd1;
                            end
                            else if (num_coins[0] < `kCoinBits'd4) begin
                                num_coins[0] <= num_coins[0] + `kCoinBits'd5 - `kCoinBits'd4;
                                num_coins[1] <= num_coins[1] - `kCoinBits'd1;
                            end
                            else begin
                                num_coins[0] <= num_coins[0] - `kCoinBits'd4;
                            end
                        `kNumItems'b10:
                            if (num_coins[1] < `kCoinBits'd1) begin
                                num_coins[1] <= num_coins[1] + `kCoinBits'd2 - `kCoinBits'd1;
                                num_coins[2] <= num_coins[2] - `kCoinBits'd1;
                            end
                            else begin
                                num_coins[1] <= num_coins[1] - `kCoinBits'd1;
                            end
                        `kNumItems'b100:
                            num_coins[2] <= num_coins[2] - `kCoinBits'd1;
                        `kNumItems'b1000:
                            num_coins[2] <= num_coins[2] - `kCoinBits'd2;
                    endcase
                end
            end
        end
    end
endmodule
