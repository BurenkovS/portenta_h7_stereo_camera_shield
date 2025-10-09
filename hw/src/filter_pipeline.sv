//actept row of 3 pixels
module filter_pipeline	#( 
	parameter DATA_WIDTH = 8)
	(
	input			clk,						
	input			rst,

	// 0 - Pass
	// 1 - Dilation(max from window)
	// 2 - Erosion (min from window)
	// 3 - Median Filtering(median from filter)
	input	[1:0]	filter_type,
	
	input [DATA_WIDTH-1:0]	din_data_line1, 
	input [DATA_WIDTH-1:0]	din_data_line2, 
	input [DATA_WIDTH-1:0]	din_data_line3, 
	input					din_valid,

	output reg [DATA_WIDTH-1:0]	dout_data,
	output reg					dout_valid
); 

	logic [DATA_WIDTH-1:0] sortSt1;
	sort_3values_pipeline sort_3values_pipeStage1Inst( 
		.clk(clk),
		.rst(rst),
		.filter_type(filter_type),
	    .a(din_data_line1),
		.b(din_data_line2),
		.c(din_data_line3),
	    .out(sortSt1)
	);
	
	logic [DATA_WIDTH-1:0] sortSt2;
	sort_3values_pipeline sort_3values_pipeStage2Inst(
		.clk(clk),
		.rst(rst),
		.filter_type(filter_type),
	    .a(muxOut[0]),
		.b(muxOut[1]),
		.c(muxOut[2]),
	    .out(sortSt2)
	);

	
	logic [DATA_WIDTH-1:0] muxOut[0:2];
	logic din_validDly1; 
	logic din_validDly2;
	logic din_validDly3;

	always @(posedge clk or posedge rst) begin
		if(rst) begin
			foreach (muxOut[i]) begin
	            muxOut[i] <=  0;
	        end
			din_validDly1 <= 1'b0;
			din_validDly2 <= 1'b0;
			din_validDly3 <= 1'b0;
			dout_valid = 0; 
			dout_data <= 0;
		end
		else begin
			din_validDly1 <= din_valid;
			din_validDly2 <= din_validDly1;
			din_validDly3 <= din_validDly2;
			dout_valid <= din_validDly3; 

			
			if(din_validDly2) begin
				muxOut[0] <= sortSt1;  
				muxOut[1] <= muxOut[0];	
				muxOut[2] <= muxOut[1];
			end
			if(din_validDly3) begin
				dout_data <= sortSt2;	
			end
		end
	end
	

endmodule

//have 1 pipeline latency
module sort_3values_pipeline (
	
	input			clk,						
	input			rst,
	
	// 0 - Pass
	// 1 - Dilation(max from window)
	// 2 - Erosion (min from window)
	// 3 - Median Filtering(median from filter)
	input	[1:0]	filter_type,
	
    input [7:0] a,
	input [7:0] b,//center value
	input [7:0] c,
	
	output [7:0] out
);

    logic [7:0] muxA1Min;
	logic [7:0] muxA1Max;
    logic [7:0] muxB1Min;
	logic [7:0] muxB1Max;

    logic [7:0] muxA2Min;
	logic [7:0] muxA2Max;
    logic [7:0] muxB2Min;
	logic [7:0] muxB2Max;

    logic [7:0] muxA1MinLatch;
	logic [7:0] muxA1MaxLatch;
    logic [7:0] muxB1MinLatch;
	logic [7:0] muxB1MaxLatch;

    logic [7:0] muxA2MinLatch;
	logic [7:0] muxA2MaxLatch;
    logic [7:0] muxB2MinLatch;
	logic [7:0] muxB2MaxLatch;
	
	logic [7:0] bValDly1;
	logic [7:0] bValDly2;
	
	
	sort_2values_comb sort_2values_combSt1A(
    	.a(a),
		.b(b),
	
		.min(muxA1Min),
		.max(muxA1Max));	  
		
	sort_2values_comb sort_2values_combSt1B(
    	.a(b),
		.b(c),
	
		.min(muxB1Min),
		.max(muxB1Max));

	sort_2values_comb sort_2values_combSt2A(
    	.a(muxA1MaxLatch),
		.b(muxB1MaxLatch),
	
		.min(muxA2Min),
		.max(muxA2Max));	  
		
	sort_2values_comb sort_2values_combSt2B(
    	.a(muxA1MinLatch),
		.b(muxB1MinLatch),
	
		.min(muxB2Min),
		.max(muxB2Max));
		
	always @(posedge clk or posedge rst) begin
		if(rst) begin
			muxA1MinLatch <= 0;
			muxA1MaxLatch <= 0;
		    muxB1MinLatch <= 0;		 
			muxB1MaxLatch <= 0;
		
		    muxA2MinLatch <= 0;
			muxA2MaxLatch <= 0;
		    muxB2MinLatch <= 0;
			muxB2MaxLatch <= 0;
			
			bValDly1 <= 0;
			bValDly2 <= 0;
		end
		else begin
			muxA1MinLatch <= muxA1Min;
			muxA1MaxLatch <= muxA1Max;
		    muxB1MinLatch <= muxB1Min;
			muxB1MaxLatch <= muxB1Max;
		
		    muxA2MinLatch <= muxA2Min;
			muxA2MaxLatch <= muxA2Max;
		    muxB2MinLatch <= muxB2Min;
			muxB2MaxLatch <= muxB2Max;
			
			bValDly1 <= b;
			bValDly2 <= bValDly1;
		end
	end
	
    assign out = (filter_type == 2'b01) ? muxA2MaxLatch : 
					(filter_type == 2'b10) ? muxB2MinLatch : 
					(filter_type == 2'b11) ? muxB2MaxLatch/* or muxA2MinLatch*/ : bValDly2;//if 00 - return center value 	
	
endmodule


module sort_2values_comb (
	
    input [7:0] a,
	input [7:0] b,
	
	output [7:0] min,
	output [7:0] max
);				
	logic agb;
	assign agb = a > b ? 1'b1 : 1'b0; 
	assign min = agb ? b : a;
	assign max = agb ? a : b;
	
endmodule

