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
	wire [8:0] abs_x;
	wire [50:0] handleInputNumber;
	handleInput(abs_x, 8'b1000_0000, handleInputNumber);

	wire CTRL0, CTRL1, CTRL2;
	wire [7:0] aValue;
	wire [15:0] bValue;
	wire [50:0] ctrlNumber, aSelectNumber, bSelectNumber;
	Mux2Bus #(3) ({CTRL0, CTRL1, CTRL2}, abs_x[6:4], 3'b111, abs_x[8], ctrlNumber);
	a8bitsSelector(aValue, CTRL0, CTRL1, CTRL2, aSelectNumber);
	b16bitsSelector(bValue, CTRL0, CTRL1, CTRL2, bSelectNumber);

endmodule

module ND8(
		output Z,
		input A,
		input B,
		input C,
		input D,
		input E,
		input F,
		input G,
		input H,
		output [50:0] number
	);
	// nand8
	// F = [(abc)(def)(gh)]'		, delay =  and3 + nand3 = 0.275 + 0.226 = 0.501  <-- choose this
	//   = [(abcd)(efgh)]'			, delay =  and4 + nand2 = 0.371 + 0.176 = 0.547
	//   = [(ab)(cd)(ef)(gh)]'		, delay =  and2 + nand4 = 0.225 + 0.296 = 0.521

	wire and2, and31, and32;
	wire [50:0] number1, number2, number3, number4;

	AN3(and31,A,B,C,number1);
	AN3(and32,D,E,F,number2);
	AN2(and2,G,H,number3);
	ND3(Z,and31,and32,and2,number4);

	assign number = number1 + number2 + number3 + number4;
endmodule

module MUX81H(
		output out,
		input in000,
		input in001,
		input in010,
		input in011,
		input in100,
		input in101,
		input in110,
		input in111,
		input CTRL0,
		input CTRL1,
		input CTRL2,
		output [50:0] number
	);
	/*-------------------------------------------- IV --------------------------------------------*/
		wire nCTRL0, nCTRL1, nCTRL2;
		wire [50:0] ivNumber0, ivNumber1, ivNumber2;
		wire [50:0] ivNumber;

		IV(nCTRL0, CTRL0, ivNumber0);
		IV(nCTRL1, CTRL1, ivNumber1);
		IV(nCTRL2, CTRL2, ivNumber2);

		assign ivNumber = ivNumber0 + ivNumber1 + ivNumber2;

	/*------------------------------------------ 8 cases ------------------------------------------*/
		wire case000, case001, case010, case011;
		wire case100, case101, case110, case111;
		wire [50:0] number000, number001, number010, number011;
		wire [50:0] number000, number001, number010, number011;
		wire [50:0] nd4Number;

		ND4(case000, in000, nCTRL0, nCTRL1, nCTRL2, number000);
		ND4(case001, in001, nCTRL0, nCTRL1,  CTRL2, number001);
		ND4(case010, in010, nCTRL0,  CTRL1, nCTRL2, number010);
		ND4(case011, in011, nCTRL0,  CTRL1,  CTRL2, number011);
		ND4(case100, in100,  CTRL0, nCTRL1, nCTRL2, number100);
		ND4(case101, in101,  CTRL0, nCTRL1,  CTRL2, number101);
		ND4(case110, in110,  CTRL0,  CTRL1, nCTRL2, number110);
		ND4(case111, in111,  CTRL0,  CTRL1,  CTRL2, number111);

		assign nd4Number = number000 + number001 + number010 + number011 + number100 + number101 + number110 + number111;

	/*------------------------------------------ nand 8 ------------------------------------------*/
		wire [50:0] nd8Number;

		ND8(out, case000, case001, case010, case011, case100, case101, case110, case111, nd8Number);

		assign number = ivNumber + nd4Number + nd8Number;
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
		output [BW-1:0] out,
		input  [BW-1:0] in,
		output [  50:0] number
	);

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

module Mux2Bus#(
		parameter BW = 2
	)(
		output [BW-1:0] out,
		input  [BW-1:0] in0,
		input  [BW-1:0] in1,
		input  CTRL,
		output [  50:0] number
	);

	wire [50:0] numbers [0:BW-1];

	genvar i;
	generate
		for (i=0; i<BW; i=i+1) begin
			 MUX21H(out[i], in0[i], in1[i], CTRL, numbers[i]);
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

