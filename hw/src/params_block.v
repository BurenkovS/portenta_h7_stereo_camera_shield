module  params_block #( 
	parameter MAX_IMAGE_WIDTH = 752,
	parameter MAX_IMAGE_HEIGHT = 480,
	parameter DEF_IMAGE_WIDTH = 640,
	parameter DEF_IMAGE_HEIGHT = 480,
	parameter DEF_EXP = 32'h00029B00)
(
	input	sys_clk,
	input	sys_rst,
	
	input	[23:0]	s_address	,				// старший байт - номер устройства, младшие - номер регистра
	input	[15:0]	s_wdata		,				// данные к записи
	input			s_wvalid	,				// строб записываемых данных
	output			s_wready	,				// готов к записи
	output	reg		s_write_ack ,				// подтверждение записи
	output	[15:0]	s_rdata		,				// прочитанные данные
	output	reg		s_rvalid	,				// строб прочитанных данных
	input			s_rreq		,				// запрос чтения
	
    output reg [8:0]  frame_heigh         ,
    output reg [9:0]  frame_width         ,
    output reg [31:0]  target_exposure     ,
    output reg [31:0]  minimal_SF2E        ,
    output reg enable_mt_drive,
	output reg param_enable_diff_mode, 
	output reg [1:0] param_filt1_type,
	output reg [1:0] param_filt2_type,
	output reg param_filt_ena,

    output  reg         new_params_written      // сигнал - был записан новый набор параметров

);

reg     s_wvalid_d1;
wire    s_wvalid_front;

assign  s_wvalid_front = ~s_wvalid_d1 & s_wvalid;

reg [8:0]   new_frame_heigh         ;
reg [9:0]   new_frame_width         ;
reg [31:0]  new_target_exposure     ;
reg [31:0]  new_minimal_SF2E        ;



always @(posedge sys_clk or posedge sys_rst) begin
	
	if(sys_rst == 1'b1) begin
		frame_heigh <= DEF_IMAGE_HEIGHT;
    	frame_width <= DEF_IMAGE_WIDTH;
    	target_exposure <= DEF_EXP;
   		minimal_SF2E <= 32'b0;//todo possible not needed 
	    new_params_written <= 1'b0;
        enable_mt_drive <= 1'b0;
		
		new_frame_heigh <= DEF_IMAGE_HEIGHT;
		new_frame_width  <= DEF_IMAGE_WIDTH;
		new_target_exposure <= DEF_EXP;
		new_minimal_SF2E <= 32'b0;//todo possible not needed
		param_enable_diff_mode <= 1'b0;	
		param_filt1_type <= 2'b00;	
		param_filt2_type <= 2'b00;
		param_filt_ena <= 1'b0;
		
	end
	else begin
	    s_wvalid_d1 <= s_wvalid;
	    s_rvalid    <= s_rreq;           // отладочная заглушка
	
	    if (s_wvalid_front) begin
	        s_write_ack <= 1;
	    end
	    else begin
	        s_write_ack <= 0;
	    end
	
	    if (s_wvalid) begin
	        if (s_address[7:0]  == 16'h00) begin
	            new_params_written <= s_wdata[0];       // младший бит - записаны новые данные
                enable_mt_drive <= s_wdata[1];       //start sensors drive
	        end
	        if (s_address[7:0]  == 16'h04) begin
	            new_frame_heigh <= s_wdata[8:0];
	        end
	        if (s_address[7:0]  == 16'h08) begin
	            new_frame_width     <= s_wdata[9:0];
	        end
	        if (s_address[7:0]  == 16'h0C) begin            // старшая и младшая части
	            new_target_exposure[15:0] <= s_wdata[15:0];
	        end
	        if (s_address[7:0]  == 16'h10) begin
	            new_target_exposure[31:16] <= s_wdata[15:0];
	        end
	        if (s_address[7:0]  == 16'h14) begin
	            new_minimal_SF2E[15:0] <= s_wdata[15:0];
	        end
	        if (s_address[7:0]  == 16'h18) begin
	            new_minimal_SF2E[31:16] <= s_wdata[15:0];
	        end
			if(s_address[7:0]  == 16'h1C) begin
				param_enable_diff_mode <= s_wdata[0];
			end
			if(s_address[7:0]  == 16'h20) begin
				param_filt1_type <= s_wdata[1:0];
				param_filt2_type <= s_wdata[3:2];
				param_filt_ena <= s_wdata[4];
			end

	        
	    end
	    else begin
	        if (new_params_written == 1) begin
	            new_params_written <= 0;
	
	            frame_heigh      <=    new_frame_heigh     ;
	            frame_width      <=    new_frame_width     ;
	            target_exposure  <=    new_target_exposure ;
	            minimal_SF2E     <=    new_minimal_SF2E    ;
	        end
	    end
	end
end

endmodule