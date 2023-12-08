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

	/*------------------------------------------ Stage 1 ------------------------------------------*/
		// input handling
		// getting a, b
		wire sign;
		wire [7:0] abs_x;
		wire [50:0] handleInputNumber;

		handleInput(abs_x, sign, i_x, handleInputNumber);

		// wire [7:0] testInput;
		// assign testInput = 8'b11010001;
		// handleInput(abs_x, testInput, handleInputNumber);

		wire CTRL0, CTRL1, CTRL2;
		wire [3:0] aValue;
		wire [11:0] bValue;
		wire [50:0] ctrlNumber, aSelectNumber, bSelectNumber;

		Mux2Bus #(3) ({CTRL0, CTRL1, CTRL2}, abs_x[6:4], 3'b111, abs_x[7], ctrlNumber);
		a4bitsSelector( aValue[3:0], CTRL0, CTRL1, CTRL2, aSelectNumber);
		b10bitsSelector(bValue[9:0], CTRL0, CTRL1, CTRL2, bSelectNumber);
		assign bValue[11:10] = 2'b01;

		wire [50:0] stage1Number;
		assign stage1Number = handleInputNumber + ctrlNumber + aSelectNumber +bSelectNumber;

	/*--------------------------------------- Stage 1 --> 2 ---------------------------------------*/
		wire d_sign, d_valid;
		wire [7:0] d_abs_x;
		wire [3:0] d_aValue;
		wire [11:0] d_bValue;
		wire [50:0] signFFNumber, validFFNumber, xFFNumber, aFFNumber, bFFNumber;
		wire [50:0] stage12FFNumber;

		FD2 signFF(d_sign, sign, clk, rst_n, signFFNumber);
		FD2 validFF(d_valid, i_in_valid, clk, rst_n, validFFNumber);
		REGP #(8) xFF(d_abs_x, abs_x, clk, rst_n, xFFNumber);
		REGP #(4) aFF(d_aValue, aValue, clk, rst_n, aFFNumber);
		REGP #(12) bFF(d_bValue, bValue, clk, rst_n, bFFNumber);

		assign stage12FFNumber = signFFNumber + validFFNumber + xFFNumber + aFFNumber + bFFNumber;

	/*------------------------------------------ Stage 2 ------------------------------------------*/
		// multiplication
		wire [11:0] mul;
		wire [50:0] stage2Number;

		mul8by4(mul[11:0], d_abs_x[7:0], d_aValue[3:0], stage2Number);

	/*--------------------------------------- Stage 2 --> 3 ---------------------------------------*/
		wire d_d_sign, d_d_valid;
		wire [11:0] d_d_bValue, d_mul;
		wire [50:0] d_signFFNumber, d_validFFNumber, d_bFFNumber, mulFFNumber;
		wire [50:0] stage23FFNumber;

		FD2 d_signFF(d_d_sign, d_sign, clk, rst_n, d_signFFNumber);
		FD2 d_validFF(d_d_valid, d_valid, clk, rst_n, d_validFFNumber);
		REGP #(12) d_bFF(d_d_bValue, d_bValue, clk, rst_n, d_bFFNumber);
		REGP #(12) mulFF(d_mul, mul, clk, rst_n, mulFFNumber);
		
		assign stage23FFNumber = d_signFFNumber + d_validFFNumber + d_bFFNumber + mulFFNumber;

	/*------------------------------------------ Stage 3 ------------------------------------------*/
		// addition
		// output handling
		wire [11:0] funcOut;
		wire [50:0] addNumber;
		carrySkip12NoC(funcOut, d_mul, d_d_bValue, addNumber);

		wire [14:0] outTemp;
		wire [50:0] xor2BusNumber, mux2BusNumber;
		Xor2Bus #(11) (outTemp[14:4], funcOut[10:0], d_d_sign, xor2BusNumber);
		Mux2Bus #(4) (outTemp[3:0], 4'b0011, 4'b1011, d_d_sign, mux2BusNumber);

		wire [50:0] stage3Number;
		assign stage3Number = addNumber + xor2BusNumber + mux2BusNumber;

	/*------------------------------------- Stage 3 --> Output -------------------------------------*/
		wire [50:0] outputValidFFNumber, outputFFNumber;
		wire [50:0] stage3OutFFNumber;

		FD2 outputValidFF(o_out_valid, d_d_valid, clk, rst_n, outputValidFFNumber);
		REGP #(15) outputFF(o_y[14:0], outTemp[14:0], clk, rst_n, outputFFNumber);
		assign o_y[15] = 1'b0;

		assign stage3OutFFNumber = outputValidFFNumber + outputFFNumber;

		assign number = stage1Number + stage12FFNumber + stage2Number + stage23FFNumber + stage3Number + stage3OutFFNumber;
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
		wire [50:0] number100, number101, number110, number111;
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
		output [BW-1:0] Q,
		input  [BW-1:0] D,
		input           clk,
		input           rst_n,
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