module Mux8Bus#(
		parameter BW = 2
	)(
		output [BW-1:0] out,
		input  [BW-1:0] in000,
		input  [BW-1:0] in001,
		input  [BW-1:0] in010,
		input  [BW-1:0] in011,
		input  [BW-1:0] in100,
		input  [BW-1:0] in101,
		input  [BW-1:0] in110,
		input  [BW-1:0] in111,
		input  CTRL0,
		input  CTRL1,
		input  CTRL2,
		output [  50:0] number
	);

	wire [50:0] numbers [0:BW-1];

	genvar i;
	generate
		for (i=0; i<BW; i=i+1) begin
			 MUX81H(out[i], in000[i], in001[i], in010[i], in011[i], in100[i], in101[i], in110[i], in111[i], CTRL0, CTRL1, CTRL2, numbers[i]);
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

module handleInput(
		output [8:0] out,
		input [7:0] in,
		output [50:0] number
	);
	// out[8] = in[7]
	assign out[8] = in[7];

	// out[7:0] = in[7:0]' + 1
	wire [7:0] nIn;
	wire [50:0] IvBusNumber;
	IvBus #(8) (nIn[7:0], in[7:0], IvBusNumber);

	wire [7:0] tempOut;
	wire [50:0] addOneNumber;
	addOne(tempOut[7:0], nIn[7:0], addOneNumber);

	wire [50:0] muxNumber;
	Mux2Bus #(8) (out[7:0], in[7:0], tempOut[7:0], in[7], muxNumber);

	assign number = IvBusNumber + addOneNumber + muxNumber;
endmodule

module carrySkip4(
		output [3:0] S,
		output Cout,
		input [3:0] A,
		input [3:0] B,
		input Cin,
		output [50:0] number
	);
	/*------------------------------------------ P, nG ------------------------------------------*/
		wire [3:0] P, nG;
		wire [50:0]  P0number,  P1number,  P2number,  P3number;
		wire [50:0] nG0number, nG1number, nG2number, nG3number;
		wire [50:0] Pnumber, nGnumber;

		// P0, nG0
		EO(  P[0], A[0], B[0],  P0number);
		ND2(nG[0], A[0], B[0], nG0number);

		// P1, nG1
		EO(  P[1], A[1], B[1],  P1number);
		ND2(nG[1], A[1], B[1], nG1number);

		// P2, nG2
		EO(  P[2], A[2], B[2],  P2number);
		ND2(nG[2], A[2], B[2], nG2number);

		// P3, nG3
		EO(  P[3], A[3], B[3],  P3number);
		ND2(nG[3], A[3], B[3], nG3number);

		assign  Pnumber =  P0number +  P1number +  P2number +  P3number;
		assign nGnumber = nG0number + nG1number + nG2number + nG3number;

	/*----------------------------------------- Gk0, Tk0 -----------------------------------------*/
		wire G10, G20, G30, tempCout;
		wire T10, T20, T30, T40;
		wire [50:0] G10number, G20number, G30number, G40number;
		wire [50:0] T10number, T20number, T30number, T40number;
		wire [50:0] Gknumber, Tknumber;

		// G10
		ND2(T10, Cin,  P[0], T10number);
		ND2(G10, T10, nG[0], G10number);

		// G20
		ND2(T20, G10,  P[1], T20number);
		ND2(G20, T20, nG[1], G20number);

		// G30
		ND2(T30, G20,  P[2], T30number);
		ND2(G30, T30, nG[2], G30number);

		// tempCout
		ND2(     T40, G30,  P[3], T40number);
		ND2(tempCout, T40, nG[3], G40number);

		assign Tknumber = T10number + T20number + T30number + T40number;
		assign Gknumber = G10number + G20number + G30number + G40number;

	/*------------------------------------------ S[3:0] ------------------------------------------*/
		wire [50:0] S0number, S1number, S2number, S3number;
		wire [50:0] Snumber;

		// S[3:0]
		EO(S[0], Cin, P[0], S0number);
		EO(S[1], G10, P[1], S1number);
		EO(S[2], G20, P[2], S2number);
		EO(S[3], G30, P[3], S3number);
		
		assign Snumber = S0number + S1number + S2number + S3number;

	/*------------------------------------------ Cout ------------------------------------------*/
		wire pAnd;
		wire [50:0] pAndNumber, muxNumber;

		AN4(pAnd, P[0], P[1], P[2], P[3], pAndNumber);
		MUX21H(Cout, tempCout, Cin, pAnd, muxNumber);

	assign number = Pnumber + nGnumber + Tknumber + Gknumber + Snumber + pAndNumber + muxNumber;
