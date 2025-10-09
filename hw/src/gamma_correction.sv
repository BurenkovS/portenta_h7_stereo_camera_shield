module gamma_correction	#( 
	parameter DATA_WIDTH = 8)
	(
	input			clk,						
	input			rst,

	input					din_sop,
	input [DATA_WIDTH-1:0]	din_data,
	input					din_valid,
	output					din_ready,

	input					dout_ready,
	output 					dout_sop,
	output [DATA_WIDTH-1:0]	dout_data,
	output					dout_valid,
	
	//table host i/f 
	input 		 table_clk,
	input [7:0]  table_data,
	input [7:0]  table_addr,
	input 		 table_we,
	output reg	 table_ack
);	   



	assign din_ready = ~outFifoAlmostFull; 
	logic [7:0]memReadData;
	logic [23:0]memReadDataStub;
	logic [23:0]memWriteDataStub = 0;
	SDPB #(
		.READ_MODE(1'b0),
		.BIT_WIDTH_0(8),
		.BIT_WIDTH_1(8),
		.BLK_SEL_0(3'b000),
		.BLK_SEL_1(3'b000),
		.RESET_MODE("SYNC"),
		 //1.0
		.INIT_RAM_00(256'h1F1E1D1C1B1A191817161514131211100F0E0D0C0B0A09080706050403020100),
		.INIT_RAM_01(256'h3F3E3D3C3B3A393837363534333231302F2E2D2C2B2A29282726252423222120),
		.INIT_RAM_02(256'h5F5E5D5C5B5A595857565554535251504F4E4D4C4B4A49484746454443424140),
		.INIT_RAM_03(256'h7F7E7D7C7B7A797877767574737271706F6E6D6C6B6A69686766656463626160),
		.INIT_RAM_04(256'h9F9E9D9C9B9A999897969594939291908F8E8D8C8B8A89888786858483828180),
		.INIT_RAM_05(256'hBFBEBDBCBBBAB9B8B7B6B5B4B3B2B1B0AFAEADACABAAA9A8A7A6A5A4A3A2A1A0),
		.INIT_RAM_06(256'hDFDEDDDCDBDAD9D8D7D6D5D4D3D2D1D0CFCECDCCCBCAC9C8C7C6C5C4C3C2C1C0),
		.INIT_RAM_07(256'hFFFEFDFCFBFAF9F8F7F6F5F4F3F2F1F0EFEEEDECEBEAE9E8E7E6E5E4E3E2E1E0))
	gamma_table (
		.DO({memReadDataStub, memReadData}), 
	    .CLKA(table_clk),
	    .CEA(table_we),
	    .RESETA(rst),
	    .CLKB(clk),
	    .CEB(din_valid),
	    .RESETB(rst),
	    .OCE(1'b1),
	    .BLKSELA(3'b000),
	    .BLKSELB(3'b000),
	    .ADA({3'b000,table_addr[7:0],3'b000}),
	    .DI({memWriteDataStub, table_data}),
	    .ADB({3'b000,din_data[7:0],3'b000}));

		
	//serveice dly
	logic sopDly;
	logic validDly;
	always @(posedge clk or posedge rst) begin : srsvs_dly
		if(rst) begin
			sopDly <= 1'b0;
			validDly <= 1'b0;
		end
		else begin 
			sopDly <= din_sop;
			validDly <= din_valid;
		end
	end
	
	//ack gen
	logic table_weDly1;
	always @(posedge table_clk or posedge rst) begin : ack_gen
		if(rst) begin
			table_ack <= 1'b0;
			table_weDly1  <= 1'b0;
		end
		else begin
			table_weDly1 <= table_we; 
			table_ack <= table_we && ~table_weDly1;
		end
	end	
	
	//compensate pipeline
	logic outFifoAlmostFull;
	logic outFifoEmpty;
	logic outFifoRdEn;
	assign outFifoRdEn = ~outFifoEmpty && dout_ready; 
	logic  [DATA_WIDTH:0] outFifoQ;
	small_pipe_comp_fifo small_pipe_comp_fifoInst(
		.Data({sopDly, memReadData}), //input [8:0] Data
		.Clk(clk), //input Clk
		.WrEn(validDly), //input WrEn
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