module And2Bus#(
		parameter BW = 2
	)(
		output [BW-1:0] out,
		input  [BW-1:0] in1,
		input  in2,
		output [  50:0] number
	);

	wire [50:0] numbers [0:BW-1];

	genvar i;
	generate
		for (i=0; i<BW; i=i+1) begin
			AN2 an2(out[i], in1[i], in2, numbers[i]);
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

module Xor2Bus#(
		parameter BW = 2
	)(
		output [BW-1:0] out,
		input  [BW-1:0] in1,
		input  in2,
		output [  50:0] number
	);

	wire [50:0] numbers [0:BW-1];

	genvar i;
	generate
		for (i=0; i<BW; i=i+1) begin
			EO xor2(out[i], in1[i], in2, numbers[i]);
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
		output [7:0] out,
		output sign,
		input [7:0] in,
		output [50:0] number
	);
	// out[8] = in[7]
	assign sign = in[7];

	// if negative, out[7:0] = in[7:0]' + 1
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

module carrySkip4NoCin(
		output [3:0] S,
		output Cout,
		input [3:0] A,
		input [3:0] B,
		output [50:0] number
	);
	/*------------------------------------------ P, nG ------------------------------------------*/
		wire [3:0] P, nG;
		wire [50:0]  P0number,  P1number,  P2number,  P3number;
		wire [50:0] nG0number, nG1number, nG2number, nG3number;
		wire [50:0] Pnumber, nGnumber;

		// P0, nG0
		EO(  P[0], A[0], B[0],  P0number);
		AN2(nG[0], A[0], B[0], nG0number);

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
		wire [50:0] G20number, G30number, G40number;
		wire [50:0] T20number, T30number, T40number;
		wire [50:0] Gknumber, Tknumber;

		// G10
		assign G10 = nG[0];

		// G20
		ND2(T20, G10,  P[1], T20number);
		ND2(G20, T20, nG[1], G20number);

		// G30
		ND2(T30, G20,  P[2], T30number);
		ND2(G30, T30, nG[2], G30number);

		// tempCout
		ND2(     T40, G30,  P[3], T40number);
		ND2(tempCout, T40, nG[3], G40number);

		assign Tknumber = T20number + T30number + T40number;
		assign Gknumber = G20number + G30number + G40number;

	/*------------------------------------------ S[3:0] ------------------------------------------*/
		wire [50:0] S1number, S2number, S3number;
		wire [50:0] Snumber;

		// S[3:0]
		assign S[0] = P[0];
		EO(S[1], G10, P[1], S1number);
		EO(S[2], G20, P[2], S2number);
		EO(S[3], G30, P[3], S3number);
		
		assign Snumber = S1number + S2number + S3number;

	/*------------------------------------------ Cout ------------------------------------------*/
		wire pAnd;
		wire [50:0] pAndNumber, muxNumber;

		AN4(pAnd, P[0], P[1], P[2], P[3], pAndNumber);
		MUX21H(Cout, tempCout, 1'b0, pAnd, muxNumber);

	assign number = Pnumber + nGnumber + Tknumber + Gknumber + Snumber + pAndNumber + muxNumber;
endmodule

module carrySkip4NoCout(
		output [3:0] S,
		input [3:0] A,
		input [3:0] B,
		input Cin,
		output [50:0] number
	);
	/*------------------------------------------ P, nG ------------------------------------------*/
		wire [3:0] P, nG;
		wire [50:0]  P0number,  P1number,  P2number,  P3number;
		wire [50:0] nG0number, nG1number, nG2number;
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

		// P3
		EO(  P[3], A[3], B[3],  P3number);

		assign  Pnumber =  P0number +  P1number +  P2number +  P3number;
		assign nGnumber = nG0number + nG1number + nG2number;

	/*----------------------------------------- Gk0, Tk0 -----------------------------------------*/
		wire G10, G20, G30;
		wire T10, T20, T30;
		wire [50:0] G10number, G20number, G30number;
		wire [50:0] T10number, T20number, T30number;
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

		assign Tknumber = T10number + T20number + T30number;
		assign Gknumber = G10number + G20number + G30number;

	/*------------------------------------------ S[3:0] ------------------------------------------*/
		wire [50:0] S0number, S1number, S2number, S3number;
		wire [50:0] Snumber;

		// S[3:0]
		EO(S[0], Cin, P[0], S0number);
		EO(S[1], G10, P[1], S1number);
		EO(S[2], G20, P[2], S2number);
		EO(S[3], G30, P[3], S3number);
		
		assign Snumber = S0number + S1number + S2number + S3number;

	assign number = Pnumber + nGnumber + Tknumber + Gknumber + Snumber;
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

module carrySkip12(
		output [11:0] S,
		output Cout,
		input [11:0] A,
		input [11:0] B,
		input Cin,
		output [50:0] number
	);
	wire carryBetween1, carryBetween2;
	wire [50:0] number1, number2, number3;
	carrySkip4(S[ 3:0], carryBetween1, A[ 3:0], B[ 3:0], 		   Cin, number1);
	carrySkip4(S[ 7:4], carryBetween2, A[ 7:4], B[ 7:4], carryBetween1, number2);
	carrySkip4(S[11:8],          Cout, A[11:8], B[11:8], carryBetween2, number3);
	assign number = number1 + number2 + number3;
endmodule

module carrySkip12NoC(
		output [11:0] S,
		input [11:0] A,
		input [11:0] B,
		output [50:0] number
	);
	wire carryBetween1, carryBetween2;
	wire [50:0] number1, number2, number3;
	carrySkip4NoCin( S[ 3:0], carryBetween1, A[ 3:0], B[ 3:0],                number1);
	carrySkip4(      S[ 7:4], carryBetween2, A[ 7:4], B[ 7:4], carryBetween1, number2);
	carrySkip4NoCout(S[11:8],                A[11:8], B[11:8], carryBetween2, number3);
	assign number = number1 + number2 + number3;
endmodule

module a4bitsSelector(
		output [3:0] out,
		input CTRL0,
		input CTRL1,
		input CTRL2,
		output [50:0] number
	);
	// 2^(-3) to 2^(-6)
	Mux8Bus #(4) (out,
				4'b1111,
				4'b1110,
				4'b1011,
				4'b1000,
				4'b0110,
				4'b0100,
				4'b0010,
				4'b0001,
				CTRL0,
				CTRL1,
				CTRL2,
				number);
