module sigmoid (
		input         clk,
		input         rst_n,
		input         i_in_valid,
		input  [ 7:0] i_x,
		output [15:0] o_y,
		output        o_out_valid,
		output [50:0] number
	);

	// Your design
	assign o_y = 16'h0000;
	assign o_out_valid = 1'b1;

endmodule

//BW-bit FD2
module REGP#(
		parameter BW = 2
	)(
		input           clk,
		input           rst_n,
		output [BW-1:0] Q,
		input  [BW-1:0] D,
		output [  50:0] number
	);

	wire [50:0] numbers [0:BW-1];

	genvar i;
	generate
		for (i=0; i<BW; i=i+1) begin
			FD2 f0(Q[i], D[i], clk, rst_n, numbers[i]);
		end
	endgenerate

	//sum number of transistors
	reg [50:0] sum;
	integer j;
	always @(*) begin
		sum = 0;
		for (j=0; j<BW; j=j+1) begin 
			sum = sum + numbers[j];
		end
	end
	assign number = sum;
endmodule

module IvBus#(
		parameter BW = 2
	)(
		input [BW-1:0] in,
		output [BW-1:0] out
	)

	wire [50:0] numbers [0:BW-1];

	genvar i;
	generate
		for (i=0; i<BW; i=i+1) begin
			IV iv0(out[i], in[i], numbers[i]);
		end
	endgenerate

	//sum number of transistors
	reg [50:0] sum;
	integer j;
	always @(*) begin
		sum = 0;
		for (j=0; j<BW; j=j+1) begin 
			sum = sum + numbers[j];
		end
	end
	assign number = sum;
endmodule