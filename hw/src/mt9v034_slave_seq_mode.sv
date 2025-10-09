//generate EXPOSURE, STLN_OUT and STFRM_OUT signals to control mt9v034 in slave sequential mode  
module mt9v034_slave_seq_mode 
	#( 
	parameter MAX_IMAGE_WIDTH = 752,
	parameter MAX_IMAGE_HEIGHT = 480, 
	
	parameter IMAGE_WIDTH_DEFAULT = 640,
	parameter IMAGE_HEIGHT_DEFAULT = 480,
	
	parameter EXP_DEFAULT = 'h00030B00,
	parameter VSYNC_ACTIVE_LEVEL = 1,
	parameter HSYNC_ACTIVE_LEVEL = 1,
	parameter VERTICAL_BLANK = 4,//shold be same as in reg 0x06 in mt9v034
	parameter HORIZONTAL_BLANK = 94//shold be same as in reg 0x05 in mt9v034
	)
	(
	input logic	reset,
	input logic	mt9v034_sysclk,//master clock from fpga to sensor (26.6 MHz; 13 MHz – 27 MHz). used as system clock for this block
    input ena,
	
	//async signals related to mt9v034_sysclk. need to resync to mt9v034_sysclk
	//from control logic 
	input logic [23:0] integration_time,//integration time calculates by external module. In mt9v034_sysclk ticks 	
	input logic [$clog2(MAX_IMAGE_WIDTH)-1:0] frame_width,//active frame width
	input logic [$clog2(MAX_IMAGE_HEIGHT)-1:0] frame_height,//active frame height

	//async signals related to mt9v034_sysclk. need to resync to mt9v034_sysclk
	//from one of sensor. Assumed both sensors produce same signals
	input logic v_sync,
	input logic h_sync,

	
	//mt9v034_sysclk clock domain
	output logic exposure,
	output logic stln_out,
	output logic stfrm_out);
	
	//some timing parameters for generation
	localparam EXP_PULSE_LENGHT = 10; 
	localparam FRM_LN_PULSE_LENGHT = 10;
    //The MT9V034 uses column parallel analog-digital converters; thus short row timing is not possible.
    //The minimum total row time is 704 columns (horizontal width + horizontal blanking).    
    localparam ROW_TIME = 735+FRM_LN_PULSE_LENGHT;
	localparam FRAME_END_BLANKING_TIME = 23;//constant according datasheet 
	localparam FRAME_START_BLANKING_TIME = ROW_TIME;/*-FRAME_END_BLANKING_TIME*/;
	
	localparam IMAGE_WIDTH_DEFAULT_WITH_BLANK = IMAGE_WIDTH_DEFAULT + HORIZONTAL_BLANK - 1;
	localparam IMAGE_HEIGHT_DEFAULT_WITH_BLANK = IMAGE_HEIGHT_DEFAULT + VERTICAL_BLANK - 1;
	
	//pass mesesarry signals to internal clock domain
	// parameters latch after current frame end	
	logic [31:0]  integrationTime;	
	//logic [$clog2(MAX_IMAGE_WIDTH):0] frameWidthWithBlank;
	logic [$clog2(MAX_IMAGE_HEIGHT)+1:0] frameHeightWithBlank;
	logic vSync;
	logic hSync;
	always_ff @(posedge mt9v034_sysclk, posedge reset) begin : resync
		logic v_syncDly1;
		logic h_syncDly1;
		if(reset) begin	
			integrationTime <= EXP_DEFAULT;	
			//frameWidthWithBlank <= IMAGE_WIDTH_DEFAULT_WITH_BLANK;
			frameHeightWithBlank <= IMAGE_HEIGHT_DEFAULT_WITH_BLANK;
			v_syncDly1 <= 1'b0;
			h_syncDly1 <= 1'b0;
			vSync <= 1'b0;
			hSync <= 1'b0;
		end
		else begin
		 	v_syncDly1 <= v_sync;//reduce metastabiliy
			h_syncDly1 <= h_sync;
			vSync <= v_syncDly1;
			hSync <= h_syncDly1;
			if(state == LATCH_CONTEXT) begin 
				integrationTime <= integration_time;	
				//frameWidthWithBlank <= frame_width + HORIZONTAL_BLANK - 1;//-1 to prepare to comparsion 
				frameHeightWithBlank <= frame_height + VERTICAL_BLANK - 1;
			end
		end
	end
	

	typedef enum logic[3:0] {IDLE, LATCH_CONTEXT, EXP_START, EXP_WAIT, FRAME_START, FRAME_START_BLANKING, CHECK_HSYNC, START_LINE, WAIT_LINE, FRAME_END_BLANKING} control_state_t;
	control_state_t state;
	logic [$clog2(MAX_IMAGE_WIDTH):0] pixCnt;
	logic [$clog2(MAX_IMAGE_HEIGHT):0] lineCnt;
	logic [23:0] integrationCntExposure; 
	
	always_ff @(posedge mt9v034_sysclk, posedge reset) begin : stfrm_sm
		logic [7:0] srvsCnt;
		if(reset) begin	
			state <= IDLE;	
			srvsCnt <= 0; 
			pixCnt <= 0; 
			lineCnt <= 0; 
			integrationCntExposure <= 0;  
			stfrm_out <= 1'b0;
			stln_out <= 1'b0;
			exposure <= 1'b0; 
		end	
		else begin
			case(state)
				IDLE : begin
					stfrm_out <= 1'b0;
					stln_out <= 1'b0;
					exposure <= 1'b0;
					if(ena) begin
						state <= LATCH_CONTEXT;
					end
				end

				LATCH_CONTEXT : begin
					state <= EXP_START; 
				end
				
				EXP_START : begin
					exposure <= 1'b1;
					srvsCnt <= srvsCnt + 1;
					if(srvsCnt == (EXP_PULSE_LENGHT-1))	begin 
						state <= EXP_WAIT;
						srvsCnt <= 0;  
						exposure <= 1'b0;
					end
				end	
				
				EXP_WAIT : begin
					integrationCntExposure <= integrationCntExposure + 1;
					if(integrationCntExposure == integrationTime) begin
						integrationCntExposure <= 0;
						state <= FRAME_START;
					end
				end

                FRAME_START : begin
                    //For proper operation, STFRM_OUT HIGH state should be limited to one master clock cycle only
 					stfrm_out <= 1'b1;
					//srvsCnt <= srvsCnt + 1;
					//if(srvsCnt == (FRM_LN_PULSE_LENGHT-1)) begin	 
						state <= FRAME_START_BLANKING;
					//	srvsCnt <= 0;  
					//	stfrm_out <= 1'b0;
					//end
				end
				
				FRAME_START_BLANKING : begin
                    stfrm_out <= 1'b0; 
					pixCnt <= pixCnt + 1;
					if(pixCnt ==  FRAME_START_BLANKING_TIME-1) begin
						pixCnt <= 0;
						state <= CHECK_HSYNC;
					end
				end

                CHECK_HSYNC : begin
                    if(hSync != HSYNC_ACTIVE_LEVEL) begin
                        state <=  START_LINE;
                    end
                end
				
				START_LINE : begin
 					stln_out <= 1'b1;
					srvsCnt <= srvsCnt + 1;
					if(srvsCnt == (FRM_LN_PULSE_LENGHT-1)) begin	 
						state <= WAIT_LINE;
						srvsCnt <= 0;  
						stln_out <= 1'b0;
					end					
				end
				
				WAIT_LINE : begin
					pixCnt <= pixCnt + 1;
					if(pixCnt >= /*frameWidthWithBlank*/ROW_TIME)  begin
						pixCnt <= 0;
						lineCnt <= lineCnt + 1;
						if((lineCnt >= frameHeightWithBlank) && (vSync != VSYNC_ACTIVE_LEVEL)) begin
							lineCnt <= 0;	
							state <= FRAME_END_BLANKING;
						end
						else begin
							state <= CHECK_HSYNC;
						end
					end							
				end

                FRAME_END_BLANKING : begin
                    if(vSync != VSYNC_ACTIVE_LEVEL) begin
                        state <= IDLE;
                    end
                end
				
			
				default: state <= IDLE;
			endcase
		end
	end	
	
	endmodule