endmodule

module b10bitsSelector(
		output [9:0] out,
		input CTRL0,
		input CTRL1,
		input CTRL2,
		output [50:0] number
	);
	// 2^(-2) to 2^(-11)
	Mux8Bus #(10) (out,
				10'b00_0000_0011,
				10'b00_0001_1101,
				10'b00_0111_1110,
				10'b01_0000_1111,
				10'b01_1000_1011,
				10'b10_0010_0100,
				10'b10_1110_0010,
				10'b11_0101_1000,
				CTRL0,
				CTRL1,
				CTRL2,
				number);
endmodule

module mul8by4(
		output [11:0] out,
		input  [7:0] in8,
		input  [3:0] in4,
		output [50:0] number
	);
	wire [11:0] temp0, temp1, temp2, temp3;
	wire [50:0] temp0Number, temp1Number, temp2Number, temp3Number;
	wire [50:0] tempNumber;

	And2Bus #(8) (temp0[7:0], in8[7:0], in4[0], temp0Number);
	assign temp0[11:8] = 4'b0000;

	And2Bus #(8) (temp1[8:1], in8[7:0], in4[1], temp1Number);
	assign temp1[11:9] = 3'b000;
	assign temp1[0] = 1'b0;

	And2Bus #(8) (temp2[9:2], in8[7:0], in4[2], temp2Number);
	assign temp2[11:10] = 2'b00;
	assign temp2[1:0] = 2'b00;

	And2Bus #(8) (temp3[10:3], in8[7:0], in4[3], temp3Number);
	assign temp3[11] = 1'b0;
	assign temp3[2:0] = 3'b000;

	assign tempNumber = temp0Number + temp1Number + temp2Number + temp3Number;

	wire [11:0] add1, add2;
	wire [50:0] adderNumber1, adderNumber2, adderNumber3;
	wire [50:0] adderNumber;

	carrySkip12NoC(add1[11:0], temp0[11:0], temp1[11:0], adderNumber1);
	carrySkip12NoC(add2[11:0], temp2[11:0], temp3[11:0], adderNumber2);
	carrySkip12NoC( out[11:0],  add1[11:0],  add2[11:0], adderNumber3);

	assign adderNumber = adderNumber1 + adderNumber2 + adderNumber3;
	assign number = tempNumber + adderNumber;
endmodule