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
		wire [7:0] nIn;
		wire [50:0] nivBusNumber;
		IvBus #(8) (nIn[7:0], i_x[7:0], nivBusNumber);

		wire [7:0] nx;
		wire [50:0] addOneNumber;
		addOne(nx[7:0], nIn[7:0], addOneNumber);

		wire [50:0] stage0Number;
		assign stage0Number = nivBusNumber + addOneNumber;

	/*--------------------------------------- Stage 0 --> 1 ---------------------------------------*/
		wire d01_valid;
		wire [7:0] d01_x, d01_nx;
		wire [50:0] d01_validFFNumber, d01_xFFNumber, d01_nxFFNumber;
		wire [50:0] stage01FFNumber;

		FD2 d01_validFF(d01_valid, i_in_valid, clk, rst_n, d01_validFFNumber);
		REGP #(8) d01_xFF(d01_x, i_x, clk, rst_n,  d01_xFFNumber);
		REGP #(8) d01_nxFF(d01_nx, nx, clk, rst_n, d01_nxFFNumber);

		assign stage01FFNumber = d01_validFFNumber + d01_xFFNumber + d01_nxFFNumber;

	/*------------------------------------------ Stage 1 ------------------------------------------*/
		// getting sign, abs_x, special and a
		wire sign;
		assign sign = d01_x[7];

		wire [7:0] abs_x;
		wire [50:0] absMuxNumber;
		Mux2Bus #(8) (abs_x[7:0], d01_x[7:0], d01_nx[7:0], sign, absMuxNumber);

		wire special;
		wire [50:0] andSpecialNumber;
		AN2(special, sign, abs_x[7], andSpecialNumber);

		wire CTRL0, CTRL1, CTRL2;
		wire nCTRL0, nCTRL1, nCTRL2;
		wire [50:0] ivCTRLNumber;
		
		assign {CTRL0, CTRL1, CTRL2} = abs_x[6:4];
		IvBus #(3) ({nCTRL0, nCTRL1, nCTRL2}, {CTRL0, CTRL1, CTRL2}, ivCTRLNumber);

		wire [3:0] aValue;
		wire [50:0] aSelectNumber;
		a4bitsSelectorEnhanced(aValue[3:0], CTRL0, nCTRL0, CTRL1, nCTRL1, CTRL2, nCTRL2, aSelectNumber);

		wire [50:0] stage1Number;
		assign stage1Number = absMuxNumber + andSpecialNumber + ivCTRLNumber + aSelectNumber;

	/*--------------------------------------- Stage 1 --> 2 ---------------------------------------*/
		wire d12_sign, d12_valid, d12_special;
		wire d12_CTRL0, d12_CTRL1, d12_CTRL2;
		wire [3:0] d12_abs_x;
		wire [3:0] d12_aValue;
		wire [50:0] d12_signFFNumber, d12_validFFNumber, d12_specialFFNumber, d12_ctrlFFNumber, d12_xFFNumber, d12_aFFNumber;
		wire [50:0] stage12FFNumber;

		FD2 d12_signFF(d12_sign, sign, clk, rst_n, d12_signFFNumber);
		FD2 d12_validFF(d12_valid, d01_valid, clk, rst_n, d12_validFFNumber);
		FD2 d12_specialFF(d12_special, special, clk, rst_n, d12_specialFFNumber);
		REGP #(3) d12_ctrlFF({d12_CTRL0, d12_CTRL1, d12_CTRL2}, {CTRL0, CTRL1, CTRL2}, clk, rst_n, d12_ctrlFFNumber);
		REGP #(4) d12_xFF(d12_abs_x[3:0], abs_x[3:0], clk, rst_n, d12_xFFNumber);
		REGP #(4) d12_aFF(d12_aValue, aValue, clk, rst_n, d12_aFFNumber);

		assign stage12FFNumber = d12_signFFNumber + d12_validFFNumber + d12_specialFFNumber + d12_ctrlFFNumber + d12_xFFNumber + d12_aFFNumber;

	/*------------------------------------------ Stage 2 ------------------------------------------*/
		// multiplication 1
		wire [50:0] stage2Number;
		wire [5:0] add01, add23;
		mulStage1(add01[5:0], add23[5:0], d12_aValue[3:0], d12_abs_x[3:0], stage2Number);

	/*--------------------------------------- Stage 2 --> 3 ---------------------------------------*/
		wire d23_sign, d23_valid, d23_special;
		wire d23_CTRL0, d23_CTRL1, d23_CTRL2;
		wire [5:0] d23_add01, d23_add23;
		wire [50:0] d23_signFFNumber, d23_validFFNumber, d23_specialFFNumber, d23_ctrlFFNumber, d23_add01FFNumber, d23_add23FFNumber;
		wire [50:0] stage23FFNumber;

		FD2 d23_signFF(d23_sign, d12_sign, clk, rst_n, d23_signFFNumber);
		FD2 d23_validFF(d23_valid, d12_valid, clk, rst_n, d23_validFFNumber);
		FD2 d23_specialFF(d23_special, d12_special, clk, rst_n, d23_specialFFNumber);
		REGP #(3) d23_ctrlFF({d23_CTRL0, d23_CTRL1, d23_CTRL2}, {d12_CTRL0, d12_CTRL1, d12_CTRL2}, clk, rst_n, d23_ctrlFFNumber);
		REGP #(6) d23_add01FF(d23_add01, add01, clk, rst_n, d23_add01FFNumber);
		REGP #(6) d23_add23FF(d23_add23, add23, clk, rst_n, d23_add23FFNumber);
		
		assign stage23FFNumber = d23_signFFNumber + d23_validFFNumber + d23_specialFFNumber + d23_ctrlFFNumber + d23_add01FFNumber + d23_add23FFNumber;

	/*------------------------------------------ Stage 3 ------------------------------------------*/
		// multiplication 2
		wire [7:0] mul;
		wire [50:0] mulNumber;
		mulStage2(mul, d23_add01, d23_add23, mulNumber);

		// get b
		wire [9:0] bValue;
		wire [50:0] bSelectNumber, d23_ivNumber;
		wire d23_nCTRL0, d23_nCTRL1, d23_nCTRL2;
		IvBus #(3) ({d23_nCTRL0, d23_nCTRL1, d23_nCTRL2}, {d23_CTRL0, d23_CTRL1, d23_CTRL2}, d23_ivNumber);
		b10bitsSelectorEnhanced(bValue[9:0], d23_CTRL0, d23_nCTRL0, d23_CTRL1, d23_nCTRL1, d23_CTRL2, d23_nCTRL2, bSelectNumber);

		wire [50:0] stage3Number;
		assign stage3Number = mulNumber + d23_ivNumber + bSelectNumber;

	/*--------------------------------------- Stage 3 --> 4 ---------------------------------------*/
		wire d34_sign, d34_valid, d34_special;
		wire [7:0] d34_mul;
		wire [9:0] d34_bValue;
		wire [50:0] d34_signFFNumber, d34_validFFNumber, d34_specialFFNumber, d34_mulFFNumber, d34_bValueNumber;
		wire [50:0] stage34FFNumber;

		FD2 d34_signFF(d34_sign, d23_sign, clk, rst_n, d34_signFFNumber);
		FD2 d34_validFF(d34_valid, d23_valid, clk, rst_n, d34_validFFNumber);
		FD2 d34_specialFF(d34_special, d23_special, clk, rst_n, d34_specialFFNumber);
		REGP #(8) d34_mulFF(d34_mul, mul, clk, rst_n, d34_mulFFNumber);
		REGP #(10) d34_bFF(d34_bValue, bValue, clk, rst_n, d34_bValueFFNumber);
		
		assign stage34FFNumber = d34_signFFNumber + d34_validFFNumber + d34_specialFFNumber + d34_mulFFNumber + d34_bValueFFNumber;

	/*------------------------------------------ Stage 4 ------------------------------------------*/
		// add b
		wire [9:0] funcOut;
		wire [50:0] stage4Number;
		addStage(funcOut, d34_mul, d34_bValue, stage4Number);

	/*--------------------------------------- Stage 4 --> 5 ---------------------------------------*/
		wire d45_sign, d45_valid, d45_special;
		wire [9:0] d45_funcOut;
		wire [50:0] d45_signFFNumber, d45_validFFNumber, d45_specialFFNumber, d45_funcOutFFNumber;
		wire [50:0] stage45FFNumber;

		FD2 d45_signFF(d45_sign, d34_sign, clk, rst_n, d45_signFFNumber);
		FD2 d45_validFF(d45_valid, d34_valid, clk, rst_n, d45_validFFNumber);
		FD2 d45_specialFF(d45_special, d34_special, clk, rst_n, d45_specialFFNumber);
		REGP #(10) d45_mulFF(d45_funcOut, funcOut, clk, rst_n, d45_funcOutFFNumber);
		
		assign stage45FFNumber = d45_signFFNumber + d45_validFFNumber + d45_specialFFNumber + d45_funcOutFFNumber;

	/*------------------------------------------ Stage 5 ------------------------------------------*/
		// output handling
		wire [15:0] outTemp1;
		wire [50:0] xor2BusNumber;
		assign outTemp1[ 0] = 1'b1;
		assign outTemp1[ 1] = 1'b1;
		assign outTemp1[ 2] = 1'b0;
		assign outTemp1[ 3] = d45_sign;
		Xor2Bus #(11) (outTemp1[14:4], {1'b1, d45_funcOut[9:0]}, d45_sign, xor2BusNumber);
		assign outTemp1[15] = 1'b0;
		
		// special  --> 0 000_0010_0100_1 10 1
		// outTemp1 --> 0 xxx_xxxx_xxxx_! 01 1  x stands for funcOut inverted
		// [14:10],8,7,5,4 -> x & special'
		// 9,6,3 -> x + special = (x' & special')'
		wire [15:0] outTemp2;

		wire nSpecial, n9, n6, n3;
		wire [50:0] ivBusNumber, nandBusNumber, andBusNumber;
		IvBus #(4) ({nSpecial, n9, n6, n3}, {d45_special, outTemp1[9], outTemp1[6], outTemp1[3]}, ivBusNumber);

		assign outTemp2[ 0] = 1'b1;
		assign outTemp2[ 1] = nSpecial;
		assign outTemp2[ 2] = d45_special;
		Nand2Bus #(3) ({outTemp2[9], outTemp2[6], outTemp2[3]}, {n9, n6, n3}, nSpecial, nandBusNumber);
		And2Bus #(9) ({outTemp2[14:10], outTemp2[8:7], outTemp2[5:4]}, {outTemp1[14:10], outTemp1[8:7], outTemp1[5:4]}, nSpecial, andBusNumber);
		assign outTemp2[15] = 1'b0;

		wire [50:0] stage5Number;
		assign stage5Number = xor2BusNumber + ivBusNumber + nandBusNumber + andBusNumber;

	/*------------------------------------- Stage 5 --> Output -------------------------------------*/
		wire [50:0] outputValidFFNumber, outputFFNumber;
		wire [50:0] stage5OutFFNumber;

		FD2 outputValidFF(o_out_valid, d45_valid, clk, rst_n, outputValidFFNumber);
		REGP #(14) outputFF(o_y[14:1], outTemp2[14:1], clk, rst_n, outputFFNumber);
		assign o_y[0] = 1'b1;
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

