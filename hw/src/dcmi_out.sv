module dcmi_out	#( 
	parameter DATA_WIDTH = 8,
	parameter MAX_IMAGE_WIDTH = 1504,//MT9V034 max frame size x2
	parameter MAX_IMAGE_HEIGHT = 480,
	parameter VSYNC_ACTIVE_LEVEL = 0,
	parameter HSYNC_ACTIVE_LEVEL = 0)
	(
	input			clk,						
	input			rst,
	
	//ready latency = 1
	input [DATA_WIDTH-1:0]	din_data,
	input					din_sop,
	input					din_valid,
	output 					din_ready,
	
	input 	[$clog2(MAX_IMAGE_WIDTH)-1:0]	param_frame_width,
	input	[$clog2(MAX_IMAGE_HEIGHT)-1:0]	param_frame_height,
	
	//clk_dcmi domain
	input						clk_dcmi,						
	output 	reg					dcmi_hsync,	// line sync
	output 	reg					dcmi_vsync,	// frame sync
	output	[DATA_WIDTH-1:0]	dcmi_data
	);
		
assign din_ready = ~outFifoAlmostFull;
logic newFrameStart;
logic startFrameProducingClkSys; 
logic startFrameProducingClkSysDly1;//clock cross from clk_dcmi
always_ff @ (posedge clk, posedge rst)	begin
	if(rst) begin
		newFrameStart <= 1'b0;
		startFrameProducingClkSys <= 1'b0;
		startFrameProducingClkSysDly1 <= 1'b0;
	end	
	else begin
		startFrameProducingClkSys <= startFrameProducing;
		if(din_valid && din_ready && din_sop) begin
			newFrameStart <= 1'b1;
		end
		else if(startFrameProducingClkSys) begin
			newFrameStart <= 1'b0;
		end
	end		
end


logic outFifoFull;
logic outFifoAlmostFull;
logic outFifoWr;
assign outFifoWr = din_valid && ~outFifoFull;
logic outFifoRd;
logic [11:0] outFifoRdNum;
logic [8:0] outFifoQ; 
assign dcmi_data = outFifoQ[7:0];
//logic [10:0] outFifoWrNum;
assign outFifoRd = (activeReadArea || (state == READOUT_REMAIN && ~outFifoQ[8])) && ~outFifoEmpty;
logic outFifoEmpty;

dcmi_out_fifo_v2 dcmi_out_fifo_v2_inst(
	.Data({din_sop, din_data}),
	.Reset(rst),
	.WrClk(clk),
	.RdClk(clk_dcmi),
	.WrEn(din_valid),
	.RdEn(outFifoRd),
	.Wnum(),
	.Rnum(outFifoRdNum),
	.Q(outFifoQ),
	.Empty(outFifoEmpty),
	.Full(outFifoFull), 
	.Almost_Full(outFifoAlmostFull)
); 


//in clk_dcmi clock cycles	

//pass parameters to ouput clock domain
logic [$clog2(MAX_IMAGE_WIDTH):0] paramFrameWidthClkDcmi;
logic [$clog2(MAX_IMAGE_WIDTH):0] paramFrameHeightClkDcmi;
always_ff @ (posedge clk, posedge rst)	begin
	if(rst) begin
		paramFrameWidthClkDcmi <= 0;
		paramFrameHeightClkDcmi <= 0;
	end	
	else begin
		//using single stage resync, signals are stable dusing long time
		paramFrameWidthClkDcmi <= param_frame_width;
		paramFrameHeightClkDcmi <= param_frame_height;
	end		
end

//genate output sequence 
localparam FRAME_START_BLANKING = 71;
localparam FRAME_END_BLANKING = 23;
localparam HORIZONTAL_BLAKING_MIN = 10;//minimum blanking. Actual blanking will depend on data availability in fifo for whole line 
//vertical blanking will not fixed - frame will start on come new frame to input and pass to the end and wait new frame to input and so on


//logic [$clog2(MAX_IMAGE_WIDTH):0] pixCnt;  
//logic [$clog2(MAX_IMAGE_HEIGHT):0] lineCnt;
logic startFrameProducing;
logic activeReadArea;  //VSYNC_ACTIVE_LEVEL && HSYNC_ACTIVE_LEVEL
assign activeReadArea = (dcmi_vsync == VSYNC_ACTIVE_LEVEL) && (dcmi_hsync == HSYNC_ACTIVE_LEVEL);
logic fifoRdWordsEnough;
assign fifoRdWordsEnough = (outFifoRdNum >= paramFrameWidthClkDcmi) ? 1'b1 : 1'b0;

localparam OUT_FIFO_WORDS = 2048;
localparam OUT_FIFO_ALMOST_FULL_VALUE = OUT_FIFO_WORDS-100;
assign fifoRdWordsAlmostFull = outFifoRdNum > OUT_FIFO_ALMOST_FULL_VALUE;

typedef enum logic[5:0] {IDLE, START_BLANK, LINE, BLANK, END_BLANK, READOUT_REMAIN} state_t;
state_t state;
		
always @(posedge clk_dcmi or posedge rst) begin
	integer linesCnt;
	integer pixCnt;
	if(rst) begin
		state <= IDLE;
		linesCnt <= 0;
		pixCnt <= 0;
		dcmi_vsync <= ~VSYNC_ACTIVE_LEVEL;
		dcmi_hsync <= ~HSYNC_ACTIVE_LEVEL;
		startFrameProducing <= 1'b0;
	end
	else begin
		case(state)
			IDLE: begin
				if(newFrameStart && fifoRdWordsEnough) begin
					state <= START_BLANK; 
					dcmi_vsync <= VSYNC_ACTIVE_LEVEL; 
					startFrameProducing <= 1'b1;
				end
			end			
		
			START_BLANK: begin
				startFrameProducing <= 1'b0;
				if(pixCnt < (FRAME_START_BLANKING-1)) begin
					pixCnt <= pixCnt + 1;
				end
				else begin 
					pixCnt <= 0;
					state <= LINE;
					dcmi_hsync <= HSYNC_ACTIVE_LEVEL; 
				end			
			end
		
			LINE : begin 
				if(pixCnt < (paramFrameWidthClkDcmi-1)) begin
					pixCnt <= pixCnt + 1;
				end
				else begin 
					pixCnt <= 0; 
					linesCnt <= linesCnt + 1;
					dcmi_hsync <= ~HSYNC_ACTIVE_LEVEL;
					if(linesCnt >= (paramFrameHeightClkDcmi-1)) begin
						state <= END_BLANK;
					end
					else begin
						state <=  BLANK;
					end
				end	
			end
			
			BLANK : begin
				if(pixCnt < HORIZONTAL_BLAKING_MIN) begin
					pixCnt <= pixCnt + 1;
				end
				
				if(fifoRdWordsEnough && pixCnt >=  HORIZONTAL_BLAKING_MIN) begin
					state <= LINE;
					pixCnt <= 0;
					dcmi_hsync <= HSYNC_ACTIVE_LEVEL;
				end
			end
			
			END_BLANK : begin
				if(pixCnt < END_BLANK) begin
					pixCnt <= pixCnt + 1;
				end
				else begin
					state <= READOUT_REMAIN;//to process wring frames
					pixCnt <= 0; 
					linesCnt <= 0;
					dcmi_hsync <= ~HSYNC_ACTIVE_LEVEL;
					dcmi_vsync <= ~VSYNC_ACTIVE_LEVEL;
				end
			end
			
			READOUT_REMAIN : begin
				if(outFifoQ[8]) begin
					state <= IDLE;
				end
			end
		endcase
	end
end


endmodule