module video_subsystem	#( 
	parameter DATA_WIDTH = 8,
	parameter MAX_IMAGE_WIDTH = 752,
	parameter MAX_IMAGE_HEIGHT = 480,
	parameter VSYNC_ACTIVE_LEVEL = 0, //same for input and output
	parameter HSYNC_ACTIVE_LEVEL = 0,
	parameter IMAGE_WIDTH_DEFAULT = 640,
	parameter IMAGE_HEIGHT_DEFAULT = 480,
	parameter EXP_DEFAULT = 'h00030B00)
	(
	input	clk,//pipeline clock						
	input	clk_sdram, //sdram clock
	input	rst,
	input	clk_dcmi,
	input	clk_sensor,//clock from fpga to sensors


	//both camera control signals
	//clk_sensor domain
    input           control_ena,//start frame driving	
    output			exposure,
	output			start_frame,
	output			start_line,

	
	//each camera provide itself clock to fpga
	input 					mt1_clk,
	input 					mt1_hsync, //lines
	input 					mt1_vsync, //frame
	input [DATA_WIDTH-1:0]	mt1_data,

	input 					mt2_clk,
	input 					mt2_hsync, //lines
	input 					mt2_vsync, //frame
	input [DATA_WIDTH-1:0]	mt2_data,
	
	//clk domain
	input [$clog2(MAX_IMAGE_WIDTH)-1:0]		param_frame_width,
	input [$clog2(MAX_IMAGE_HEIGHT)-1:0]	param_frame_height,
	input [23:0]							param_target_exposure,
	input [10:0]							param_start_line_base,
	input [10:0]							param_start_line_gap,
	input									param_enable_diff_mode,
	input [1:0]								param_filt1_type,
	input [1:0]								param_filt2_type,
	input 									param_filt_ena,
	input									param_update,
	
	//gamma table host i/f
	input		 gamma_table_clk,
	input [7:0]  gamma_table_data,
	input [7:0]  gamma_table_addr,
	input 		 gamma_table_we,
	output 		 gamma_table_ack,
	
	//clk_dcmi domain
	output 						dcmi_hsync,	// line sync
	output 						dcmi_vsync,	// frame sync
	output	[DATA_WIDTH-1:0]	dcmi_data,
	
	//sdram		   		
	output 						O_sdram_clk,
	output 						O_sdram_cke,
	output 						O_sdram_cs_n,
	output 						O_sdram_cas_n,
	output 						O_sdram_ras_n,
	output 						O_sdram_wen_n,
	output 						[3:0] O_sdram_dqm,
	output 						[10:0] O_sdram_addr,
	output 						[1:0] O_sdram_ba,
	inout 						[31:0] IO_sdram_dq
);	

	
	mt9v034_slave_seq_mode #( 
		.MAX_IMAGE_WIDTH(MAX_IMAGE_WIDTH),
		.MAX_IMAGE_HEIGHT(MAX_IMAGE_HEIGHT),
		.IMAGE_WIDTH_DEFAULT(IMAGE_WIDTH_DEFAULT),
		.IMAGE_HEIGHT_DEFAULT(IMAGE_HEIGHT_DEFAULT),		
		.EXP_DEFAULT(EXP_DEFAULT),
		.VSYNC_ACTIVE_LEVEL(VSYNC_ACTIVE_LEVEL),
		.HSYNC_ACTIVE_LEVEL(HSYNC_ACTIVE_LEVEL),
		.VERTICAL_BLANK(4),//shold be same as in reg 0x06 in mt9v034
		.HORIZONTAL_BLANK(104))//shold be same as in reg 0x05 in mt9v034
	mt9v034_slave_seq_mode_inst
	(
		.reset(rst),
		.mt9v034_sysclk(clk_sensor),//master clock from fpga to sensor (26.6 MHz; 13 MHz – 27 MHz). used as system clock for this block
        .ena(control_ena),
		//async signals related to mt9v034_sysclk. need to resync to mt9v034_sysclk
		//from control logic 
		.integration_time(param_target_exposure),//integration time calculates by external module. In mt9v034_sysclk ticks 	
		.frame_width(param_frame_width),//active frame width
		.frame_height(param_frame_height),//active frame height

		//async signals related to mt9v034_sysclk. need to resync to mt9v034_sysclk
		//from one of sensor. Assumed both sensors produce same signals
		.v_sync(mt1_vsync),
		.h_sync(mt1_hsync),
 	
		//mt9v034_sysclk clock domain
		.exposure(exposure),
		.stln_out(start_line),
		.stfrm_out(start_frame));
		
	logic 	[13:0]	mt1RcvdData;//TODO check datawidth
	logic			mt1RcvdFrameStart;
	logic			mt1RcvdDvalid;

	dcmi_receiver #(
		.MAX_IMAGE_WIDTH(MAX_IMAGE_WIDTH),
		.MAX_IMAGE_HEIGHT(MAX_IMAGE_HEIGHT),
		.VSYNC_ACTIVE_LEVEL(VSYNC_ACTIVE_LEVEL),
		.HSYNC_ACTIVE_LEVEL(HSYNC_ACTIVE_LEVEL)) 	
	mt1RcvInst(
		.sys_clk(clk),	
	 	.rst(rst),
	
		.rcvd_data(mt1RcvdData),
		.rcvd_frame_start(mt1RcvdFrameStart),
		.rcvd_dvalid(mt1RcvdDvalid),
		//.locked(),
		
		.dcmi_pixclk(mt1_clk),
		.dcmi_hsync(mt1_hsync), //lines
		.dcmi_vsync(mt1_vsync), //frame
		.dcmi_data({6'b0, mt1_data}),
		.param_frame_width(param_frame_width),
		.param_frame_height(param_frame_height));	

	logic 	[13:0]	mt2RcvdData;//TODO check datawidth
	logic			mt2RcvdFrameStart;
	logic			mt2RcvdDvalid;
	
	dcmi_receiver #(
		.MAX_IMAGE_WIDTH(MAX_IMAGE_WIDTH),
		.MAX_IMAGE_HEIGHT(MAX_IMAGE_HEIGHT),
		.VSYNC_ACTIVE_LEVEL(VSYNC_ACTIVE_LEVEL),
		.HSYNC_ACTIVE_LEVEL(HSYNC_ACTIVE_LEVEL)) 	
	mt2RcvInst(
		.sys_clk(clk),	
	 	.rst(rst),
	
		.rcvd_data(mt2RcvdData),
		.rcvd_frame_start(mt2RcvdFrameStart),
		.rcvd_dvalid(mt2RcvdDvalid),
		//.locked(),
		
		.dcmi_pixclk(mt2_clk),
		.dcmi_hsync(mt2_hsync), //lines
		.dcmi_vsync(mt2_vsync), //frame
		.dcmi_data({6'b0, mt2_data}),
		.param_frame_width(param_frame_width),
		.param_frame_height(param_frame_height));	
		
	
	logic stitcherDoutReady;  
	logic stitcherDoutStart;
	logic [DATA_WIDTH-1:0] stitcherDoutData;
	logic stitcherDoutValid;
		
	stitcher_v2 #(
		.DATA_WIDTH(DATA_WIDTH),
		.MAX_INPUT_WIDTH(MAX_IMAGE_WIDTH),
           .IMAGE_WIDTH_DEFAULT(IMAGE_WIDTH_DEFAULT))
	stitcherInst(
		.clk(clk),
		.rst(rst),
	
		//ready latency  = 0
		.din1_sop(mt1RcvdFrameStart),
		.din1_data(mt1RcvdData[DATA_WIDTH-1:0]),
		.din1_valid(mt1RcvdDvalid),
		.din1_ready(),
	
		.din2_sop(mt2RcvdFrameStart),
		.din2_data(mt2RcvdData[DATA_WIDTH-1:0]),
		.din2_valid(mt2RcvdDvalid),
		.din2_ready(),

		.dout_ready(stitcherDoutReady),
		.dout_sop(stitcherDoutStart),
		.dout_data(stitcherDoutData),
		.dout_valid(stitcherDoutValid),
		
		.param_frame_width(param_frame_width));//input width. output frame will have x2 width

	logic gammaDoutReady;  
	logic gammaDoutStart;
	logic [DATA_WIDTH-1:0] gammaDoutData;
	logic gammaDoutValid;

	
	gamma_correction#( 
		.DATA_WIDTH(DATA_WIDTH))
	gamma_correctionInst(
		.clk(clk),						
		.rst(rst),

		.din_sop(stitcherDoutStart),
		.din_data(stitcherDoutData),
		.din_valid(stitcherDoutValid),
		.din_ready(stitcherDoutReady),

		.dout_ready(gammaDoutReady),
		.dout_sop(gammaDoutStart),
		.dout_data(gammaDoutData),
		.dout_valid(gammaDoutValid),
	
		//table host i/f
		.table_clk(gamma_table_clk),
		.table_data(gamma_table_data),
		.table_addr(gamma_table_addr),
		.table_we(gamma_table_we),
		.table_ack(gamma_table_ack)
);

	logic [10:0] paramFrameWidthX2;
	assign paramFrameWidthX2 = param_frame_width << 1;

	logic diffDoutReady;  
	logic diffDoutStart;
	logic [DATA_WIDTH-1:0] diffDoutData;
	logic diffDoutValid;
		
		
	frame_diff #(
		.DATA_WIDTH(DATA_WIDTH),
		.MAX_INPUT_WIDTH(MAX_IMAGE_WIDTH*2),
		.MAX_INPUT_HEIGHT(MAX_IMAGE_HEIGHT))
	frame_diffInst(
		.I_sdrc_clk(clk),//control IF and data stream clock, 
		.I_sdram_clk(clk_sdram),//clock to SDRAM
		.rst(rst),
		.enable_diff_mode(param_enable_diff_mode),
	
		//ready latency  = 0
		.din_sop(gammaDoutStart),
		.din_data(gammaDoutData),
		.din_valid(gammaDoutValid),
		.din_ready(gammaDoutReady),

		.dout_ready(diffDoutReady),
		.dout_sop(diffDoutStart),
		.dout_data(diffDoutData),
		.dout_valid(diffDoutValid),
	
		//actual number of pixels in frame should be multiple of 4 bytes!
		.param_frame_width(paramFrameWidthX2),
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
		
	//morth filter
	
	logic morph1DinReady;  
	logic morph1DinStart;
	logic [DATA_WIDTH-1:0] morph1DinData;
	logic morph1DinValid;
	
	logic morph1DoutReady;  
	logic morph1DoutStart;
	logic [DATA_WIDTH-1:0] morph1DoutData;
	logic morph1DoutValid;
	morph_filter#( 
		.DATA_WIDTH(DATA_WIDTH),
		.MAX_IMAGE_WIDTH(MAX_IMAGE_WIDTH*2),
		.MAX_IMAGE_HEIGHT(MAX_IMAGE_HEIGHT))
	morph_filterInst1(
		.clk(clk),						
		.rst(rst),

		// 0 - Pass
		// 1 - Dilation(max from window)
		// 2 - Erosion (min from window)
		// 3 - Median Filtering(median from filter)
		.filter_type(param_filt1_type),
		.param_frame_width(paramFrameWidthX2),
	
	//ready latency  = 0
		.din_data(morph1DinData),
		.din_sop(morph1DinStart),
		.din_valid(morph1DinValid),
		.din_ready(morph1DinReady),

		.dout_ready(morph1DoutReady),
		.dout_sop(morph1DoutStart),
		.dout_data(morph1DoutData),
		.dout_valid(morph1DoutValid));

	logic morph2DoutReady;  
	logic morph2DoutStart;
	logic [DATA_WIDTH-1:0] morph2DoutData;
	logic morph2DoutValid;
	morph_filter#( 
		.DATA_WIDTH(DATA_WIDTH),
		.MAX_IMAGE_WIDTH(MAX_IMAGE_WIDTH*2),
		.MAX_IMAGE_HEIGHT(MAX_IMAGE_HEIGHT))
	morph_filterInst2(
		.clk(clk),						
		.rst(rst),

		// 0 - Pass
		// 1 - Dilation(max from window)
		// 2 - Erosion (min from window)
		// 3 - Median Filtering(median from filter)
		.filter_type(param_filt2_type),
		.param_frame_width(paramFrameWidthX2),
	
	//ready latency  = 0
		.din_data(morph1DoutData),
		.din_sop(morph1DoutStart),
		.din_valid(morph1DoutValid),
		.din_ready(morph1DoutReady),

		.dout_ready(morph2DoutReady),
		.dout_sop(morph2DoutStart),
		.dout_data(morph2DoutData),
		.dout_valid(morph2DoutValid));


	//filter bypass
	bypass_loop#(
		.DATA_WIDTH(DATA_WIDTH))
	bypass_loopFilterInst(
		.bypass(~param_filt_ena),// 1'b0 : din=>loop_send; loop_ret=>dout, 1'b1 : din=>dout
	
		.din_sop(diffDoutStart),
		.din_data(diffDoutData),
		.din_valid(diffDoutValid),
		.din_ready(diffDoutReady),
	
		.dout_loop_send_ready(morph1DinReady),
		.dout_loop_send_sop(morph1DinStart),
		.dout_loop_send_data(morph1DinData),
		.dout_loop_send_valid(morph1DinValid),
	
		.din_loop_ret_sop(morph2DoutStart),
		.din_loop_ret_data(morph2DoutData),
		.din_loop_ret_valid(morph2DoutValid),
		.din_loop_ret_ready(morph2DoutReady),
	
		.dout_ready(dcmiDinReady),
		.dout_sop(dcmiDinStart),
		.dout_data(dcmiDinData),
		.dout_valid(dcmiDinValid));
	
	logic [DATA_WIDTH-1:0] dcmiDinData;
	logic dcmiDinStart;
	logic dcmiDinValid;
	logic dcmiDinReady;
		
	dcmi_out	#( 
		.DATA_WIDTH(DATA_WIDTH),
		.MAX_IMAGE_WIDTH(MAX_IMAGE_WIDTH*2),//MT9V034 max frame size x2
		.MAX_IMAGE_HEIGHT(MAX_IMAGE_HEIGHT),
		.VSYNC_ACTIVE_LEVEL(1),
		.HSYNC_ACTIVE_LEVEL(1))
	dcmi_out_inst (
		.clk(clk),						
		.rst(rst),
	
		.din_data(dcmiDinData),
		.din_sop(dcmiDinStart),
		.din_valid(dcmiDinValid),
		.din_ready(dcmiDinReady),	 
		
		
		.param_frame_width(paramFrameWidthX2),//x2
		.param_frame_height(param_frame_height),
	
		//clk_dcmi domain
		.clk_dcmi(clk_dcmi),						
		.dcmi_hsync(dcmi_hsync),	// line sync
		.dcmi_vsync(dcmi_vsync),	// frame sync
		.dcmi_data(dcmi_data));
		
	
endmodule
	
	
	