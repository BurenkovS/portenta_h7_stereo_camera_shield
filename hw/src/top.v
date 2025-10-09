module TOP
(
    input           XTAL_IN,                    // clock 27 MHz
	
    inout          	LED1    ,
    inout          	LED2    ,

    output          uart_tx,

	output          dcmi_o_pixclk ,
    output          dcmi_o_hsync  ,
    output          dcmi_o_vsync  ,
	output  [7:0]   dcmi_o_data   ,
	
    input   [9:0]   MT1Data         ,
    input           MT1LineValid    ,
    input           MT1FrameValid   ,
    input           MT1PixClk       ,

    input   [9:0]   MT2Data         ,
    input           MT2LineValid    ,
    input           MT2FrameValid   ,
    input           MT2PixClk       ,

	inout			arduino_i2c_data	,		// slave i2c from Arduino
	inout			arduino_i2c_clk		,
	
	output			sensorClk		,

	inout			sensor_i2c_data	,
	inout			sensor_i2c_clk	,
		
	output			exposure		,			// sencors control 
	output			start_frame		,
	output			start_line      ,
    
    inout			standby         ,
    output			reset_bar       ,//active low 
    output          i2c_adr1 ,
	
	//sdram
	output 			O_sdram_clk,
	output 			O_sdram_cke,
	output 			O_sdram_cs_n,
	output 			O_sdram_cas_n,
	output 			O_sdram_ras_n,
	output 			O_sdram_wen_n,
	output 			[3:0] O_sdram_dqm,
	output 			[10:0] O_sdram_addr,
	output 			[1:0] O_sdram_ba,
	inout 			[31:0] IO_sdram_dq
);

assign          i2c_adr1 = 1    ;
assign          reset_bar = ~sys_rst;

wire			clk_sys			;
wire			sys_pll_locked	;
wire			sys_rst			;
wire    [3:0]   GPIO_wire       ;

assign          LED1 = GPIO_wire[0];
assign          LED2 = GPIO_wire[1];
assign          standby = 1'b0;//GPIO_wire[2];

//to MT9V034 sensors
wire sensor_i2c_data_in;
wire sensor_i2c_data_oe;
wire sensor_i2c_clk_in;
wire sensor_i2c_clk_oe;


wire			i2c_arduino_data_in;
wire			i2c_arduino_clk_in;
wire			i2c_arduino_data_oe;
wire			i2c_arduino_clk_oe;

assign i2c_arduino_clk_in = arduino_i2c_clk;
assign arduino_i2c_clk = ~i2c_arduino_clk_oe ? 1'b0 : 1'bz;

assign i2c_arduino_data_in = arduino_i2c_data;
assign arduino_i2c_data = ~i2c_arduino_data_oe ? 1'b0 : 1'bz;

wire			pll_vid_clk_27M;

wire            slv_ext_stb     ;   
wire            slv_ext_we      ;  
wire            slv_ext_cyc     ;
wire            slv_ext_ack     ;
wire [31:0]     slv_ext_adr     ;
wire [31:0]     slv_ext_wdata   ;
//reg [31:0]      slv_ext_rdata   ;
wire [31:0]      slv_ext_rdata   ;
wire [3:0]      slv_ext_sel     ;

wire            wb_arduino_module_select    ;
wire [15:0]     wb_arduino_module_rdata     ;
wire            wb_arduino_module_ack       ;

wire            i2c_slave_irq       ;



localparam I2C_MASTER_ADDR_MS  = 8'h20;
localparam PARAM_BLOCK_ADDR_MS = 8'h30;
localparam GAMMA_TABLE_ADDR_MS = 8'h31;
localparam I2C_SLAVE_ARDUINO_ADDR_MS  = 8'h38;

assign          wb_arduino_module_select = slv_ext_stb & (slv_ext_adr[31:24] == I2C_SLAVE_ARDUINO_ADDR_MS);  // i2c from arduino addres space : 0x38000000 


i2c_arduino_slave i2c_arduino_slave_inst
(
	.clk	(pll_vid_clk_27M),
	.rst	(sys_rst),

    /*
     * I2C interface
     */
    .scl_i		(i2c_arduino_clk_in)	,
    .scl_o		()						,
    .scl_t		(i2c_arduino_clk_oe)	,
    .sda_i		(i2c_arduino_data_in)	,
    .sda_o		()						,
    .sda_t		(i2c_arduino_data_oe)   ,

    // Wishbone
    .wb_rd_ack       (wb_arduino_module_ack)               ,       
    .wb_ext_we       (slv_ext_we)                               ,
    .wb_ext_stb      (wb_arduino_module_select)   ,
    .wb_ext_adr      (slv_ext_adr[7:0])                         ,
    .wb_ext_rdata    (wb_arduino_module_rdata)                  ,

    .irq             (i2c_slave_irq)
	
);

localparam MAX_IMAGE_WIDTH = 752;
localparam MAX_IMAGE_HEIGHT = 480;
localparam VSYNC_ACTIVE_LEVEL = 0;
localparam HSYNC_ACTIVE_LEVEL = 0;
localparam IMAGE_WIDTH_DEFAULT = 320;//640;
localparam IMAGE_HEIGHT_DEFAULT = 240;//480;
localparam EXP_DEFAULT = 'h00030B00;