module Nand2Bus#(
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
			ND2 nd2(out[i], in1[i], in2, numbers[i]);
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
			EO xor2(out[i], in2, in1[i], numbers[i]);
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
		EO(S[0], P[0], Cin, S0number);
		EO(S[1], P[1], G10, S1number);
		EO(S[2], P[2], G20, S2number);
		EO(S[3], P[3], G30, S3number);
		
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
		EO(S[0], A[0], Cin, S0number);
		EO(S[1], A[1], G10, S1number);
		EO(S[2], A[2], G20, S2number);
		EO(S[3], A[3], G30, S3number);
		
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
		EO(S[1], A[1], G10, S1number);
		EO(S[2], A[2], G20, S2number);
		EO(S[3], A[3], G30, S3number);
		
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
		EO(S[1], P[1], G10, S1number);
		EO(S[2], P[2], G20, S2number);
		EO(S[3], P[3], G30, S3number);
		
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
		EO(S[0], P[0], Cin, S0number);
		EO(S[1], P[1], G10, S1number);
		EO(S[2], P[2], G20, S2number);
		EO(S[3], P[3], G30, S3number);
		
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
				10'b00_1111_1101,
				10'b01_1101_1110,
				10'b10_1000_1111,
				10'b11_0000_1011,
				10'b11_0110_0100,
				10'b11_1010_0010,
				10'b11_1100_1000,
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

	// out[0] = CTRL1'CTRL2' + CTRL0'CTRL2
		wire nandn1n2, nandn02;
		wire [50:0] nandn1n2Number, nandn02Number, out0Number;
		wire [50:0] number0;
		ND2(nandn1n2, nCTRL1, nCTRL2, nandn1n2Number);
		ND2(nandn02, nCTRL0, CTRL2, nandn02Number);
		ND2(out[0], nandn1n2, nandn02, out0Number);
		assign number0 = nandn1n2Number + nandn02Number + out0Number;

	// out[1] =  CTRL2' + CTRL0'CTRL1
		wire nandn01;
		wire [50:0] nandn01Number, out1Number;
		wire [50:0] number1;
		ND2(nandn01, nCTRL0, CTRL1, nandn01Number);
		ND2(out[1], CTRL2, nandn01, out1Number);
		assign number1 = nandn01Number + out1Number;

	// out[2] = CTRL1'CTRL2 + CTRL0'CTRL1
	// 		  = MUX, CTRL = CTRL1, 0 -> CTRL2, 1 -> CTRL0'
		wire nandn12;
		wire [50:0] nandn12Number, out2Number;
		wire [50:0] number2;
		ND2(nandn12, nCTRL1, CTRL2, nandn12Number);
		ND2(out[2], nandn12, nandn01, out2Number);
		assign number2 = nandn12Number + out2Number;

	// out[3] =  CTRL0'CTRL1 + CTRL0'CTRL2 + CTRL1CTRL2 + CTRL0CTRL1'CTRL2'
		wire nand12;
		wire [50:0] nand12Number, nand0n1n2Number, out3Number;
		wire [50:0] number3;
		ND2(nand12, CTRL1, CTRL2, nand12Number);
		ND3(nand0n1n2, CTRL0, nCTRL1, nCTRL2, nand0n1n2Number);
		ND4(out[3], nandn01, nandn02, nand12, nand0n1n2, out3Number);
		assign number3 = nand12Number + nand0n1n2Number + out3Number;

	// out[4] = CTRL0'CTRL1'CTRL2 + CTRL0'CTRL1CTRL2'
		wire nandn0n12, nandn01n2;
		wire [50:0] nandn0n12Number, nandn01n2Number, out4Number;
		wire [50:0] number4;
		ND3(nandn0n12, nCTRL0, nCTRL1,  CTRL2, nandn0n12Number);
		ND3(nandn01n2, nCTRL0,  CTRL1, nCTRL2, nandn01n2Number);
		ND2(out[4], nandn0n12, nandn01n2, out4Number);
		assign number4 = nandn0n12Number + nandn01n2Number + out4Number;

	// out[5] = CTRL1'CTRL2 + CTRL0CTRL1CTRL2'
		wire nand01n2;
		wire [50:0] nand01n2Number, out5Number;
		wire [50:0] number5;
		ND3(nand01n2, CTRL0, CTRL1, nCTRL2, nand01n2Number);
		ND2(out[5], nandn12, nand01n2, out5Number);
		assign number5 = nand01n2Number + out5Number;

	// out[6] = CTRL1'CTRL2 + CTRL0CTRL2 + CTRL0'CTRL1CTRL2'
		wire nand02;
		wire [50:0] nand02Number, out6Number;
		wire [50:0] number6;
		ND2(nand02, CTRL0, CTRL2, nand02Number);
		ND3(out[6], nandn12, nand02, nandn01n2, out6Number);
		assign number6 = nand02Number + out6Number;

	// out[7] = CTRL1 + CTRL0'CTRL2
		wire [50:0] number7;
		ND2(out[7], nCTRL1, nandn02, number7);

	// out[8] = CTRL0 + CTRL1CTRL2'
		wire nand1n2;
		wire [50:0] nand1n2Number, out8Number;
		wire [50:0] number8;
		ND2(nand1n2, CTRL1, nCTRL2, nand1n2Number);
		ND2(out[8], nCTRL0, nand1n2, out8Number);
		assign number8 = nand1n2Number + out8Number;

	// out[9] = CTRL0 + CTRL1CTRL2
		wire nand12;
		wire [50:0] nand12Number, out9Number;
		wire [50:0] number9;
		ND2(nand12, CTRL1, CTRL2, nand12Number);
		ND2(out[9], nCTRL0, nand12, out9Number);
		assign number9 = nand12Number + out9Number;

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

