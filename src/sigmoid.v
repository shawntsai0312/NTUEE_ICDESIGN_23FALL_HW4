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

module XNOR2(Z, A, B);
	input A, B;
	output Z;
	// F = ab + (a+b)'		, delay = nor2 +   or2 = 0.227 + 0.300 = 0.527
	//   = [(ab)' & (a+b)]'	, delay =  or2 + nand2 = 0.300 + 0.176 = 0.476
	//   = (a'b+ab')'   	, delay = xor2 +   inv = 0.343 + 0.127 = 0.470 <-- choose this
	// MUX21(f, a', a, b)	, delay =  inv +   mux = 0.127 + 0.347 = 0.474
	// although we can use xnor, but the delay is too high !!!
	wire xor2;
	EO(xor2, A, B);
	IV(Z, xor2);
endmodule

module OR3low(Z,A,B,C);
	input A, B, C;
	output Z;

	// original or3 = 0.43
	// use or4low instead
	OR4low(Z, A, B, C, 1'b0);
endmodule

module OR4low(Z,A,B,C,D);
	input A, B, C, D;
	output Z;

	// original or4 = 0.544
	// z = a + b + c + d
	//   = [(a+b)'&(c+d)']'		, delay = nor2 + nand2 = 0.227 + 0.176 = 0.403
	wire nor21, nor22;
	NR2(nor21, A, B);
	NR2(nor22, C, D);
	ND2(Z, nor21, nor22);
endmodule

module OR5(Z,A,B,C,D,E);
	// or 5
	// use or6
	input A, B, C, D, E;
	output Z;
	
	OR6(Z,A,B,C,D,E,1'b0);
endmodule

module NR5(Z,A,B,C,D,E);
	// nor 5
	// use nor6
	input A, B, C, D, E;
	output Z;
	
	NR6(Z,A,B,C,D,E,1'b0);
endmodule

module AN5(Z,A,B,C,D,E);
	// and 5
	// use and6
	input A, B, C, D, E;
	output Z;
	
	AN6(Z,A,B,C,D,E,1'b1);
endmodule

module ND5(Z,A,B,C,D,E);
	// nand 6
	// use nand6
	input A, B, C, D, E;
	output Z;
	
	ND6(Z,A,B,C,D,E,1'b1);
endmodule

module OR6(Z,A,B,C,D,E,F);
	// or6
	// f = a+b+c+d+e+f
	//   = [(a+b+c)'(d+e+f)']'		, delay = nor3 + nand2 = 0.345 + 0.176 = 0.521
	//   = [(a+b)'(c+d)'(e+f)']'	, delay = nor2 + nand3 = 0.227 + 0.226 = 0.453  <-- choose this
	input A, B, C, D, E, F;
	output Z;
	
	wire nor21, nor22, nor23;
	NR2(nor21, A, B);
	NR2(nor22, C, D);
	NR2(nor23, E, F);
	ND3(Z, nor21, nor22, nor23);
endmodule

module NR6(Z,A,B,C,D,E,F);
	// nor 6
	// f = (a+b+c+d+e+f)'
	//   = (a+b+c)'(d+e+f)'		, delay = nor3 + and2 = 0.345 + 0.225 = 0.570
	//   = (a+b)'(c+d)'(e+f)'	, delay = nor2 + and3 = 0.227 + 0.275 = 0.502  <-- choose this
	input A, B, C, D, E, F;
	output Z;
	
	wire nor21, nor22, nor23;
	NR2(nor21, A, B);
	NR2(nor22, C, D);
	NR2(nor23, E, F);
	AN3(Z, nor21, nor22, nor23);
endmodule

module AN6(Z,A,B,C,D,E,F);
	// and6
	// F = (abc)(def)					, delay =   and3 + and2 = 0.275 + 0.225 = 0.500
	//   = [(abc)'+(def)']'				, delay =  nand3 + nor2 = 0.226 + 0.227 = 0.453  <-- choose this
	//	 = [(ab)'+(cd)'+(ef)']'			, delay =  nand2 + nor3 = 0.176 + 0.345 = 0.521
	input A, B, C, D, E, F;
	output Z;
	
	wire nand31, nand32;
	ND3(nand31, A, B, C);
	ND3(nand32, D, E, F);
	NR2(Z, nand31, nand32);
endmodule

module ND6(Z,A,B,C,D,E,F);
	// nand 6
	// f = (abcdef)'
	//   = (abc)'+(def)'			, delay = nand3 +   or2 = 0.226 + 0.300 = 0.526
	//   = (ab)'+(cd)'+(ef)'		, delay = nand2 +   or3 = 0.176 + 0.403 = 0.579
	//	 = ((abc)(def))'			, delay =  and3 + nand2 = 0.275 + 0.176 = 0.451  <-- choose this
	//   = ((ab)(cd)(ef))'			, delay =  and2 + nand3 = 0.225 + 0.226 = 0.451
	input A, B, C, D, E, F;
	output Z;
	
	wire and31, and32;
	AN3(and31, A, B, C);
	AN3(and32, D, E, F);
	ND2(Z, and31, and32);
endmodule

module OR8(Z,A,B,C,D,E,F,G,H);
	// or8
	// F = [(a+b+c)'(d+e+f)'(g+h)]'			, delay =  nor3 + nand3 = 0.345 + 0.226 = 0.571
	//   = [(a+b+c+d)'(e+f+g+h)']'			, delay =  nor4 + nand2 = 0.345 + 0.176 = 0.521  <-- choose this
	//   = [(a+b)'(c+d)'(e+f)'(g+h)']'		, delay =  nor2 + nand4 = 0.227 + 0.296 = 0.523
	input A,B,C,D;
	input E,F,G,H;
	output Z;
	wire nor41, nor42;
	NR4(nor41,A,B,C,D);
	NR4(nor42,E,F,G,H);
	ND2(Z, nor41, nor42);
endmodule

module NR8(Z,A,B,C,D,E,F,G,H);
	// nor8
	// F = (a+b+c)'(d+e+f)'(g+h)		, delay =  nor3 + and3 = 0.345 + 0.275 = 0.620
	//   = (a+b+c+d)'(e+f+g+h)'			, delay =  nor4 + and2 = 0.345 + 0.225 = 0.570  <-- choose this
	//   = (a+b)'(c+d)'(e+f)'(g+h)'		, delay =  nor2 + and4 = 0.227 + 0.371 = 0.598
	input A,B,C,D;
	input E,F,G,H;
	output Z;
	wire nor41, nor42;
	NR4(nor41,A,B,C,D);
	NR4(nor42,E,F,G,H);
	AN2(Z, nor41, nor42);
endmodule

module AN8(Z,A,B,C,D,E,F,G,H);
	// and8
	// F = (abc)(def)(gh)				, delay =   and3 + and3 = 0.275 + 0.275 = 0.550
	//   = [(abc)'+(def)'+(gh)']'		, delay =  nand3 + nor3 = 0.226 + 0.345 = 0.571
	//   = [(abcd)'+(efgh)']'			, delay =  nand4 + nor2 = 0.296 + 0.227 = 0.523  <-- choose this
	input A,B,C,D;
	input E,F,G,H;
	output Z;
	wire nand41, nand42;
	ND4(nand41,A,B,C,D);
	ND4(nand42,E,F,G,H);
	NR2(Z,nand41,nand42);
endmodule

module ND8(Z,A,B,C,D,E,F,G,H);
	// nand8
	// F = [(abc)(def)(gh)]'		, delay =  and3 + nand3 = 0.275 + 0.226 = 0.501  <-- choose this
	//   = [(abcd)(efgh)]'			, delay =  and4 + nand2 = 0.371 + 0.176 = 0.547
	//   = [(ab)(cd)(ef)(gh)]'		, delay =  and2 + nand4 = 0.225 + 0.296 = 0.521
	input A,B,C,D;
	input E,F,G,H;
	output Z;
	wire and2, and31, and32;
	AN3(and31,A,B,C);
	AN3(and32,D,E,F);
	AN2(and2,G,H);
	ND3(Z,and31,and32,and2);
endmodule

module AN9(Z,A,B,C,D,E,F,G,H,I);
	// and9
	// F = (abc)(def)(ghi)				, delay =   and3 + and3 = 0.275 + 0.275 = 0.550  <-- choose this
	//   = [(abc)'+(def)'+(ghi)']'		, delay =  nand3 + nor3 = 0.226 + 0.345 = 0.571
	//   = [(ab)'+(cd)'+(ef)'+(ghi)']'	, delay =  nand3 + nor4 (x)
	input A,B,C,D;
	input E,F,G,H,I;
	output Z;
	wire and31, and32, and33;
	AN3(and31,A,B,C);
	AN3(and32,D,E,F);
	AN3(and33,G,H,I);
	AN3(Z,and31,and32,and33);
endmodule

module ND9(Z,A,B,C,D,E,F,G,H,I);
	// nand9
	// F = [(abc)(def)(ghi)]'		, delay =  and3 + nand3 = 0.275 + 0.226 = 0.501  <-- choose this
	input A,B,C,D;
	input E,F,G,H,I;
	output Z;
	wire and31, and32, and33;
	AN3(and31,A,B,C);
	AN3(and32,D,E,F);
	AN3(and33,G,H,I);
	ND3(Z,and31,and32,and33);
endmodule

module OR10(Z,A,B,C,D,E,F,G,H,I,J);
	// or10
	// F = (a+b+c)+(d+e+f)+(g+h+i+j)
	//   = [(a+b+c+0)'(d+e+f+0)'(g+h+i+j)']'
	// delay = nor4 + nand3 = 0.345 + 0.226 = 0.571
	// nor4 is faster than nor3
	input A,B,C,D,E;
	input F,G,H,I,J;
	output Z;
	wire nor31, nor32, nor4;
	NR4(nor31,A,B,C,1'b0);
	NR4(nor32,D,E,F,1'b0);
	NR4(nor4,G,H,I,J);
	ND3(Z,nor31,nor32,nor4);
endmodule

module NR10(Z,A,B,C,D,E,F,G,H,I,J);
	// nor10
	// F = [(a+b+c)+(d+e+f)+(g+h+i+j)]'		, delay =  or4 + nor3 = 0.403 + 0.345 = 0.748
	//   = (a+b+c+0)'(d+e+f+0)'(g+h+i+j)'	, delay = nor4 + and3 = 0.345 + 0.275 = 0.620 <-- choose this
	//	 = (a+b+c+0)'(d+e+f+0)'(g+h)'(i+j)'	, delay = nor3 + and4 = 0.345 + 0.371 = 0.716
	input A,B,C,D,E;
	input F,G,H,I,J;
	output Z;
	wire nor31, nor32, nor4;
	NR4(nor31,A,B,C,1'b0);
	NR4(nor32,D,E,F,1'b0);
	NR4(nor4,G,H,I,J);
	AN3(Z,nor31,nor32,nor4);
endmodule

module AN10(Z,A,B,C,D,E,F,G,H,I,J);
	// and10
	// F = (abc)(def)(ghij)				, delay =   and4 + and3 = 0.371 + 0.275 = 0.646
	//   = [(abc)'+(def)'+(gh)'+(ij)']'	, delay =  nand3 + nor4 = 0.226 + 0.345 = 0.571  <-- choose this
	//   = [(abc)'+(def)'+(ghij)']'		, delay =  nand4 + nor3 = 0.296 + 0.345 = 0.641
	input A,B,C,D,E;
	input F,G,H,I,J;
	output Z;
	wire nand21, nand22, nand31, nand32;
	ND3(nand31,A,B,C);
	ND3(nand32,D,E,F);
	ND2(nand21,G,H);
	ND2(nand22,I,J);
	NR4(Z,nand31,nand32,nand21,nand22);
endmodule

module ND10(Z,A,B,C,D,E,F,G,H,I,J);
	// nand10
	// F = [(abc)(def)(ghij)]'		, delay =  and4 + nand3 = 0.371 + 0.226 = 0.697
	//   = [(abc)(def)(gh)(ij)]'	, delay =  and3 + nand4 = 0.275 + 0.296 = 0.571  <-- choose this
	//   = (abc)'+(def)'+(ghij)'	, delay = nand4 +   or3 = 0.296 + 0.403 = 0.699
	input A,B,C,D,E;
	input F,G,H,I,J;
	output Z;
	wire and21, and22, and31, and32;
	AN3(and31,A,B,C);
	AN3(and32,D,E,F);
	AN2(and21,G,H);
	AN2(and22,I,J);
	ND4(Z,and31,and32,and21,and22);
endmodule