assign sys_rst = ~sys_pll_locked;


wire pll_vid_clk_54M;
wire clkDcmi;  
wire clk_sdram;
assign clkDcmi = pll_vid_clk_54M;
assign dcmi_o_pixclk = pll_vid_clk_54M;

assign pll_vid_clk_27M = XTAL_IN;
assign sensorClk = pll_vid_clk_27M;

Gowin_rPLL rPLL_inst(
        .clkout	(clk_sys		),// 81
        .lock	(sys_pll_locked	),
        .clkin	(XTAL_IN		),
		.clkoutp(clk_sdram		)// 81 shifted	
);

Gowin_rPLL_54 rPLL_54_inst_name(
        .clkout (pll_vid_clk_54M),      //output clkout
        .clkin  (XTAL_IN		)       //input clkin
);

wire [$clog2(MAX_IMAGE_WIDTH)-1:0]	param_frame_width;
wire [$clog2(MAX_IMAGE_HEIGHT)-1:0]	param_frame_height;
wire            new_params_written  ;
wire enableMtDrive;	 

wire [1:0] filter1Type;
wire [1:0] filter2Type;
wire filtEna;
	
wire enableDiffMode;

wire	[10:0]		param_start_line_base	;
wire	[10:0]		param_start_line_gap	;

assign	param_start_line_base 	= 788;
assign	param_start_line_gap	= 34;
wire 	[19:0]		param_minimal_SF2E;
wire	[23:0]		param_target_exposure;

//some crutch
reg MT1FrameValidDly1;
reg MT1FrameValidDly2;
always @(posedge MT1PixClk, posedge sys_rst) begin
	if(sys_rst) begin
		MT1FrameValidDly1 <= VSYNC_ACTIVE_LEVEL;
	end
	else begin
		MT1FrameValidDly1 <= MT1FrameValid;
        MT1FrameValidDly2 <= MT1FrameValidDly1;
	end
end

reg MT2FrameValidDly1;
reg MT2FrameValidDly2;
always @(posedge MT2PixClk, posedge sys_rst) begin
	if(sys_rst) begin
		MT2FrameValidDly1 <= VSYNC_ACTIVE_LEVEL;
	end
	else begin
		MT2FrameValidDly1 <= MT2FrameValid;
        MT2FrameValidDly2 <= MT2FrameValidDly1;
	end
end

wire gamma_table_select;
assign  gamma_table_select = slv_ext_stb & (slv_ext_adr[31:24] == GAMMA_TABLE_ADDR_MS);// 0x3100_0000
video_subsystem	#( 
	.DATA_WIDTH(8),
	.MAX_IMAGE_WIDTH(MAX_IMAGE_WIDTH),
	.MAX_IMAGE_HEIGHT(MAX_IMAGE_HEIGHT),
	.VSYNC_ACTIVE_LEVEL(VSYNC_ACTIVE_LEVEL),//same for input and output
	.HSYNC_ACTIVE_LEVEL(HSYNC_ACTIVE_LEVEL),
	.IMAGE_WIDTH_DEFAULT(IMAGE_WIDTH_DEFAULT),
	.IMAGE_HEIGHT_DEFAULT(IMAGE_HEIGHT_DEFAULT),
	.EXP_DEFAULT(EXP_DEFAULT))
videoSubsystemInst(
	.clk(clk_sys),
	.clk_sdram(clk_sdram),
	.rst(sys_rst),
	.clk_dcmi(clkDcmi),
	.clk_sensor(sensorClk),

    .control_ena(enableMtDrive),
    .exposure(exposure),
	.start_frame(start_frame),
	.start_line(start_line),

	.mt1_clk(MT1PixClk),
	.mt1_hsync(MT1LineValid),
	.mt1_vsync(MT1FrameValidDly2/*MT1FrameValid*/),
	.mt1_data(MT1Data[9:2]),

	.mt2_clk(MT2PixClk),
	.mt2_hsync(MT2LineValid),
	.mt2_vsync(MT2FrameValidDly2/*MT2FrameValid*/),
	.mt2_data(MT2Data[9:2]),

	.param_frame_width(param_frame_width),
	.param_frame_height(param_frame_height),
	.param_target_exposure(param_target_exposure),
	.param_start_line_base(param_start_line_base),
	.param_start_line_gap(param_start_line_gap),
	.param_enable_diff_mode(enableDiffMode),
	.param_filt1_type(filter1Type),
	.param_filt2_type(filter2Type),
	.param_filt_ena 	(filtEna),
	.param_update(new_params_written),
	
	//gamma table host i/f
	.gamma_table_clk(pll_vid_clk_27M),
	.gamma_table_data(slv_ext_wdata[7:0]),
	.gamma_table_addr(slv_ext_adr[9:2]),
	.gamma_table_we(gamma_table_select & slv_ext_stb & slv_ext_we),
	.gamma_table_ack(gamma_table_ack),

	.dcmi_hsync(dcmi_o_hsync),
	.dcmi_vsync(dcmi_o_vsync),
	.dcmi_data(dcmi_o_data),
	
	.O_sdram_clk(O_sdram_clk),
	.O_sdram_cke(O_sdram_cke),
	.O_sdram_cs_n(O_sdram_cs_n),
	.O_sdram_cas_n(O_sdram_cas_n),
	.O_sdram_ras_n(O_sdram_ras_n),
	.O_sdram_wen_n(O_sdram_wen_n),
	.O_sdram_dqm(O_sdram_dqm),
	.O_sdram_addr(O_sdram_addr),
	.O_sdram_ba(O_sdram_ba),
	.IO_sdram_dq(IO_sdram_dq));


