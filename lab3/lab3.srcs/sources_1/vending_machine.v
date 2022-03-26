// Title         : vending_machine.v
// Author      : Hunjun Lee (hunjunlee7515@snu.ac.kr), Suheon Bae (suheon.bae@snu.ac.kr)

`include "vending_machine_def.v"

module vending_machine (

	clk,							// Clock signal
	reset_n,						// Reset signal (active-low)

	i_input_coin,				// coin is inserted.
	i_select_item,				// item is selected.
	i_trigger_return,			// change-return is triggered

	o_available_item,			// Sign of the item availability
	o_output_item,			   // Sign of the item withdrawal
	o_return_coin,			   // Sign of the coin return
	o_current_total
);

	// Ports Declaration
	input clk;
	input reset_n;

	input [`kNumCoins-1:0] i_input_coin;
	input [`kNumItems-1:0] i_select_item;
	input i_trigger_return;

	output [`kNumItems-1:0] o_available_item;
	output [`kNumItems-1:0] o_output_item;
	output [`kReturnCoins-1:0] o_return_coin;
	output [`kTotalBits-1:0] o_current_total;

	// Net constant values (prefix kk & CamelCase)
	wire [31:0] kkItemPrice [`kNumItems-1:0];	// Price of each item
	wire [31:0] kkCoinValue [`kNumCoins-1:0];	// Value of each coin
	assign kkItemPrice[0] = 400;
	assign kkItemPrice[1] = 500;
	assign kkItemPrice[2] = 1000;
	assign kkItemPrice[3] = 2000;
	assign kkCoinValue[0] = 100;
	assign kkCoinValue[1] = 500;
	assign kkCoinValue[2] = 1000;

	// Internal states. You may add your own reg variables.
	reg [`kTotalBits-1:0] current_total;
	reg [`kItemBits-1:0] num_items [`kNumItems-1:0]; //use if needed
	reg [`kCoinBits-1:0] num_coins [`kNumCoins-1:0]; //use if needed


	// Combinational circuit for the next states
	always @(*) begin


	end
	// Combinational circuit for the output
	always @(*) begin


	end


	// Sequential circuit to reset or update the states
	always @(posedge clk) begin
		if (!reset_n) begin
			// TODO: reset all states.

		end
		else begin
			// TODO: update all states.

		end
	end

endmodule
