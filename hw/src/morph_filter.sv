module morph_filter	#( 
	parameter DATA_WIDTH = 8,
	parameter MAX_IMAGE_WIDTH = 1504,//MT9V034 max frame size x2
	parameter MAX_IMAGE_HEIGHT = 480)
	(
	input			clk,						
	input			rst,

	// 0 - Pass
	// 1 - Dilation(max from window)
	// 2 - Erosion (min from window)
	// 3 - Median Filtering(median from filter)
	input	[1:0]	filter_type,
	input 	[$clog2(MAX_IMAGE_WIDTH)-1:0]	param_frame_width,
	
	//ready latency  = 0
	input					din_sop,
	input [DATA_WIDTH-1:0]	din_data,
	input					din_valid,
	output					din_ready,

	input					dout_ready,
	output 					dout_sop,
	output [DATA_WIDTH-1:0]	dout_data,
	output					dout_valid
);

	logic outFifoAlmostFull;
	assign din_ready = ~outFifoAlmostFull;
	logic [DATA_WIDTH-1:0] tap1;
	logic [DATA_WIDTH-1:0] tap2; 
	ram_based_shift_reg	#( 
		.DATA_WIDTH(DATA_WIDTH),
		.MAX_LENGHT(MAX_IMAGE_WIDTH))
	ramBasedShiftRegTap1Inst(
		.clk(clk),						
		.rst(rst),
	
		.shift_lenght(param_frame_width),
		
		.we(din_valid && din_ready),
		.din(din_data),
		.dout_valid(tap1Valid),
		.dout(tap1)
	);
	
	ram_based_shift_reg	#( 
		.DATA_WIDTH(DATA_WIDTH),
		.MAX_LENGHT(MAX_IMAGE_WIDTH))
	ramBasedShiftRegTap2Inst(
		.clk(clk),						
		.rst(rst),
	
		.shift_lenght(param_frame_width),
		
		.we(tap1Valid),
		.din(tap1),
		.dout_valid(tap2Valid),
		.dout(tap2)
	);	
	
	logic [DATA_WIDTH-1:0] dinDataLatch;
	logic [DATA_WIDTH-1:0] dinDataLatchDly1;
	logic [DATA_WIDTH-1:0] dinDataLatchDly2;
	logic [DATA_WIDTH-1:0] dinDataLatchDly3;

	logic [DATA_WIDTH-1:0] tap1Latch;	
	logic [DATA_WIDTH-1:0] tap1LatchDly1;
	logic [DATA_WIDTH-1:0] tap1LatchDly2;
	
	logic [DATA_WIDTH-1:0] scanRow[0:2];//single row 
	logic scanRowValid;
	always @(posedge clk or posedge rst) begin
		if(rst) begin
			dinDataLatch <= 0;
			dinDataLatchDly1 <= 0; 
			dinDataLatchDly2 <= 0;
			dinDataLatchDly3 <= 0;
			
			tap1LatchDly1 <= 0;	
			tap1LatchDly2 <= 0;	
			tap1Latch <= 0;	 
			scanRowValid <= 1'b0; 
	        foreach (scanRow[i]) begin
	            scanRow[i] <= 'hFF;
	        end
		end
		else begin
			tap1LatchDly1 <= tap1;
			tap1LatchDly2 <= tap1LatchDly1;
			dinDataLatchDly1 <= dinDataLatch;
			dinDataLatchDly2 <= dinDataLatchDly1;
			dinDataLatchDly3 <= dinDataLatchDly2;
			
			if(din_valid && din_ready) begin
				dinDataLatch <=	din_data;
			end	
			
			if(tap1Valid) begin
				tap1Latch <= tap1;
			end
			
			if(tap2Valid) begin
				scanRow[0] <= dinDataLatchDly3;
				scanRow[1] <= tap1LatchDly2;
				scanRow[2] <= tap2;
			end
			scanRowValid <= tap2Valid;
		end
	end

	logic [DATA_WIDTH-1:0] filterDoutData;
	logic filterDoutValid;
	filter_pipeline	#( 
		.DATA_WIDTH(8))
	filter_pipelineInst(
		.clk(clk),						
		.rst(rst),

		.filter_type(filter_type),
	
		.din_data_line1(scanRow[0]), 
		.din_data_line2(scanRow[1]), 
		.din_data_line3(scanRow[2]), 
		.din_valid(scanRowValid),

		.dout_data(filterDoutData),
		.dout_valid(filterDoutValid)
		);

	//compensate pipeline length
	logic sopDly;
	DelayLine #(
		.WIDTH(1),
		.LENGTH(9))
	DelayLineSopDly(
		.clk(clk),
		.reset(rst),
		.din(din_sop),
		.dout(sopDly)
	);
	
	
	logic outFifoEmpty;
	logic outFifoRdEn;
	assign outFifoRdEn = ~outFifoEmpty && dout_ready; 
	logic  [DATA_WIDTH:0] outFifoQ;
	small_pipe_comp_fifo small_pipe_comp_fifoInst(
		.Data({sopDly, filterDoutData}), //input [8:0] Data
		.Clk(clk), //input Clk
		.WrEn(filterDoutValid), //input WrEn
		.RdEn(outFifoRdEn), //input RdEn
		.Reset(rst), //input Reset
		.Almost_Empty(), //output Almost_Empty
		.Almost_Full(outFifoAlmostFull), //output Almost_Full
		.Q(outFifoQ), //output [8:0] Q
		.Empty(outFifoEmpty), //output Empty
		.Full() //output Full
	);
	
	assign dout_sop = outFifoQ[DATA_WIDTH]; 
	assign dout_data = outFifoQ[DATA_WIDTH-1:0];
	assign dout_valid = ~outFifoEmpty;
	

endmodule 