module mulStage1(
		output [5:0] add01,
		output [5:0] add23,
		input [3:0] aValue,
		input [3:0] abs_x,
		output [50:0] number
	);
		wire [3:0] abs_x0, abs_x1, abs_x2, abs_x3;
		wire [50:0] andNumber0, andNumber1, andNumber2, andNumber3;
		wire [50:0] andNumber;

		And2Bus #(4) (abs_x0, abs_x[3:0], aValue[0], andNumber0);
		And2Bus #(4) (abs_x1, abs_x[3:0], aValue[1], andNumber1);
		And2Bus #(4) (abs_x2, abs_x[3:0], aValue[2], andNumber2);
		And2Bus #(4) (abs_x3, abs_x[3:0], aValue[3], andNumber3);
		assign andNumber = andNumber0 + andNumber1 + andNumber2 + andNumber3;

		wire carry01, carry23;
		wire [50:0] ck4Number01, ck4Number23;
		wire [50:0] stage2Number;

		assign add01[0] = abs_x0[0];
		carrySkip4NoCin(add01[4:1], add01[5], {1'b0, abs_x0[3:1]}, abs_x1[3:0], ck4Number01);

		assign add23[0] = abs_x2[0];
		carrySkip4NoCin(add23[4:1], add23[5], {1'b0, abs_x2[3:1]}, abs_x3[3:0], ck4Number23);

		assign number = andNumber + ck4Number01 + ck4Number23;
endmodule

module mulStage2(
		output [7:0] S,
		input [5:0] add01,
		input [5:0] add23,
		output [50:0] number
	);
	assign S[1:0] = add01[1:0];
	wire carry5, n7, nd6;
	wire [50:0] ck4Number, xorNumber, nand2Number1, ivNumber, nand2Number2;

	carrySkip4NoCin(S[5:2], carry5, add01[5:2], add23[3:0], ck4Number);
	EO(S[6], add23[4], carry5, xorNumber);
	ND2(nd6, carry5, add23[4], nand2Number1);
	IV(n7, add23[5], ivNumber);
	ND2(S[7], nd6, n7, nand2Number2);

	assign number = ck4Number + xorNumber + nand2Number1 + ivNumber + nand2Number2;
endmodule

module addStage(
		output [9:0] S,
		input [7:0] mul,
		input [9:0] b,
		output [50:0] number
	);
	wire carry, n9, nd8;
	wire [50:0] ck8Number, xorNumber, nand2Number1, ivNumber, nand2Number2;

	carrySkip8NoCin(S[7:0], carry, mul[7:0], b[7:0], ck8Number);
	EO(S[8], b[8], carry, xorNumber);

	ND2(nd8, carry, b[8], nand2Number1);
	IV(n9, b[9], ivNumber);
	ND2(S[9], nd8, n9, nand2Number2);

	assign number = ck8Number + xorNumber + nand2Number1 + ivNumber + nand2Number2;
endmodule