Gowin_PicoRV32_Top PicoRV32_inst(

	.ser_tx         (uart_tx)      , //output ser_tx
	.ser_rx         (1'b1)      , //input ser_rx
	.gpio_io        (GPIO_wire)         , //inout [3:0] gpio_io

	.slv_ext_stb_o  (slv_ext_stb    )   , //output slv_ext_stb_o
	.slv_ext_we_o   (slv_ext_we     )   , //output slv_ext_we_o
	.slv_ext_cyc_o  (slv_ext_cyc    )   , //output slv_ext_cyc_o
	.slv_ext_ack_i  (slv_ext_ack    )   , //input slv_ext_ack_i
	.slv_ext_adr_o  (slv_ext_adr    )   , //output [31:0] slv_ext_adr_o
	.slv_ext_wdata_o(slv_ext_wdata  )   , //output [31:0] slv_ext_wdata_o
	.slv_ext_rdata_i(slv_ext_rdata  )   , //input [31:0] slv_ext_rdata_i
	.slv_ext_sel_o  (slv_ext_sel    )   , //output [3:0] slv_ext_sel_o
	
    .irq_in         ({11'h0, i2c_slave_irq}) , //input [31:20] irq_in

	.wbi2c_sda(sensor_i2c_data), //inout wbi2c_sda
	.wbi2c_scl(sensor_i2c_clk), //inout wbi2c_scl

	.clk_in         (pll_vid_clk_27M)           ,   //input clk_in
	.resetn_in      (~sys_rst)            //input resetn_in
);
	
wire    params_block_select ;
wire    params_block_ack    ;
wire    params_block_m_s_rvalid ;

//TODO check slv_ext_stb signal, possible not needed here
assign  params_block_select = slv_ext_stb & (slv_ext_adr[31:24] == PARAM_BLOCK_ADDR_MS);//params block offset in address space 0x3000_0000
params_block #(
	.MAX_IMAGE_WIDTH(MAX_IMAGE_WIDTH),
	.MAX_IMAGE_HEIGHT(MAX_IMAGE_HEIGHT),
	.DEF_IMAGE_WIDTH(IMAGE_WIDTH_DEFAULT),	
	.DEF_IMAGE_HEIGHT(IMAGE_HEIGHT_DEFAULT),
	.DEF_EXP(EXP_DEFAULT))
params_block_inst(
    .sys_clk        (pll_vid_clk_27M),
	.sys_rst        (sys_rst),
	
	.s_address	    (slv_ext_adr[23:0])                                 ,				//high byte - device number, 2 low byte? - register number
	.s_wdata		(slv_ext_wdata[31:0])                               ,	
	.s_wvalid	    (params_block_select & slv_ext_stb & slv_ext_we  )  ,		
	.s_wready	    ()                                                  ,			
	.s_write_ack    (params_block_ack)                                  ,			
	.s_rdata		()                                                  ,			
	.s_rvalid	    (params_block_m_s_rvalid    )                       ,				
	.s_rreq		    (params_block_select & slv_ext_stb & ~slv_ext_we  ) ,				
	
    .frame_heigh         (param_frame_height),
    .frame_width         (param_frame_width)    ,
    .target_exposure     (param_target_exposure),                                       // u32
    .minimal_SF2E        (param_minimal_SF2E)   ,
    .new_params_written  (new_params_written),
    .enable_mt_drive     (enableMtDrive), 
	.param_filt1_type	(filter1Type),
	.param_filt2_type	(filter2Type),
	.param_filt_ena 	(filtEna),
	.param_enable_diff_mode(enableDiffMode)
);

wire            i2c_m_s_write_ack  ;     
wire            i2c_m_s_rvalid     ;
wire  [15:0]    i2c_m_s_rdata      ;
wire            i2c_master_shell_select;

assign      slv_ext_ack = gamma_table_ack || params_block_ack || params_block_m_s_rvalid || wb_arduino_module_ack;
assign      slv_ext_rdata[15:0] = wb_arduino_module_rdata[15:0];
assign      i2c_master_shell_select = slv_ext_stb & (slv_ext_adr[31:24] == I2C_MASTER_ADDR_MS);      // i2c master addreses: 0x2000_0000

/*always @(*)                                                  
begin
    if (i2c_master_shell_select) begin
        slv_ext_rdata[15:0] = i2c_m_s_rdata[15:0];
    end
    else begin
        slv_ext_rdata[15:0] = wb_arduino_module_rdata[15:0];
    end
end*/


endmodule
