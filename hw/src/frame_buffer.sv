//frame_buffer. V1 : write to frame A, read from frame B same time, then exchange write and read space.
//current version limitation : actual number of pixels in line should be multiple of 4 bytes! dqm hardcoded to 4'b0000
module 	frame_buffer #(
	parameter DATA_WIDTH = 8,
	parameter MAX_INPUT_WIDTH = 1504,
	parameter MAX_INPUT_HEIGHT = 480)

(
	input I_sdrc_clk,//control IF and data stream clock, 
	input I_sdram_clk,//clock to SDRAM
	input		rst,
	
	input		enable_diff_mode,
	
	//ready latency  = 0
	input					din_sop,
	input [DATA_WIDTH-1:0]	din_data,
	input					din_valid,
	output					din_ready,

	input					dout_ready,
	output reg				dout_sop,
	output [DATA_WIDTH-1:0]	dout_data,
	output reg				dout_valid,
	
	//actual number of pixels in frame should be multiple of 4 bytes!
	input 	[$clog2(MAX_INPUT_WIDTH)-1:0]	param_frame_width,
	input 	[$clog2(MAX_INPUT_HEIGHT)-1:0]	param_frame_height,
	
	//sdram side
	output O_sdram_clk,
	output O_sdram_cke,
	output O_sdram_cs_n,
	output O_sdram_cas_n,
	output O_sdram_ras_n,
	output O_sdram_wen_n,
	output [3:0] O_sdram_dqm,
	output [10:0] O_sdram_addr,
	output [1:0] O_sdram_ba,
	inout [31:0] IO_sdram_dq);
	
	localparam FRAME1_ADDR = 0;
	localparam FRAME2_ADDR = 'h100000;//MAX_INPUT_WIDTH*MAX_INPUT_HEIGHT;
							  
	logic widthConverterWrite;	
	logic [31:0] widthConverterDataOut;
	logic widthConverterValidOut;
	
	assign widthConverterWrite = ~writeFifoAlmostFull && din_valid;
	
	logic writeFifoWrEn;
	logic writeFifoFull;
	logic writeFifoAlmostFull;
	logic writeFifoRdEn;
	logic writeFifoEmpty;	
	logic [8:0] writeFifoRnum;
	logic [31:0] writeFifoQ;
	
	assign writeFifoWrEn  = widthConverterValidOut;// din_valid;
	assign din_ready = ~writeFifoAlmostFull;
	assign writeFifoRdEn = (state == WRITE_CHUNK) ? 1'b1 : 1'b0;

	bit8ToBit32 bit8ToBit32Inst(
   		.clk(I_sdrc_clk),          // Clock signal
    	.reset(rst),        // Reset signal
    	.valid_in(widthConverterWrite),     // Valid signal for input data
    	.data_in(din_data),// 8-bit input data
    	.data_out(widthConverterDataOut), // 32-bit output data
    	.valid_out(widthConverterValidOut)     // Valid signal for output data
);

	sdram_write_fifo_v3 sdramWriteFifo(
		.Reset(rst),
		.Data(widthConverterDataOut),
		.Clk(I_sdrc_clk),
		.WrEn(writeFifoWrEn),
		.RdEn(writeFifoRdEn),
		.Wnum(writeFifoRnum),
		.Q(writeFifoQ),
		.Empty(writeFifoEmpty),
		.Full(),
		.Almost_Full(writeFifoAlmostFull));


	logic writeFifoCopyRdEn;
	assign writeFifoCopyRdEn = O_sdrc_rd_valid;
	logic [31:0] writeFifoCopyQ;
	sdram_write_fifo_v3 sdramWriteFifoCopy(	
		.Reset(rst),
		.Data(/*din_data*/widthConverterDataOut),
		//.WrClk(I_sdrc_clk),
		//.RdClk(I_sdrc_clk),
		.Clk(I_sdrc_clk),
		.WrEn(writeFifoWrEn),
		.RdEn(writeFifoCopyRdEn),
		.Wnum(),
		.Q(writeFifoCopyQ),
		.Empty(),
		.Full(),
		.Almost_Full());
		
	logic O_sdrc_rd_valid;
	logic O_sdrc_rd_validDly1;
	logic [31:0] O_sdrc_data; 
	logic [31:0] O_sdrc_dataDly1; 
	logic sdrcWrN;
	logic sdrcRdN;
	logic [20:0] sdrcAddr;

	//Read/write data length
	//Take I_sdrc_data_len[7:0] for
	//instance, the port input range is
	//0~255, and the corresponding valid
	//read/write length range is 1~256,
	//and so on.		   
	logic [7:0] sdrcDataLen;
	logic O_sdrc_init_done;	
	logic O_sdrc_busy_n;
	
	SDRAM_controller_top_SIP SDRAM_controller_top_SIP_inst(
		.I_sdrc_rst_n(~rst),
		.I_sdrc_clk(I_sdrc_clk),
		.I_sdram_clk(I_sdram_clk),
		.I_sdrc_selfrefresh(1'b0),
		.I_sdrc_power_down(1'b0),
		.I_sdrc_wr_n(sdrcWrNDly1),
		.I_sdrc_rd_n(sdrcRdN),
		.I_sdrc_addr(sdrcAddr),
		
		//Read/write data length
		//Take I_sdrc_data_len[7:0] for
		//instance, the port input range is
		//0~255, and the corresponding valid
		//read/write length range is 1~256,
		//and so on.		   
		.I_sdrc_data_len(sdrcDataLen-1'b1),
		
		.I_sdrc_dqm(4'b0000),
		.I_sdrc_data(writeFifoQ),
		
		.O_sdrc_data(O_sdrc_data),
		.O_sdrc_init_done(O_sdrc_init_done),
		.O_sdrc_busy_n(O_sdrc_busy_n),
		.O_sdrc_rd_valid(O_sdrc_rd_valid),
		.O_sdrc_wrd_ack(),
		
		
		.O_sdram_clk(O_sdram_clk),
		.O_sdram_cke(O_sdram_cke),
		.O_sdram_cs_n(O_sdram_cs_n),
		.O_sdram_cas_n(O_sdram_cas_n),
		.O_sdram_ras_n(O_sdram_ras_n),
		.O_sdram_wen_n(O_sdram_wen_n),
		.O_sdram_dqm(O_sdram_dqm),
		.O_sdram_addr(O_sdram_addr),
		.O_sdram_ba(O_sdram_ba),
		.IO_sdram_dq(IO_sdram_dq)
	);

	logic readFifoFull; 
	logic readFifoRdEn;	
	logic readFifoEmpty;	
	
	assign readFifoRdEn = dout_ready && ~readFifoEmpty;	
	logic [8:0] readFifoWnum;

	//write diff signal
	logic [31:0] diffStream;
	logic diffValid[0:3]; 

	genvar i;
    generate
        for (i=0; i < 4; i++) begin
            pixDiff	#(
				.DATA_WIDTH(DATA_WIDTH))
			pixDiffInst(
				.clk(I_sdrc_clk),
				.rst(rst),
				.enable_diff_mode(enable_diff_mode),
				.din_valid(O_sdrc_rd_validDly1), 
				.dout_valid(diffValid[i]),
				.din1(O_sdrc_dataDly1[(i+1)*DATA_WIDTH-1-:DATA_WIDTH]),
				.din2(writeFifoCopyQ[(i+1)*DATA_WIDTH-1-:DATA_WIDTH]),
				.dout(diffStream[(i+1)*DATA_WIDTH-1-:DATA_WIDTH]));
        end
    endgenerate
	
	sdram_read_fifo_hs sdramReadFifoInst(
		.Data(diffStream),
		.WrClk(I_sdrc_clk),
		.RdClk(I_sdrc_clk),
		.WrEn(diffValid[0]),
		.RdEn(readFifoRdEn),
		.Wnum(readFifoWnum),
		.Q(dout_data),
		.Empty(readFifoEmpty),
		.Full(readFifoFull)
	);


	//control sm
	typedef enum logic[3:0] {IDLE
		,WAIT_INIT_DONE	
		,WAIT_SOP
		,CHECK_ENOUGH_SPACE_TO_READ
		,READ_CHUNK
		,CHECK_ENOUGH_DATA_TO_WRITE
		,WRITE_CHUNK
		,WAIT_WRITE_BUSY
		,EXCHANGE} state_t;
		state_t state;
	localparam CHUNK_SIZE = 32; 
	
	logic [$clog2(MAX_INPUT_WIDTH)-1:0] pixCnt;
	logic [$clog2(MAX_INPUT_WIDTH)-1:0] lastRemainLenght; 
	logic [$clog2(MAX_INPUT_WIDTH*MAX_INPUT_HEIGHT)-1:0] addrOffset;
	logic [$clog2(MAX_INPUT_HEIGHT)-1:0] linesCnt;
	logic parity;

	always @(posedge I_sdrc_clk or posedge rst) begin
		integer wordsCnt; //1 word = 4 bytes
		if(rst) begin
			state <= IDLE;
			linesCnt <= 0;
			pixCnt <= 0;
			wordsCnt <= 0;
			sdrcWrN <= 1'b1;
			sdrcRdN <= 1'b1;
			sdrcAddr <= 0;
			lastRemainLenght <= 0;
			parity <= 1'b0;
			addrOffset <= 0;
			
		end
		else begin
			case(state)
				IDLE : begin
					state <= WAIT_INIT_DONE; 
					sdrcWrN <= 1'b1;
					sdrcRdN <= 1'b1;
				end			
			
				WAIT_INIT_DONE : begin
					if(O_sdrc_init_done) begin
						state <= WAIT_SOP;
					end			
				end
				
				WAIT_SOP : begin
					if(/*din_valid && din_ready && */din_sop) begin
						state <= CHECK_ENOUGH_SPACE_TO_READ;
						pixCnt <= 0;
						linesCnt <= 0;
						addrOffset <= 0;
					end
				end
					
				
				CHECK_ENOUGH_SPACE_TO_READ : begin
					if(writeFifoRnum >=CHUNK_SIZE && readFifoWnum <= CHUNK_SIZE && O_sdrc_busy_n) begin
						sdrcAddr <= (parity ? FRAME1_ADDR : FRAME2_ADDR) + addrOffset;
						state <= READ_CHUNK;
						sdrcRdN <= 1'b0;
						if(linesCnt == (param_frame_height-1) && pixCnt > (param_frame_width-CHUNK_SIZE*4)) begin
							sdrcDataLen <= (param_frame_width-pixCnt)>>2;//div on 4 to get num of words
						end
						else begin
							sdrcDataLen <= CHUNK_SIZE;
						end
					end	   
				end
				
				READ_CHUNK : begin
					sdrcRdN <= 1'b1;
					if(O_sdrc_rd_validDly1) begin
						wordsCnt <= wordsCnt + 1;
						if(wordsCnt == sdrcDataLen-1) begin
							wordsCnt <= 0;
							state <= CHECK_ENOUGH_DATA_TO_WRITE;
							if(pixCnt < param_frame_width-CHUNK_SIZE*4) begin
								pixCnt <= pixCnt + CHUNK_SIZE*4;
							end
							else begin
								pixCnt <= pixCnt + CHUNK_SIZE*4 - param_frame_width;
								linesCnt <= linesCnt + 1;
							end
						end
					end
				end
				
				CHECK_ENOUGH_DATA_TO_WRITE : begin
					if(writeFifoRnum >= CHUNK_SIZE && O_sdrc_busy_n) begin
						sdrcWrN <= 1'b0;
						state <= WRITE_CHUNK;
						sdrcAddr <= (parity ? FRAME2_ADDR : FRAME1_ADDR) + addrOffset;
					end
				end
				
				WRITE_CHUNK : begin
					sdrcWrN <= 1'b1;
					wordsCnt <= wordsCnt + 1;
					if(wordsCnt == sdrcDataLen-1) begin
						wordsCnt <= 0;
						state <= WAIT_WRITE_BUSY;
					end
				end
				
				WAIT_WRITE_BUSY : begin
					if(O_sdrc_busy_n) begin
						if(linesCnt == param_frame_height &&  pixCnt == 0) begin
							parity <= ~parity;
							state = WAIT_SOP;
							addrOffset <= 0;
						end
						else begin
							state <= CHECK_ENOUGH_SPACE_TO_READ;
							addrOffset <= addrOffset + CHUNK_SIZE;
						end
					end
				end
				
			endcase
		end
	end
	
	//serveice dly
	logic sdrcWrNDly1;
	always @(posedge I_sdrc_clk or posedge rst) begin : srsvs_dly
		if(rst) begin
			sdrcWrNDly1 <= 1'b1; 
			O_sdrc_rd_validDly1 <= 1'b0; 
			O_sdrc_dataDly1 <= 0;
		end
		else begin
			sdrcWrNDly1 <= sdrcWrN;
			O_sdrc_rd_validDly1 <= O_sdrc_rd_valid;
			O_sdrc_dataDly1 <= O_sdrc_data;
		end
	end	

	
	logic intSop;
	always @(posedge I_sdrc_clk or posedge rst) begin : sop_gen
		if(rst) begin
			intSop <= 1'b0;
		end
		else begin
			if(state == WAIT_SOP && din_valid && din_ready && din_sop) begin
				intSop <= 1'b1;																						  
			end
			if(intSop && readFifoRdEn) begin
				intSop <= 1'b0;			
			end
		end
	end

	always @(posedge I_sdrc_clk or posedge rst) begin
		if(rst) begin
			dout_valid <= 1'b0;
			dout_sop <= 1'b0;
		end
		else begin
			dout_valid <= ~readFifoEmpty;	
			dout_sop <= intSop;
		end
	end
		
endmodule


module 	pixDiff #(
	parameter DATA_WIDTH = 8)

(
	input						clk,
	input						rst,
	input						enable_diff_mode,
	input						din_valid,
	input [DATA_WIDTH-1:0]		din1,
	input [DATA_WIDTH-1:0]		din2,
	output reg [DATA_WIDTH-1:0]	dout,
	output reg					dout_valid);
	
	logic [DATA_WIDTH:0] din1Reg;
	logic [DATA_WIDTH:0] din2Reg;
	logic	dinValidReg;

	logic signed [DATA_WIDTH:0] diff;
	assign diff = $signed(din1Reg)-$signed(din2Reg);

	always @(posedge clk or posedge rst) begin
		integer tstCnt;
		if(rst) begin
			din1Reg <= 0;
			din2Reg <= 0;
			dout <= 0;
			dout_valid <= 1'b0;	 
			dinValidReg <= 1'b0;
			tstCnt <= 0;
		end
		else begin
			tstCnt <= tstCnt + 1;
			dinValidReg <= din_valid;
			din1Reg <= {1'b0, din1};
			din2Reg <= {1'b0, din2};
			if(enable_diff_mode) begin
				dout <= (diff > 0) ? diff : - diff;
			end
			else begin
				dout <= din2Reg;
			end
			dout_valid <= dinValidReg;
		end
	end
	
endmodule

module bit8ToBit32 (
    input wire clk,          // Clock signal
    input wire reset,        // Reset signal
    input wire valid_in,     // Valid signal for input data
    input wire [7:0] data_in,// 8-bit input data
    output [31:0] data_out, // 32-bit output data
    output reg valid_out     // Valid signal for output data
);

    reg [1:0] count;         // Counter to keep track of received 8-bit chunks
    reg [31:0] temp_data;    // Temporary register to accumulate 32-bit data

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count <= 2'b00;
            temp_data <= 32'b0;
            valid_out <= 1'b0;
        end else if (valid_in) begin
            case (count)
                2'b00: begin
                    temp_data[7:0] <= data_in;
                    count <= count + 1;
                    valid_out <= 1'b0;
                end
                2'b01: begin
                    temp_data[15:8] <= data_in;
                    count <= count + 1;
                    valid_out <= 1'b0;
                end
                2'b10: begin
                    temp_data[23:16] <= data_in;
                    count <= count + 1;
                    valid_out <= 1'b0;
                end
                2'b11: begin
                    temp_data[31:24] <= data_in;
                    count <= 2'b00;
                    valid_out <= 1'b1;
                end
            endcase
        end else begin
            valid_out <= 1'b0;
        end
    end

   assign data_out = temp_data;

endmodule
