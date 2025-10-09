// Receive data from image sensor
// dcmi receive block - accepts everything that comes, does not count pixels

// frame start is detected by the edge of the corresponding blanking pulse

// Attention! Starts issuing without waiting for the start of the frame - these checks must be carried out on next steps.

//

// WARNING: The frame start pulse is output at the same time as the first data word

//

module dcmi_receiver#(
	parameter MAX_IMAGE_WIDTH = 752,//MT9V034 max frame size
	parameter MAX_IMAGE_HEIGHT = 480,
	parameter VSYNC_ACTIVE_LEVEL = 0,
	parameter HSYNC_ACTIVE_LEVEL = 0)
(
	input sys_clk,
	input rst,
	
	//ready latency 0
	output 	[13:0]  rcvd_data,
	output			rcvd_frame_start,//SOP
	output 	reg		rcvd_dvalid,
	
//	output  reg			bad_frame_error  ,	//rised if the size of the received frame does not match the given one. Checked at the end of each line
	//output	reg 		locked, //synced with frame_start signal. Rise if previous frames have expected dimensions
	input			dcmi_pixclk ,
	input       	dcmi_hsync	,
	input       	dcmi_vsync	,
	input	[13:0]  dcmi_data	,
		
	input 	[9:0]	param_frame_width	,						// параметры от блока управления
	input	[8:0]	param_frame_height	
);

wire 			in_fifo_rdempty;

reg 	[9:0]	loc_param_frame_width;							// внутренние переменные - что бы менять только по началу кадра
reg		[8:0]	loc_param_frame_height;	


/*(* noprune *) 	reg		[22:0] 		rd_samples_cntr;

always @(posedge sys_clk or posedge rst)
begin
	if(rst) begin
		rd_samples_cntr	<= 0;
	end
	else begin
		if (rcvd_frame_start) begin
			rd_samples_cntr	<= 0;
		end
		if (~in_fifo_rdempty) begin
			rd_samples_cntr 	<= rd_samples_cntr + 1;
		end
	end
end*/

//dbg!
reg [7:0] cnt;
always @(posedge dcmi_pixclk or posedge rst)
begin
	if(rst) begin
		cnt	<= 0;  
	end
	else begin
		if (dcmi_hsync == HSYNC_ACTIVE_LEVEL && dcmi_vsync == VSYNC_ACTIVE_LEVEL) begin
			if(sof)
				cnt <= 0;								
			else
				cnt <= cnt + 1;
		end
	end
end	


always @(posedge sys_clk or posedge rst)
begin
	if(rst) begin
		loc_param_frame_height	<= 0;  
		loc_param_frame_width <= 0;
	end
	else begin
		if (rcvd_frame_start) begin
			loc_param_frame_width <= param_frame_width;								// установка значений параметров - покадрово
			loc_param_frame_height <= param_frame_height;
		end
	end
end	

wire sof;
wire fifoWr;
assign fifoWr = frameSizeMatched && dcmi_hsync == HSYNC_ACTIVE_LEVEL && dcmi_vsync == VSYNC_ACTIVE_LEVEL;
wire [15:0] fifoQ;	
assign rcvd_frame_start = fifoQ[14];
assign rcvd_data = fifoQ[13:0];
dcmi_in_fifo dcmi_in_fifo_inst(
	.Data       ({1'b0, sof, /*6'b0, cnt*/dcmi_data}), //input [15:0] Data
	.WrClk      (dcmi_pixclk), //input WrClk
	.RdClk      (sys_clk), //input RdClk
	.Reset		(rst),
	.WrEn       (fifoWr), //input WrEn
	.RdEn       (~in_fifo_rdempty), //input RdEn
	.Q          (fifoQ), //output [15:0] Q
	.Empty      (in_fifo_rdempty), //output Empty
	.Full       () //output Full
); 

//delay dvalid to compensate register on fifo output
always @(posedge sys_clk or posedge rst)
begin
	if(rst) begin
		rcvd_dvalid	<= 1'b0;  
	end
	else begin
		rcvd_dvalid	<= ~in_fifo_rdempty; 	
	end
end	


//monitor input signal
logic frameLocked;
logic frameSizeMatched;
logic [$clog2(MAX_IMAGE_WIDTH)-1:0]		paramFrameWidth;
logic [$clog2(MAX_IMAGE_HEIGHT)-1:0]	paramFrameHeight;	
	
input_stream_monitor#(
	.MAX_IMAGE_WIDTH(MAX_IMAGE_WIDTH),
	.MAX_IMAGE_HEIGHT(MAX_IMAGE_HEIGHT),
	.VSYNC_ACTIVE_LEVEL(VSYNC_ACTIVE_LEVEL),
	.HSYNC_ACTIVE_LEVEL(HSYNC_ACTIVE_LEVEL))
inputStreamMonitorInst(
	.rst(rst),
	.dcmi_pixclk(dcmi_pixclk),
	.dcmi_hsync(dcmi_hsync),
	.dcmi_vsync(dcmi_vsync),
	.param_frame_width(paramFrameWidth),
	.param_frame_height(paramFrameHeight),	
	.locked(frameLocked),
	.sof(sof));

always @(posedge dcmi_pixclk or posedge rst)
begin
	if(rst) begin
		frameSizeMatched <= 1'b0;
	end
	else begin
		if (frameLocked && paramFrameWidth == param_frame_width && paramFrameHeight == param_frame_height) begin
			frameSizeMatched <= 1'b1;
		end
		else begin
			frameSizeMatched <= 1'b0;
		end		
	end
end	


endmodule