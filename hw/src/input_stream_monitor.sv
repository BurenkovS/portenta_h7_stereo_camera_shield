module input_stream_monitor#(
	parameter MAX_IMAGE_WIDTH = 640,
	parameter MAX_IMAGE_HEIGHT = 480,
	parameter VSYNC_ACTIVE_LEVEL = 0,
	parameter HSYNC_ACTIVE_LEVEL = 0)
	(
	input 	rst,
	input	dcmi_pixclk,
	input   dcmi_hsync,
	input   dcmi_vsync,

	output 	reg [$clog2(MAX_IMAGE_WIDTH)-1:0]	param_frame_width,
	output	reg [$clog2(MAX_IMAGE_HEIGHT)-1:0]	param_frame_height,	
	
	output	reg 	locked, //'1' it last frame have same number of pixels in every line and integer number of lines
	//output	reg 	stable, //'1' it last 3 lines have same number of pixels
	output	reg		sof	//detect start of frame issue on input bus
);

	logic [$clog2(MAX_IMAGE_WIDTH)-1:0]	pixCnt;
	logic [$clog2(MAX_IMAGE_HEIGHT)-1:0] lineCnt; 
	logic vSyncDly1;
	logic hSyncDly1;
	always @(posedge dcmi_pixclk, posedge rst) begin
		logic [$clog2(MAX_IMAGE_WIDTH)-1:0] pixelInLineRef;
		logic [$clog2(MAX_IMAGE_HEIGHT)-1:0] expectedLenghtLinesCnt; 
		if(rst) begin
			//stable <= 1'b0;
			locked <= 1'b0;
			vSyncDly1 <= 1'b0; 
			hSyncDly1 <= 1'b0;
			pixCnt <= 0;
			lineCnt <= 0;
			pixelInLineRef <= 0;
			expectedLenghtLinesCnt <= 0;
			param_frame_width <= 0;
			param_frame_height <= 0;
		end
		else begin
			vSyncDly1 <= dcmi_vsync; 
			hSyncDly1 <= dcmi_hsync;
			if(dcmi_vsync == VSYNC_ACTIVE_LEVEL) begin
				if(hSyncDly1 == HSYNC_ACTIVE_LEVEL && dcmi_hsync != HSYNC_ACTIVE_LEVEL) begin
					pixCnt <= 0;
					lineCnt <= lineCnt + 1;
					if(lineCnt == 0) begin
						pixelInLineRef <= pixCnt;
					end
					else begin
						if(pixelInLineRef == pixCnt) begin
							expectedLenghtLinesCnt <= expectedLenghtLinesCnt + 1;
						end
					end
				end
				else if(dcmi_hsync == HSYNC_ACTIVE_LEVEL)begin
					pixCnt <= pixCnt + 1;
				end
			end
			//check frame size at the end of frame
			if(vSyncDly1 == VSYNC_ACTIVE_LEVEL && dcmi_vsync != VSYNC_ACTIVE_LEVEL) begin
				if(expectedLenghtLinesCnt == (lineCnt-1) && pixCnt == 0) begin//last frame have same number of pixels in every line and integer number of lines
					locked <= 1'b1;
					param_frame_width <= pixelInLineRef; 
					param_frame_height <= lineCnt; 
				end
                else begin
                    locked <= 1'b0;
                end
				lineCnt <= 0;
				expectedLenghtLinesCnt <= 0;
			end
		end
	end			  
   
	
	//generate SOF
	always @(posedge dcmi_pixclk, posedge rst) begin
		if(rst) begin
			sof <= 1'b0;
		end
		else begin
			if(dcmi_vsync == VSYNC_ACTIVE_LEVEL && vSyncDly1 != VSYNC_ACTIVE_LEVEL) begin
				sof <= 1'b1;
			end
			else if(sof == 1'b1 && dcmi_hsync == HSYNC_ACTIVE_LEVEL) begin //reset SOF an first active pixel
				sof <= 1'b0;
			end
		end
	end
	
endmodule