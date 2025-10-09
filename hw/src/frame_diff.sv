//Frame difference module wrapper. Calculate freme differences between current and prevouce frame to get "event camera" effect
	
module 	frame_diff #(
	parameter DATA_WIDTH = 8,
	parameter MAX_INPUT_WIDTH = 1504,
	parameter MAX_INPUT_HEIGHT = 480)

(
	input I_sdrc_clk,//control IF and data stream clock, 
	input I_sdram_clk,//clock to SDRAM
	input		rst,
	input		enable_diff_mode,
	
	//ready latency  = 0
	input					din_sop,
	input [DATA_WIDTH-1:0]	din_data,
	input					din_valid,
	output					din_ready,

	input					dout_ready,
	output 					dout_sop,
	output [DATA_WIDTH-1:0]	dout_data,
	output					dout_valid,
	
	//actual number of pixels in frame should be multiple of 4 bytes!
	input 	[$clog2(MAX_INPUT_WIDTH)-1:0]	param_frame_width,
	input 	[$clog2(MAX_INPUT_HEIGHT)-1:0]	param_frame_height,
	
	//sdram side
	output O_sdram_clk,
	output O_sdram_cke,
	output O_sdram_cs_n,
	output O_sdram_cas_n,
	output O_sdram_ras_n,
	output O_sdram_wen_n,
	output [3:0] O_sdram_dqm,
	output [10:0] O_sdram_addr,
	output [1:0] O_sdram_ba,
	inout [31:0] IO_sdram_dq); 
	
	
	/*logic dinReady;
	logic doutReady; 
	logic doutValid;
	logic outTransaction;
	assign outTransaction = dout_ready && dout_valid;	
	assign din_ready = dinReady && outTransaction;
	assign dout_valid = doutValid && outTransaction;  */

	frame_buffer #(
		.DATA_WIDTH(DATA_WIDTH),
		.MAX_INPUT_WIDTH(MAX_INPUT_WIDTH),
		.MAX_INPUT_HEIGHT(MAX_INPUT_HEIGHT))
	frameBufferInst(
		.I_sdrc_clk(I_sdrc_clk),//control IF and data stream clock, 
		.I_sdram_clk(I_sdram_clk),//clock to SDRAM
		.rst(rst), 
		.enable_diff_mode(enable_diff_mode),
	
		//ready latency  = 0
		.din_sop(din_sop),
		.din_data(din_data),
		.din_valid(din_valid),
		.din_ready(din_ready),

		.dout_ready(dout_ready),
		.dout_sop(dout_sop),
		.dout_data(dout_data),
		.dout_valid(dout_valid),
	
		//actual number of pixels in frame should be multiple of 4 bytes!
		.param_frame_width(param_frame_width),
		.param_frame_height(param_frame_height),
	
		//sdram side
		.O_sdram_clk(O_sdram_clk),
		.O_sdram_cke(O_sdram_cke),
		.O_sdram_cs_n(O_sdram_cs_n),
		.O_sdram_cas_n(O_sdram_cas_n),
		.O_sdram_ras_n(O_sdram_ras_n),
		.O_sdram_wen_n(O_sdram_wen_n),
		.O_sdram_dqm(O_sdram_dqm),
		.O_sdram_addr(O_sdram_addr),
		.O_sdram_ba(O_sdram_ba),
		.IO_sdram_dq(IO_sdram_dq));
	
endmodule