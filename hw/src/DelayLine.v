	// Parameterized serial-in, serial-out shift register
	module DelayLine #(
		parameter WIDTH = 64,
		parameter LENGTH = 16
	)
	(
		input 	clk,
		input 	reset,
		input	[WIDTH-1:0] din,
		output	[WIDTH-1:0]	dout
	);
		
	
	generate
		if(LENGTH == 1) begin : single_delay_gen
			reg [WIDTH-1:0] tmp;
			always @(posedge clk or posedge reset) begin
				if(reset) begin
					tmp <= {WIDTH{1'b0}};
				end
				else begin
					tmp <= din;
				end
			end
		
			assign dout = tmp;
			
		end
		else begin : multiple_delay_gen
			reg [WIDTH-1:0] tmp[LENGTH-1:0];
		
			integer i;
			always @(posedge clk or posedge reset) begin
				if(reset) begin
					for(i = 1; i < LENGTH; i=i+1) begin  
						tmp[0] <= {WIDTH{1'b0}};
						tmp[i] <= {WIDTH{1'b0}}; 
					end
				end
				else begin
					for(i = 1; i < LENGTH; i=i+1) begin  
						tmp[0] <= din;
						tmp[i] <= tmp[i-1]; 
					end
				end
			end
		
			assign dout = tmp[LENGTH-1];
		end
	endgenerate
		
	endmodule