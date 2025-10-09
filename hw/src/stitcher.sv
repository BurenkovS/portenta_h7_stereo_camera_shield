module 	stitcher #(
	parameter DATA_WIDTH = 8,
	parameter MAX_INPUT_WIDTH = 640,
	parameter MAX_INPUT_HEIGHT = 480)

(
	input 		clk,
	input		rst,
	
	//ready latency  = 0
	input					din1_sop,
	input [DATA_WIDTH-1:0]	din1_data,
	input					din1_valid,
	output					din1_ready,

	input					din2_sop,
	input [DATA_WIDTH-1:0]	din2_data,
	input					din2_valid,
	output					din2_ready,

	input					dout_ready,
	output 					dout_sop,
	output [DATA_WIDTH-1:0]	dout_data,
	output					dout_valid,
	
	input 	[9:0]	param_frame_width,//input width. output frame will have x2 width
	input	[8:0]	param_frame_height);
	
	assign din1_ready = 1'b1;
	assign din2_ready = 1'b1;	
	
	//latch parameters on mt1 sop 
	logic [9:0]paramFrameWidthLatch;
	logic [10:0]paramFrameWidthX2Latch;
	logic [8:0]	paramFrameHeightLatch; 
	logic paramsLatched;
	
	always_ff @(posedge clk, posedge rst)	begin : paramsLatch 
		if(rst) begin
			paramFrameWidthX2Latch <= 0; 
			paramFrameWidthLatch <= 0; 
			paramFrameHeightLatch <= 0;	
			paramsLatched <= 1'b0;
		end
		else begin
			if (din1_valid && din1_ready && din1_sop) begin
				paramFrameWidthLatch <= param_frame_width;//need to know double width 
				paramFrameWidthX2Latch <= param_frame_width << 1;//need to know double width 
				paramFrameHeightLatch <= param_frame_height;
				paramsLatched <= 1'b1;
			end
			else if(state == EOF) begin
				paramsLatched <= 1'b0;
			end
		end
	end
	
	typedef enum logic[3:0] {IDLE, CHECK_LOCKED, PASS_MT1, PASS_MT2, WAIT_READ_DONE, EOF} state_t;

	logic [$clog2(MAX_INPUT_WIDTH)-1:0] interLineCnt;
	logic [$clog2(MAX_INPUT_HEIGHT):0] interPixCnt;
	
	state_t state;
 	always_ff @ (posedge clk, posedge rst)	begin : controlSm
		if(rst) begin
  			state   <= IDLE;
		end	
		
		else begin
			case(state)
				IDLE: begin
					//state <= PASS_MT1;
					interLineCnt <= 0;  
					interPixCnt <= 0;
					if(paramsLatched) begin
						state <= PASS_MT1;
					end
				end
				
				PASS_MT1: begin
					if(cam1FifoRd) begin
						interPixCnt <= interPixCnt + 1;
						if(interPixCnt == (paramFrameWidthLatch-1)) begin
							interPixCnt <= 0;
							state <= PASS_MT2;
						end
					end
				end

				
				PASS_MT2: begin
					if(cam2FifoRd) begin
						interPixCnt <= interPixCnt + 1;
						if(interPixCnt == (paramFrameWidthLatch-1)) begin
							interPixCnt <= 0;
							if(interLineCnt < (paramFrameHeightLatch-1)) begin
								interLineCnt <= interLineCnt + 1;
								state <= PASS_MT1;
							end
							else begin
								interLineCnt <= 0;
								state <= WAIT_READ_DONE;
							end
						end	
					end
				end
				
				WAIT_READ_DONE: begin
					if(collectorFifoEmpty) begin
						state <= EOF;
					end
				end
				
				EOF: begin
					state <= IDLE;
				end

				
				default : ;
				
			endcase
		end
	end

	
	logic cam1FifoEmpty;
	logic [7:0] cam1FifoQ;
	logic cam2FifoEmpty;
	logic [7:0] cam2FifoQ;

 	logic collectorFifoFull;
	logic cam1FifoRd;
	assign cam1FifoRd = ~cam1FifoEmpty && ~collectorFifoFull && state == PASS_MT1; 
	logic cam2FifoRd;
	assign cam2FifoRd = ~cam2FifoEmpty && ~collectorFifoFull && state == PASS_MT2; 
	
	cam_line_fifo cam1_line_fifo_inst(
		.Data(din1_data),
		.Reset(rst), 
		.WrClk(clk), 
		.RdClk(clk), 
		.WrEn(din1_valid), 
		.RdEn(cam1FifoRd), 
		.Q(cam1FifoQ), 
		.Empty(cam1FifoEmpty), 
		.Full()
	);	


	cam_line_fifo cam2_line_fifo_inst(
		.Data(din2_data),
		.Reset(rst), 
		.WrClk(clk), 
		.RdClk(clk), 
		.WrEn(din2_valid), 
		.RdEn(cam2FifoRd), 
		.Q(cam2FifoQ), 
		.Empty(cam2FifoEmpty), 
		.Full()
	);	


	logic [7:0] collectorFifoData;
	assign collectorFifoData = (state == PASS_MT1) ? cam1FifoQ : cam2FifoQ;	
	
	logic collectorFifoWr;
	assign collectorFifoWr = ~collectorFifoFull && (
							(state == PASS_MT1) ? ~cam1FifoEmpty : 
							(state == PASS_MT2) ? ~cam2FifoEmpty : 1'b0); 
				
	logic collectorFifoEmpty;
	assign dout_valid = ~collectorFifoEmpty;
	
	logic collectorFifoRd;
	assign collectorFifoRd = ~collectorFifoEmpty && dout_ready;
	logic [10:0] collectorFifoRnum;
	collected_fifo collected_fifo_inst( 
		.Data(collectorFifoData),
		.Reset(rst),
		.WrClk(clk),
		.RdClk(clk),
		.WrEn(collectorFifoWr),
		.RdEn(collectorFifoRd),
		.Rnum(collectorFifoRnum),
		.Q(dout_data),
		.Empty(collectorFifoEmpty),
		.Full(collectorFifoFull)
	); 
	
	
	logic [$clog2(MAX_INPUT_WIDTH*2):0] outPixCnt;  
	logic [$clog2(MAX_INPUT_HEIGHT):0] outLineCnt;
	always_ff @ (posedge clk, posedge rst)	begin : sopGen
		if(rst) begin
			outPixCnt  <= 0;
			outLineCnt  <= 0;
		end	
		else begin
			if(collectorFifoRd) begin
				outPixCnt <= outPixCnt + 1;
				if(outPixCnt >= paramFrameWidthX2Latch-1) begin
					outPixCnt <= 0;
					if(outLineCnt >= paramFrameHeightLatch-1) begin
						//dout_sop <= 1'b1;
						outLineCnt <= 0;
					end
					else begin
						outLineCnt <= outLineCnt + 1;
					end				
				end
			end
			else if(state == EOF) begin
				outPixCnt  <= 0;
				outLineCnt  <= 0;
			end
			
		end
	end

	assign dout_sop = (outPixCnt == 0) && (outLineCnt == 0);
	
endmodule