endmodule

module carrySkip4NoB(
		output [3:0] S,
		output Cout,
		input [3:0] A,
		input Cin,
		output [50:0] number
	);
	/*------------------------------------------- Gk0 -------------------------------------------*/
		wire G10, G20, G30, tempCout;
		wire [50:0] G10number, G20number, G30number, G40number;
		wire [50:0] Gknumber;

		// G10
		AN2(G10, Cin, A[0], G10number);

		// G20
		AN2(G20, G10, A[1], G20number);

		// G30
		AN2(G30, G20, A[2], G30number);

		// tempCout
		AN2(tempCout, G30, A[3], G40number);

		assign Gknumber = G10number + G20number + G30number + G40number;

	/*------------------------------------------ S[3:0] ------------------------------------------*/
		wire [50:0] S0number, S1number, S2number, S3number;
		wire [50:0] Snumber;

		// S[3:0]
		EO(S[0], Cin, A[0], S0number);
		EO(S[1], G10, A[1], S1number);
		EO(S[2], G20, A[2], S2number);
		EO(S[3], G30, A[3], S3number);
		
		assign Snumber = S0number + S1number + S2number + S3number;

	/*------------------------------------------ Cout ------------------------------------------*/
		wire aAnd;
		wire [50:0] aAndNumber, muxNumber;

		AN4(aAnd, A[0], A[1], A[2], A[3], aAndNumber);
		MUX21H(Cout, tempCout, Cin, aAnd, muxNumber);

	assign number = Gknumber + Snumber + aAndNumber + muxNumber;
endmodule

module addOne(
		output [7:0] out,
		input [7:0] in,
		output [50:0] number
	);
	wire carryBetween, carryOut;
	wire [50:0] number1, number2;

	carrySkip4NoB(out[3:0], carryBetween, in[3:0],         1'b1, number1);
	carrySkip4NoB(out[7:4],     carryOut, in[7:4], carryBetween, number2);

	assign number = number1 + number2;
endmodule

module a6bitsSelector(
		output [7:0] out,
		input CTRL0,
		input CTRL1,
		input CTRL2,
		output [50:0] number
	);
	// 2^(-3) to 2^(-10)
	// shift 0 bit after multiplication
	Mux8Bus #(6) (out,
				6'b1111_11,
				6'b1110_00,
				6'b1011_00,
				6'b1000_00,
				6'b0101_10,
				6'b0011_11,
				6'b0010_01,
				6'b0001_10,
				CTRL0,
				CTRL1,
				CTRL2,
				number);
endmodule

module a8bitsSelector(
		output [7:0] out,
		input CTRL0,
		input CTRL1,
		input CTRL2,
		output [50:0] number
	);
	// 2^(-3) to 2^(-10)
	// shift 0 bit after multiplication
	Mux8Bus #(8) (out,
				8'b1111_1010,
				8'b1101_1110,
				8'b1011_0001,
				8'b1000_0001,
				8'b0101_1000,
				8'b0011_1010,
				8'b0010_0101,
				8'b0001_0111,
				CTRL0,
				CTRL1,
				CTRL2,
				number);
endmodule

module b16bitsSelector(
		output [15:0] out,
		input CTRL0,
		input CTRL1,
		input CTRL2,
		output [50:0] number
	);
	// 2^0 to 2^(-15)
	Mux8Bus #(16) (out,
				16'b0100_0000_0000_0000,
				16'b0100_0001_1100_0110,
				16'b0100_0111_0110_1101,
				16'b0101_0000_0101_1111,
				16'b0101_1010_1000_1101,
				16'b0110_0100_0001_1000,
				16'b0110_1100_0000_0101,
				16'b0111_0010_0001_1010,
				CTRL0,
				CTRL1,
				CTRL2,
				number);
endmodule