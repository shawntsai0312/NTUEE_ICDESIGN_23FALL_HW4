`timescale 1ns / 1ps
`define CYCLE 10.0
`define PATTERN 256

module tb;

//clk generation
reg clk = 1;
always #(`CYCLE/2) clk = ~clk;

//dump waveform
initial begin
	$dumpfile("sigmoid.vcd");
    $dumpvars;
	// $fsdbDumpfile("sigmoid.fsdb");
	// $fsdbDumpvars(0,"+mda");
end

//time out
initial begin
	#(100000*`CYCLE);
	$display("\n\033[1;31m=============================================");
	$display("           Simulation Time Out!      ");
	$display("=============================================\033[0m");
	$finish;
end

//instatiate DUT
reg rst_n = 1;
reg [7:0] i_x;
reg i_valid;
wire o_valid;
wire [15:0] o_y;
wire [50:0] number;

sigmoid DUT(
	.clk         (clk),
	.rst_n       (rst_n),
	.i_x         (i_x),
	.i_in_valid  (i_valid),
	.o_out_valid (o_valid),
	.o_y         (o_y),
	.number      (number)
);

//Initial memory
reg [7:0] INPUTX_MEM [0:`PATTERN-1];
reg [15:0]  GOLDEN_MEM [0:`PATTERN-1];

initial begin
	$readmemb("pattern/Inn.dat", INPUTX_MEM);
	$readmemb("pattern/Gol.dat", GOLDEN_MEM);
end

//Latency
integer latency;
always @(posedge clk or negedge rst_n) begin 
	if (~rst_n) begin 
		latency = -1;
	end
	else begin
		latency = latency + 1;
	end
end

//input pattern & check result
integer i, j;
integer total_latency = 0;
integer diff;
integer error;
reg [100:0] mse = 0;

//input
initial begin
	//reset 
	i_valid = 0;
	@(posedge clk) rst_n = 0;
	@(posedge clk); 
	rst_n = 1;
	@(posedge clk);
	for (i=0; i<`PATTERN; i=i+1) begin
		#(0.6); //filp flop hold time
		i_x = INPUTX_MEM[i];
		i_valid = 1;
		@(posedge clk); 
	end
	#(0.6);
	i_valid = 0;
	i_x = 'bx;
end


//check output
initial begin
	wait (o_valid);
	@(negedge clk);
	for (j=0; j<`PATTERN; j=j+1) begin
		if (o_valid !== 1)begin
			$display("\n\033[1;31m=============================================");
			$display("     o_valid should be kept high once       ");
			$display("     you pull it up in pipeline mode.       ");
			$display("=============================================\033[0m");
			@(negedge clk);
			$finish;
		end else begin
			diff  = (o_y>=GOLDEN_MEM[j]) ? (o_y-GOLDEN_MEM[j]) : (GOLDEN_MEM[j]-o_y);
			error = diff*diff;
			`ifdef DEBUG
				$display("Pattern %3d. / Output: %2d / Golden: %1d / MSE: %1d", j, o_y, GOLDEN_MEM[j], error[31:8]);
			`endif
			mse = mse + error;
		end
		@(negedge clk);
	end
	total_latency = latency-1;

	$display("\n\033[1;92m=============================================");
	$display("              Simulation finished            ");
	$display("=============================================\033[0m");

	$display("\n\033[1;96m=============================================");
	$display("                   Summary                   ");
	$display("=============================================");
	$display("  Clock cycle:               %.1f ns", `CYCLE);
	$display("  Number of transistors:     %.0f", $itor(number));
	$display("  Total excution cycle:      %.0f", $itor(total_latency));
	$display("  Approximation Error Score: %.1f", $itor(mse[100:8]));
	$display("  Performance Score:         %.1f", $itor(total_latency) * $itor(number) * `CYCLE);
	$display("=============================================\033[0m");

	$finish;
end

endmodule
