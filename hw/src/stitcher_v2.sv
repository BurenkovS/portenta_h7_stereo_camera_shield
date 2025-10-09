//simplified stitcher. Do not processed frame height, stich line by line, and insert SOP from din1 SOP
module 	stitcher_v2 #(
	parameter DATA_WIDTH = 8,
	parameter MAX_INPUT_WIDTH = 752,
    parameter IMAGE_WIDTH_DEFAULT = 640)

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
	
	input 	[9:0]	param_frame_width//input width. output frame will have x2 width
);
	
	assign din1_ready = 1'b1;
	assign din2_ready = 1'b1;	
	
	//latch parameters on mt1 sop 
	logic [$clog2(MAX_INPUT_WIDTH)-1:0]paramFrameWidthLatch;
	logic [$clog2(MAX_INPUT_WIDTH):0]paramFrameWidthX2Latch;
	logic paramsLatched;
	
	always_ff @(posedge clk, posedge rst)	begin : paramsLatch 
		if(rst) begin
			paramFrameWidthX2Latch <= IMAGE_WIDTH_DEFAULT*2; 
			paramFrameWidthLatch <= IMAGE_WIDTH_DEFAULT; 
			paramsLatched <= 1'b0;
		end
		else begin
			if (din1_valid && din1_ready && din1_sop) begin
				paramFrameWidthLatch <= param_frame_width;//need to know double width 
				paramFrameWidthX2Latch <= param_frame_width << 1;//need to know double width 
				paramsLatched <= 1'b1;
			end
		end
	end
	
	typedef enum logic[3:0] {IDLE, CHECK_LOCKED, PASS_MT1, PASS_MT2, WAIT_READ_DONE, EOF} state_t;

	//logic [$clog2(MAX_INPUT_WIDTH)-1:0] interLineCnt;
	logic [$clog2(MAX_INPUT_WIDTH):0] interPixCnt;
	
	state_t state;
 	always_ff @ (posedge clk, posedge rst)	begin : controlSm
		if(rst) begin
  			state <= IDLE;
	 		interPixCnt <= 0;
		end	
		
		else begin
			case(state)
				IDLE: begin
					state <= PASS_MT1;
				end
				
				PASS_MT1: begin			
					if(cam1FifoRd) begin
						if(cam1FifoQ[8]) begin
							interPixCnt <= 1;
						end
						else begin	
							interPixCnt <= interPixCnt + 1;
							if(interPixCnt >= (paramFrameWidthLatch-1)) begin
								interPixCnt <= 0;
								state <= PASS_MT2;
							end	
						end
					end
				end

				
				PASS_MT2: begin
					if(cam2FifoRd) begin
						interPixCnt <= interPixCnt + 1;
						if(interPixCnt >= (paramFrameWidthLatch-1)) begin
							interPixCnt <= 0;
							state <= PASS_MT1;
						end	
					end
				end
				
				default : ;
				
			endcase
		end
	end

	
	logic cam1FifoEmpty;
	logic [8:0] cam1FifoQ;
	logic cam2FifoEmpty;
	logic [8:0] cam2FifoQ;

 	logic collectorFifoFull;
	logic cam1FifoRd;
	assign cam1FifoRd = ~cam1FifoEmpty && ~collectorFifoFull && state == PASS_MT1; 
	logic cam2FifoRd;
	assign cam2FifoRd = ~cam2FifoEmpty && ~collectorFifoFull && state == PASS_MT2; 
	
	cam_line_fifo cam1_line_fifo_inst(
		.Data({din1_sop, din1_data}),
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
		.Data({1'b0, din2_data}),
		.Reset(rst), 
		.WrClk(clk), 
		.RdClk(clk), 
		.WrEn(din2_valid), 
		.RdEn(cam2FifoRd), 
		.Q(cam2FifoQ), 
		.Empty(cam2FifoEmpty), 
		.Full()
	);	


	logic [8:0] collectorFifoData;
	logic [8:0] collectorFifoQ;
	assign collectorFifoData = (state == PASS_MT1) ? cam1FifoQ : cam2FifoQ;	
	
	logic collectorFifoWr;
	assign collectorFifoWr = ~collectorFifoFull && (
							(state == PASS_MT1) ? ~cam1FifoEmpty : ~cam2FifoEmpty);
							//(state == PASS_MT2) ? ~cam2FifoEmpty : 1'b0); 
				
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
		.Q(collectorFifoQ),
		.Empty(collectorFifoEmpty),
		.Full(collectorFifoFull)
	); 
	


	assign dout_data = collectorFifoQ[7:0];
	assign dout_sop = collectorFifoQ[8];
	
endmodule
