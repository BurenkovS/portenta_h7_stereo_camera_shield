`define     I2C_SLAVE_RCVD_ADDR     8'h00
`define     I2C_SLAVE_RCVD_DATA     8'h04


module i2c_arduino_slave
(
	input 	clk,
	input	rst,
	
    /*
     * I2C interface
     */
    input  wire        scl_i,
    output wire        scl_o,
    output wire        scl_t,
    input  wire        sda_i,
    output wire        sda_o,
    output wire        sda_t,

    output  reg                 wb_rd_ack       ,       // Wishbone-сигналы
    input                       wb_ext_we       ,
    input                       wb_ext_stb      ,
    input           [7:0]       wb_ext_adr      ,
    output  reg     [15:0]      wb_ext_rdata    ,

    output  reg                 irq 
);

parameter DATA_WIDTH = 16;  // width of data bus in bits
parameter ADDR_WIDTH = 8;  // width of address bus in bits
parameter STRB_WIDTH = (DATA_WIDTH/8);


wire [ADDR_WIDTH-1:0]  m_axil_awaddr	;
wire [2:0]             m_axil_awprot	;
wire                   m_axil_awvalid	;
wire                   m_axil_awready	;
wire [DATA_WIDTH-1:0]  m_axil_wdata		;
wire [STRB_WIDTH-1:0]  m_axil_wstrb		;
wire                   m_axil_wvalid	;
wire                   m_axil_wready	;
wire [1:0]             m_axil_bresp		;
wire                   m_axil_bvalid	;
wire                   m_axil_bready	;
wire [ADDR_WIDTH-1:0]  m_axil_araddr	;
wire [2:0]             m_axil_arprot	;
wire                   m_axil_arvalid	;
wire                   m_axil_arready	;
wire [DATA_WIDTH-1:0]  m_axil_rdata		;
wire [1:0]             m_axil_rresp		;
wire                   m_axil_rvalid	;
wire                   m_axil_rready	;


(* keep="true" *) reg         [15:0]  writen_addr;                // data from Arduino to module via I2C
(* keep="true" *) reg         [15:0]  writen_data;

always @(posedge clk) begin
    if (wb_ext_stb) begin           // чтение по WB
        if (wb_ext_we == 0) begin
            if (wb_ext_adr[7:0] == `I2C_SLAVE_RCVD_ADDR) begin
                wb_ext_rdata <= writen_addr;
            end
            if (wb_ext_adr[7:0] == `I2C_SLAVE_RCVD_DATA) begin
                wb_ext_rdata <= writen_data;
            end

            wb_rd_ack <= 1;
        end
    end
    if (wb_rd_ack == 1) begin
        wb_rd_ack <= 0;
    end
end

(* keep="true" *) wire [7:0]  m_axis_data_tdata	;
wire		m_axis_data_tvalid	;
wire		m_axis_data_tlast	;

/*
 * I2C slave
 */
i2c_slave  #(
    .FILTER_LEN (4)
)
i2c_slave_inst (
    .clk	(clk),
    .rst	(rst),

    /*
     * Host interface
     */
    .release_bus		(release_bus)		,

    .s_axis_data_tdata	(0)					,			  //	input  wire [7:0]  
    .s_axis_data_tvalid	(0)					,             //	input  wire        
    .s_axis_data_tready	()					,             //	output wire        
    .s_axis_data_tlast	(0)					,             //	input  wire        

    .m_axis_data_tdata	(m_axis_data_tdata)	,
    .m_axis_data_tvalid (m_axis_data_tvalid),
    .m_axis_data_tready (1)					,
    .m_axis_data_tlast	(m_axis_data_tlast)	,

    /*
     * I2C interface
     */
    .scl_i			(scl_i),
    .scl_o			(scl_o),
    .scl_t			(scl_t),
    .sda_i			(sda_i),
    .sda_o			(sda_o),
    .sda_t			(sda_t),

    /*
     * Status
     */
    .busy			(),
    .bus_address	(),
    .bus_addressed	(),
    .bus_active		(),

    /*
     * Configuration
     */
    .enable					(1)	,
    .device_address			(7'b1100100),
    .device_address_mask    (7'h7f)
);

(* keep="true" *) reg [4:0] state;

parameter STATE_IDLE = 0;
parameter STATE_ADDR1 = 1;
parameter STATE_ADDR2 = 2;
parameter STATE_DAT1 = 3;
parameter STATE_DAT2 = 4;

always @(posedge clk)
begin
	if (rst) begin
		state <= STATE_IDLE;
		irq <= 0;
	end
	
	if (state == STATE_IDLE) begin
		if (m_axis_data_tvalid) begin
			writen_addr[15:8] <= m_axis_data_tdata;
			if (~m_axis_data_tlast) begin//check unexpected tlast and go to IDLE if occure
				state		<= STATE_ADDR1;
			end
			else begin
				state		<= STATE_IDLE;
			end
		end
	end

	if (state == STATE_ADDR1) begin
		if (m_axis_data_tvalid) begin
			if (~m_axis_data_tlast) begin
				state		<= STATE_ADDR2;
				writen_addr[7:0] <= m_axis_data_tdata;
			end
			else begin
				state		<= STATE_IDLE;
			end
		end		
	end
	
	if (state == STATE_ADDR2) begin
		if (m_axis_data_tvalid) begin
			if (~m_axis_data_tlast) begin
				state		<= STATE_DAT1;
				writen_data[15:8] <= m_axis_data_tdata;
			end
			else begin
				state		<= STATE_IDLE;
				writen_data[7:0] <= m_axis_data_tdata;
			end
		end		
	end
    
	if (state == STATE_DAT1) begin
		if (m_axis_data_tvalid) begin
			writen_data[7:0] 	<= m_axis_data_tdata;
			state				<= STATE_IDLE;
			irq                 <= 1;
		end		
	end	
	
	begin
        if (irq) begin
            irq <= 0;
        end
    end
end

endmodule