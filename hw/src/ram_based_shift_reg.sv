module ram_based_shift_reg	#( 
	parameter DATA_WIDTH = 8,
	parameter MAX_LENGHT = 1504)
	(
	input			clk,						
	input			rst,

	input [$clog2(MAX_LENGHT)-1:0]	shift_lenght,
	
	input							we,
	input [DATA_WIDTH-1:0]			din,
	output  reg [DATA_WIDTH-1:0]	dout,
	output	reg						dout_valid
);


	logic [$clog2(MAX_LENGHT)-1:0] wrAddr;
	logic [$clog2(MAX_LENGHT)-1:0] rdAddr;
	logic [$clog2(MAX_LENGHT)-1:0] ramOut;
	
	logic [DATA_WIDTH-1:0]			dinDly1;

	ram_sr ram_sr_inst(
		.clka(clk),
		.reseta(rst),
		.cea(weDly1),
		.ada(wrAddr),
		.din(dinDly1),
		
		.clkb(clk),
		.resetb(rst),
		.ceb(we),
		.adb(rdAddr),
		.dout(ramOut),
		.oce(1'b1));


	//assign dout = ramOut;
	always @(posedge clk or posedge rst) begin
		if(rst) begin
			wrAddr <= 0;
			rdAddr <= 0;
			dout <= 0;
			dinDly1 <= 0;
		end
		else begin
			dout <= ramOut;
			//rdAddr <= wrAddr;  
			wrAddr <= rdAddr; 
			dinDly1 <= din;
			if(we) begin
				//dout <= ramOut;
				rdAddr <= rdAddr+1;
				//rdAddr <= wrAddr+2;
				if(rdAddr == (shift_lenght-1)) begin
					rdAddr <= 0;
					//rdAddr <= 1;
				end
			end
		end
	end
	
	logic weDly1;
	logic weDly2;
	always @(posedge clk or posedge rst) begin
		if(rst) begin
			dout_valid <= 1'b0;
			weDly1 <= 1'b0;
			weDly2 <= 1'b0;
		end
		else begin
			weDly1 <= we;
			weDly2 <= weDly1;
			dout_valid <= weDly1;//weDly2; 
		end
	end

endmodule