//modules for stream routing 
module mux_2_to_1_comb#(
	parameter DATA_WIDTH = 8)
	(
	input 					sel,// 1'b0 : din_0=>dout, 1'b1 : din_1=>dout
	
	input					din_0_sop,
	input [DATA_WIDTH-1:0]	din_0_data,
	input					din_0_valid,
	output					din_0_ready,
	
	input					din_1_sop,
	input [DATA_WIDTH-1:0]	din_1_data,
	input					din_1_valid,
	output					din_1_ready,
	

	input					dout_ready,
	output 					dout_sop,
	output [DATA_WIDTH-1:0]	dout_data,
	output					dout_valid);
	
	assign dout_sop = sel ? din_1_sop : din_0_sop;
	assign dout_data = sel ? din_1_data : din_0_data;
	assign dout_valid = sel ? din_1_valid : din_0_valid;
	
	assign din_0_ready = sel ? 1'b0 : dout_ready;
	assign din_1_ready = sel ? dout_ready : 1'b0;
	
endmodule

module demux_1_to_2_comb#(
	parameter DATA_WIDTH = 8)
	(
	input 					sel,// 1'b0 : din=>dout_0, 1'b1 : din=>dout_1
	
	input					din_sop,
	input [DATA_WIDTH-1:0]	din_data,
	input					din_valid,
	output					din_ready,
	
	input					dout_0_ready,
	output 					dout_0_sop,
	output [DATA_WIDTH-1:0]	dout_0_data,
	output					dout_0_valid,
	
	input					dout_1_ready,
	output 					dout_1_sop,
	output [DATA_WIDTH-1:0]	dout_1_data,
	output					dout_1_valid);
	
	assign dout_1_sop = sel ? din_sop : 1'b0;
	assign dout_1_data = sel ? din_data : 0;
	assign dout_1_valid = sel ? din_valid : 1'b0;
	
	assign dout_0_sop = sel ? 1'b0 : din_sop;
	assign dout_0_data = sel ? 0 : din_data;
	assign dout_0_valid = sel ? 1'b0 : din_valid;
	
	assign din_ready = sel ? dout_1_ready : dout_0_ready;
	
endmodule


module bypass_loop#(
	parameter DATA_WIDTH = 8)
	(
	input 					bypass,// 1'b0 : din=>loop_send; loop_ret=>dout, 1'b1 : din=>dout
	
	input					din_sop,
	input [DATA_WIDTH-1:0]	din_data,
	input					din_valid,
	output					din_ready,
	
	input					dout_loop_send_ready,
	output 					dout_loop_send_sop,
	output [DATA_WIDTH-1:0]	dout_loop_send_data,
	output					dout_loop_send_valid,
	
	input					din_loop_ret_sop,
	input [DATA_WIDTH-1:0]	din_loop_ret_data,
	input					din_loop_ret_valid,
	output					din_loop_ret_ready,
	
	input					dout_ready,
	output 					dout_sop,
	output [DATA_WIDTH-1:0]	dout_data,
	output					dout_valid);
	
	logic 					demuxDout1Ready;
	logic 					demuxDout1Sop;
	logic [DATA_WIDTH-1:0] 	demuxDout1Data;
	logic 					demuxDout1Valid;
	
	demux_1_to_2_comb#(
		.DATA_WIDTH(DATA_WIDTH))
	demux_1_to_2_combInst(
		.sel(bypass),// 1'b0 : din=>dout_0, 1'b1 : din=>dout_1
	
		.din_sop(din_sop),
		.din_data(din_data),
		.din_valid(din_valid),
		.din_ready(din_ready),
	
		.dout_0_ready(dout_loop_send_ready),
		.dout_0_sop(dout_loop_send_sop),
		.dout_0_data(dout_loop_send_data),
		.dout_0_valid(dout_loop_send_valid),
	
		.dout_1_ready(demuxDout1Ready),
		.dout_1_sop(demuxDout1Sop),
		.dout_1_data(demuxDout1Data),
		.dout_1_valid(demuxDout1Valid));
	

 	mux_2_to_1_comb#(
		.DATA_WIDTH(DATA_WIDTH))
	mux_2_to_1_combInst(
		.sel(bypass),// 1'b0 : din_0=>dout, 1'b1 : din_1=>dout
	
		.din_0_sop(din_loop_ret_sop),
		.din_0_data(din_loop_ret_data),
		.din_0_valid(din_loop_ret_valid),
		.din_0_ready(din_loop_ret_ready),
		
		.din_1_sop(demuxDout1Sop),
		.din_1_data(demuxDout1Data),
		.din_1_valid(demuxDout1Valid),
		.din_1_ready(demuxDout1Ready),
	
		.dout_ready(dout_ready),
		.dout_sop(dout_sop),
		.dout_data(dout_data),
		.dout_valid(dout_valid));
	
endmodule

