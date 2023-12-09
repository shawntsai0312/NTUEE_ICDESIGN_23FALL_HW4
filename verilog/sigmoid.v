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
	/*------------------------------------------ Stage 0 ------------------------------------------*/
		// input handling
		wire sign;
		wire [7:0] abs_x;
		wire [50:0] stage0Number;

		handleInput(abs_x, sign, i_x, stage0Number);
		// wire [7:0] testInput;
		// assign testInput = 8'b1000_0000;
		// handleInput(abs_x, sign, testInput, handleInputNumber);

	/*--------------------------------------- Stage 0 --> 1 ---------------------------------------*/
		wire d01_sign, d01_valid;
		wire [7:0] d01_abs_x;
		wire [50:0] d01_signFFNumber, d01_validFFNumber, d01_xFFNumber;
		wire [50:0] stage01FFNumber;

		FD2 d01_signFF(d01_sign, sign, clk, rst_n, d01_signFFNumber);
		FD2 d01_validFF(d01_valid, i_in_valid, clk, rst_n, d01_validFFNumber);
		REGP #(8) d01_xFF(d01_abs_x, abs_x, clk, rst_n, d01_xFFNumber);

		assign stage01FFNumber = d01_signFFNumber + d01_validFFNumber + d01_xFFNumber;

	/*------------------------------------------ Stage 1 ------------------------------------------*/
		// getting a, b
		wire CTRL0, CTRL1, CTRL2;
		wire nCTRL0, nCTRL1, nCTRL2;
		wire [3:0] aValue;
		wire [9:0] bValue;
		wire [50:0] ctrlNumber, aSelectNumber, bSelectNumber, ivCTRLNumber;

		Mux2Bus #(3) ({CTRL0, CTRL1, CTRL2}, d01_abs_x[6:4], 3'b111, d01_abs_x[7], ctrlNumber);
		IvBus #(3) ({nCTRL0, nCTRL1, nCTRL2}, {CTRL0, CTRL1, CTRL2}, ivCTRLNumber);
		// a4bitsSelector( aValue[3:0], CTRL0, CTRL1, CTRL2, aSelectNumber);
		a4bitsSelectorEnhanced(aValue[3:0], CTRL0, nCTRL0, CTRL1, nCTRL1, CTRL2, nCTRL2, aSelectNumber);
		// b10bitsSelector(bValue[9:0], CTRL0, CTRL1, CTRL2, bSelectNumber);
		b10bitsSelectorEnhanced(bValue[9:0], CTRL0, nCTRL0, CTRL1, nCTRL1, CTRL2, nCTRL2, bSelectNumber);

		wire [50:0] stage1Number;
		assign stage1Number = ctrlNumber + aSelectNumber + bSelectNumber + ivCTRLNumber;

	/*--------------------------------------- Stage 1 --> 2 ---------------------------------------*/
		wire d12_sign, d12_valid;
		wire [7:0] d12_abs_x;
		wire [3:0] d12_aValue;
		wire [9:0] d12_bValue;
		wire [50:0] d12_signFFNumber, d12_validFFNumber, d12_xFFNumber, d12_aFFNumber, d12_bFFNumber;
		wire [50:0] stage12FFNumber;

		FD2 d12_signFF(d12_sign, d01_sign, clk, rst_n, d12_signFFNumber);
		FD2 d12_validFF(d12_valid, d01_valid, clk, rst_n, d12_validFFNumber);
		REGP #(8) d12_xFF(d12_abs_x, d01_abs_x, clk, rst_n, d12_xFFNumber);
		REGP #(4) d12_aFF(d12_aValue, aValue, clk, rst_n, d12_aFFNumber);
		REGP #(10) d12_bFF(d12_bValue, bValue, clk, rst_n, d12_bFFNumber);

		assign stage12FFNumber = d12_signFFNumber + d12_validFFNumber + d12_xFFNumber + d12_aFFNumber + d12_bFFNumber;

	/*------------------------------------------ Stage 2 ------------------------------------------*/
		// multiplication 1
		wire [7:0] abs_x0, abs_x1, abs_x2, abs_x3;
		wire [50:0] andNumber0, andNumber1, andNumber2, andNumber3;
		wire [50:0] andNumber;

		And2Bus #(8) (abs_x0, d12_abs_x, d12_aValue[0], andNumber0);
		And2Bus #(8) (abs_x1, d12_abs_x, d12_aValue[1], andNumber1);
		And2Bus #(8) (abs_x2, d12_abs_x, d12_aValue[2], andNumber2);
		And2Bus #(8) (abs_x3, d12_abs_x, d12_aValue[3], andNumber3);
		assign andNumber = andNumber0 + andNumber1 + andNumber2 + andNumber3;

		wire [9:0] add01, add23;
		wire [50:0] ck8Number01, ck8Number23;
		wire [50:0] ck8Number;

		assign add01[0] = abs_x0[0];
		assign add23[0] = abs_x2[0];
		carrySkip8NoCin(add01[8:1], add01[9], {1'b0, abs_x0[7:1]}, abs_x1[7:0], ck8Number01);
		carrySkip8NoCin(add23[8:1], add23[9], {1'b0, abs_x2[7:1]}, abs_x3[7:0], ck8Number23);
		assign ck8Number = ck8Number01 + ck8Number23;
		
		wire [50:0] stage2Number;
		assign stage2Number = andNumber + ck8Number;

	/*--------------------------------------- Stage 2 --> 3 ---------------------------------------*/
		wire d23_sign, d23_valid;
		wire [9:0] d23_add01, d23_add23;
		wire [9:0] d23_bValue;
		wire [50:0] d23_signFFNumber, d23_validFFNumber, d23_bFFNumber, d23_add01FFNumber, d23_add23FFNumber;
		wire [50:0] stage23FFNumber;

		FD2 d23_signFF(d23_sign, d12_sign, clk, rst_n, d23_signFFNumber);
		FD2 d32_validFF(d23_valid, d12_valid, clk, rst_n, d23_validFFNumber);
		REGP #(10) d23_bFF(d23_bValue, d12_bValue, clk, rst_n, d23_bFFNumber);
		REGP #(10) d23_add01FF(d23_add01, add01, clk, rst_n, d23_add01FFNumber);
		REGP #(10) d23_add23FF(d23_add23, add23, clk, rst_n, d23_add23FFNumber);
		
		assign stage23FFNumber = d23_signFFNumber + d23_validFFNumber + d23_bFFNumber + d23_add01FFNumber + d23_add23FFNumber;

	/*------------------------------------------ Stage 3 ------------------------------------------*/
		// multiplication 2
		wire [11:0] mul;
		wire carry;
		wire [50:0] ck8Number0123, twoBitsaddOneBitNumber;
		assign mul[1:0] = d23_add01[1:0];
		carrySkip8NoCin(mul[9:2], carry, d23_add01[9:2], d23_add23[7:0], ck8Number0123);
		twoBitsaddOneBit(mul[11:10], d23_add23[9:8], carry, twoBitsaddOneBitNumber);

		wire [50:0] stage3Number;
		assign stage3Number = ck8Number0123 + twoBitsaddOneBitNumber;

	/*--------------------------------------- Stage 3 --> 4 ---------------------------------------*/
		wire d34_sign, d34_valid;
		wire [ 9:0] d34_bValue;
		wire [11:0] d34_mul;
		wire [50:0] d34_signFFNumber, d34_validFFNumber, d34_bFFNumber, d34_mulFFNumber;
		wire [50:0] stage34FFNumber;

		FD2 d34_signFF(d34_sign, d23_sign, clk, rst_n, d34_signFFNumber);
		FD2 d34_validFF(d34_valid, d23_valid, clk, rst_n, d34_validFFNumber);
		REGP #(10) d34_bFF(d34_bValue, d23_bValue, clk, rst_n, d34_bFFNumber);
		REGP #(12) d34_mulFF(d34_mul, mul, clk, rst_n, d34_mulFFNumber);
		
		assign stage34FFNumber = d34_signFFNumber + d34_validFFNumber + d34_bFFNumber + d34_mulFFNumber;

	/*------------------------------------------ Stage 4 ------------------------------------------*/
		// addition
		wire [11:0] funcOut;
		wire [50:0] stage4Number;
		carrySkip12NoC(funcOut, d34_mul, {1'b0, 1'b1,d34_bValue}, stage4Number);

	/*--------------------------------------- Stage 4 --> 5 ---------------------------------------*/
		wire d45_sign, d45_valid;
		wire [11:0] d45_funcOut;
		wire [50:0] d45_signFFNumber, d45_validFFNumber, d45_funcOutFFNumber;
		wire [50:0] stage45FFNumber;

		FD2 d45_signFF(d45_sign, d34_sign, clk, rst_n, d45_signFFNumber);
		FD2 d45_validFF(d45_valid, d34_valid, clk, rst_n, d45_validFFNumber);
		REGP #(12) d45_mulFF(d45_funcOut, funcOut, clk, rst_n, d45_funcOutFFNumber);
		
		assign stage45FFNumber = d45_signFFNumber + d45_validFFNumber + d45_funcOutFFNumber;

	/*------------------------------------------ Stage 5 ------------------------------------------*/
		// output handling
		wire [11:0] outTemp;
		wire [50:0] xor2BusNumber, mux2BusNumber;
		Xor2Bus #(11) (outTemp[11:1], d45_funcOut[10:0], d45_sign, xor2BusNumber);
		// Mux2Bus #(4) (outTemp[3:0], 4'b0011, 4'b1011, d45_sign, mux2BusNumber);
		assign outTemp[0] = d45_sign;

		wire [50:0] stage5Number;
		assign stage5Number = xor2BusNumber;

	/*------------------------------------- Stage 5 --> Output -------------------------------------*/
		wire [50:0] outputValidFFNumber, outputFFNumber;
		wire [50:0] stage5OutFFNumber;

		FD2 outputValidFF(o_out_valid, d45_valid, clk, rst_n, outputValidFFNumber);
		REGP #(12) outputFF(o_y[14:3], outTemp[11:0], clk, rst_n, outputFFNumber);
		assign o_y[2:0] = 3'b011;
		assign o_y[15] = 1'b0;

		assign stage5OutFFNumber = outputValidFFNumber + outputFFNumber;

		assign number = stage0Number + stage01FFNumber
					  + stage1Number + stage12FFNumber
					  + stage2Number + stage23FFNumber
					  + stage3Number + stage34FFNumber
					  + stage4Number + stage45FFNumber
					  + stage5Number + stage5OutFFNumber;
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

module carrySkip4NoBCin1(
		output [3:0] S,
		output Cout,
		input [3:0] A,
		output [50:0] number
	);
	/*------------------------------------------- Gk0 -------------------------------------------*/
		wire G10, G20, G30, tempCout;
		wire [50:0] G20number, G30number, G40number;
		wire [50:0] Gknumber;

		// G10
		assign G10 = A[0];

		// G20
		AN2(G20, G10, A[1], G20number);

		// G30
		AN2(G30, G20, A[2], G30number);

		// tempCout
		AN2(tempCout, G30, A[3], G40number);

		assign Gknumber = G20number + G30number + G40number;

	/*------------------------------------------ S[3:0] ------------------------------------------*/
		wire [50:0] S0number, S1number, S2number, S3number;
		wire [50:0] Snumber;

		// S[3:0]
		IV(S[0], 	  A[0], S0number);
		EO(S[1], G10, A[1], S1number);
		EO(S[2], G20, A[2], S2number);
		EO(S[3], G30, A[3], S3number);
		
		assign Snumber = S0number + S1number + S2number + S3number;

	/*------------------------------------------ Cout ------------------------------------------*/
		wire aAnd;
		wire [50:0] aAndNumber, orNumber;

		AN4(aAnd, A[0], A[1], A[2], A[3], aAndNumber);
		OR2(Cout, tempCout, aAnd, orNumber);

	assign number = Gknumber + Snumber + aAndNumber + orNumber;
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

	// carrySkip4NoB(out[3:0], carryBetween, in[3:0],         1'b1, number1);
	carrySkip4NoBCin1(out[3:0], carryBetween, in[3:0],               number1);
	carrySkip4NoB(    out[7:4],     carryOut, in[7:4], carryBetween, number2);

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

module a4bitsSelectorEnhanced(
		output [3:0] out,
		input CTRL0,
		input nCTRL0,
		input CTRL1,
		input nCTRL1,
		input CTRL2,
		input nCTRL2,
		output [50:0] number
	);
	// 2^(-3) to 2^(-6)

	// out[3] = CTRL0'
	assign out[3] = nCTRL0;

	// out[2] = CTRL1'
	assign out[2] = nCTRL1;

	// out[1] =  CTRL0'CTRL1'+ CTRL2'
	//        = [(CTRL0+CTRL1)CTRL2]'
	wire or01;
	wire [50:0] or01Number, out1Number;
	OR2(  or01, CTRL0, CTRL1, or01Number);
	ND2(out[1],  or01, CTRL2, out1Number);

	// out[0] =  CTRL0'CTRL2'+ CTRL0CTRL1CTRL2
	//        = [(CTRL0+CTRL2)(CTRL0CTRL1CTRL2)']'
	wire or02, nand012;
	wire [50:0] or02Number, nand012Number, out0Number;
	OR2(    or02, CTRL0, CTRL2, or02Number);
	ND3( nand012, CTRL0, CTRL1, CTRL2, nand012Number);
	ND2(  out[0],  or02, nand012, out0Number);

	assign number = or01Number + out1Number + or02Number + nand012Number + out0Number;
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

module b10bitsSelectorEnhanced(
		output [9:0] out,
		input CTRL0,
		input nCTRL0,
		input CTRL1,
		input nCTRL1,
		input CTRL2,
		input nCTRL2,
		output [50:0] number
	);
	// 2^(-2) to 2^(-11)

	// out[9] = CTRL0(CTRL1 + CTRL2)
	//		  = CTRL0(CTRL1'CTRL2')'
		wire nandn1n2;
		wire [50:0] nandn1n2Number, out9Number;
		wire [50:0] number9;
		ND2(nandn1n2, nCTRL1, nCTRL2, nandn1n2Number);
		AN2(out[9],  CTRL0, nandn1n2, out9Number);
		assign number9 = nandn1n2Number + out9Number;

	// out[8] =  CTRL1CTRL2 + CTRL0CTRL1'CTRL2'
	//        = [(CTRL1CTRL2)'( CTRL0CTRL1'CTRL2')']'
		wire nand12, nand0n1n2;
		wire [50:0] nand12Number, nand0n1n2Number, out8Number;
		wire [50:0] number8;
		ND2(nand12, CTRL1, CTRL2, nand12Number);
		ND3(nand0n1n2, CTRL0, nCTRL1, nCTRL2, nand0n1n2Number);
		ND2(out[8], nand12, nand0n1n2, out8Number);
		assign number8 = nand12Number + nand0n1n2Number + out8Number;

	// out[7] = CTRL0CTRL2'
		wire [50:0] number7;
		AN2(out[7], CTRL0, nCTRL2, number7);

	// out[6] = CTRL1(CTRL0 + CTRL2')
	//        = CTRL1(CTRL0'CTRL2)'
		wire nandn02;
		wire [50:0] nandn02Number, out6Number;
		wire [50:0] number6;
		ND2(nandn02, nCTRL0, CTRL2, nandn02Number);
		AN2(out[6],  CTRL1, nandn02, out6Number);
		assign number6 = nandn02Number + out6Number;

	// out[5] =  CTRL1CTRL2' + CTRL0CTRL1'CTRL2
	//        = [(CTRL1CTRL2')'( CTRL0CTRL1'CTRL2)']'
		wire nand1n2, nand0n12;
		wire [50:0] nand1n2Number, nand0n12Number, out5Number;
		wire [50:0] number5;
		ND2(nand1n2, CTRL1, nCTRL2, nand1n2Number);
		ND3(nand0n12, CTRL0, nCTRL1, CTRL2, nand0n12Number);
		ND2(out[5], nand1n2, nand0n12, out5Number);
		assign number5 = nand1n2Number + nand0n12Number + out5Number;

	// out[4] =   CTRL0'CTRL1'CTRL2 + CTRL0'CTRL1CTRL2' + CTRL0CTRL1CTRL2
	//        = [(CTRL0'CTRL1'CTRL2)'(CTRL0'CTRL1CTRL2')'(CTRL0CTRL1CTRL2)']'
		wire nandn0n12, nandn01n2, nand012;
		wire [50:0] nandn0n12Number, nandn01n2Number, nand012, out4Number;
		wire [50:0] number4;
		ND3(nandn0n12, nCTRL0, nCTRL1,  CTRL2, nandn0n12Number);
		ND3(nandn01n2, nCTRL0,  CTRL1, nCTRL2, nandn01n2Number);
		ND3(  nand012,  CTRL0,  CTRL1,  CTRL2,   nand012Number);
		ND3(out[4], nandn0n12, nandn01n2, nand012, out4Number);
		assign number4 = nandn0n12Number + nandn01n2Number + nand012Number + out4Number;
	
	// out[3] =  CTRL0'CTRL1 + CTRL0'CTRL2 + CTRL1CTRL2 + CTRL0CTRL1'CTRL2'
	//        = [(CTRL0'CTRL1)'(CTRL0'CTRL2)'(CTRL1CTRL2)'(CTRL0CTRL1'CTRL2')']'
		wire nandn01;
		wire [50:0] nandn01Number, out3Number;
		wire [50:0] number3;
		ND2(nandn01, nCTRL0, CTRL1, nandn01Number);
		ND4(out[3], nandn01, nandn02, nand12, nand0n1n2, out3Number);
		assign number3 = nandn01Number + out3Number;

	// out[2] = CTRL1'CTRL2 + CTRL1CTRL0'
	// 		  = MUX, CTRL = CTRL1, 0 -> CTRL2, 1 -> CTRL0'
		wire number2;
		MUX21H(out[2], CTRL2, nCTRL0, CTRL1, number2);

	// out[1] =  CTRL2' + CTRL0'CTRL1
	//        = [CTRL2(CTRL0'CTRL1)']'
		wire [50:0] number1;
		ND2(out[1], CTRL2, nandn01, number1);

	// out[0] = CTRL1'CTRL2' + CTRL0'CTRL2
	//		  = MUX, CTRL = CTRL2, 0 -> CTRL1', 1 -> CTRL0'
		wire number0;
		MUX21H(out[0], nCTRL1, nCTRL0, CTRL2, number0);

	assign number = number0 + number1 + number2 + number3 + number4
				  + number5 + number6 + number7 + number8 + number9;

endmodule

module carrySkip8NoCin(
		output [7:0] S,
		output Cout,
		input [7:0] A,
		input [7:0] B,
		output [50:0] number
	);
	wire carryBetween;
	wire [50:0] number1, number2;
	carrySkip4NoCin( S[3:0], carryBetween, A[3:0], B[3:0],               number1);
	carrySkip4(      S[7:4],         Cout, A[7:4], B[7:4], carryBetween, number2);
	assign number = number1 + number2;
endmodule

module twoBitsaddOneBit(
		output [1:0] S,
		input [1:0] A,
		input B,
		output [50:0] number
	);
	wire [50:0] xorNumber, nand1Number, nand2Number;
	wire temp;
	EO(S[0], A[0], B, xorNumber);
	ND2(temp, A[0], B, nand1Number);
	ND2(S[1], A[1], temp, nand2Number);
	assign number = xorNumber + nand1Number + nand2Number;
endmodule