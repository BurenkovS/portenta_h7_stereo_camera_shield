module i2c_master_shell
#(
	parameter 	prescale = 1
)
(
	input	sys_clk,
	input	sys_rst,
	
	input	[23:0]	s_address	,				// старший байт - номер устройства, младшие - номер регистра
	input	[15:0]	s_wdata		,				// данные к записи
	input			s_wvalid	,				// строб записываемых данных
	output			s_wready	,				// готов к записи
	output			s_write_ack ,				// подтверждение записи
	output	[15:0]	s_rdata		,				// прочитанные данные
	output			s_rvalid	,				// строб прочитанных данных
	input			s_rreq		,				// запрос чтения
	
	/*
     * I2C interface
    */
    input  wire        scl_i,
    output wire        scl_o,
    output wire        scl_t,
    input  wire        sda_i,
    output wire        sda_o,
    output wire        sda_t
	
);

// To i2c master block

reg [6:0]   s_axis_cmd_address;
reg         s_axis_cmd_start;
reg         s_axis_cmd_read;
reg         s_axis_cmd_write;
reg         s_axis_cmd_write_multiple;
reg         s_axis_cmd_stop;
reg         s_axis_cmd_valid;
wire        s_axis_cmd_ready;

// Данные для записи
reg 	[7:0]   s_axis_data_tdata;
reg 			s_axis_data_tvalid;
wire			s_axis_data_tready;
reg 			s_axis_data_tlast;

// Выдача прочитанных данных из ядра
wire  	[7:0]   m_axis_data_tdata;
wire  	        m_axis_data_tvalid;
reg   	        m_axis_data_tready;
wire  	        m_axis_data_tlast;

reg	[7:0]	device_addr;							// Команды
reg	[7:0] 	reg_addr;
reg	[15:0]	read_data;
reg	[15:0]	data_to_write;
reg			start_write;
reg			start_read;

reg			data_hv_read;							// Статусы 
reg			data_hv_written;

assign		s_wready = s_axis_cmd_ready & !start_write & !start_read;
assign		s_rvalid = data_hv_read;
assign		s_rdata	 = read_data;
assign 		s_write_ack = data_hv_written;

wire        s_wvalid_front;
wire        s_rreq_front;

reg         s_wvalid_d;
reg         s_rreq_d;

assign      s_rreq_front = ~s_rreq_d & s_rreq_d;
assign      s_wvalid_front = ~s_wvalid_d & s_wvalid;

always @(posedge sys_clk)
begin

    if (sys_rst) begin
		start_write <= 0;
		start_read 	<= 0;
        s_wvalid_d  <= 0;
        s_rreq_d    <= 0;
	end
    else begin
        s_wvalid_d  <= s_wvalid;
        s_rreq_d    <= s_rreq;
    end

	if (s_rreq_front) begin
		device_addr <= s_address[23:16];
		reg_addr	<= s_address[15:8];
		start_read	<= 1;
	end
	if (data_hv_read) begin
		start_read <= 0;
	end
	
	if (s_wvalid_front) begin
		device_addr <= s_address[23:16];
		reg_addr	<= s_address[15:8];
		data_to_write <= s_wdata;
		start_write	<= 1;
	end
	if (data_hv_written) begin
		start_write <= 0;
	end
end

// цикл операции с матрицей (чтения/записи 16-битных регистров)

reg		[3:0] 	operations_cntr;

always @(posedge sys_clk)
begin
	if (sys_rst) begin
		operations_cntr <= 0;
		
		s_axis_cmd_start <= 0;
		s_axis_cmd_read  <= 0;
		s_axis_cmd_write <= 0;
		s_axis_cmd_stop  <= 0;
		s_axis_cmd_write_multiple <= 0;
		s_axis_cmd_valid <= 0;
		m_axis_data_tready	<= 0;
		s_axis_data_tvalid  <= 0;
		
		data_hv_read	<= 0;
		data_hv_written <= 0;
	end
	
	if (start_read) begin								// Операция чтения
		if (operations_cntr == 0) begin					// Записать адрес регистра
			if (s_axis_cmd_ready) begin
				s_axis_cmd_address  <= device_addr;
				s_axis_cmd_write	<= 1;
				s_axis_cmd_valid    <= 1;
				
				operations_cntr <= operations_cntr + 1;
			end
		end
		if (operations_cntr == 1) begin
			s_axis_cmd_write	<= 0;
			s_axis_cmd_valid    <= 0;
			
			if (s_axis_data_tready) begin
				s_axis_data_tdata 	<= reg_addr;
				s_axis_data_tvalid	<= 1;
				
				operations_cntr <= operations_cntr + 1;
			end
		end
		if (operations_cntr == 2) begin
			s_axis_data_tvalid	<= 0;
			if (s_axis_cmd_ready) begin					// Адрес регистра записан, можем начинать чтение старшего Байта
				s_axis_cmd_address  <= device_addr;
				s_axis_cmd_read		<= 1;
				s_axis_cmd_valid    <= 1;
				
				m_axis_data_tready	<= 1;
				
				operations_cntr <= operations_cntr + 1;
			end
		end
		if (operations_cntr == 3) begin
			s_axis_cmd_read		<= 0;
			s_axis_cmd_valid    <= 0;
			if (m_axis_data_tvalid) begin
				read_data[15:8] <= m_axis_data_tdata;
				
				operations_cntr <= operations_cntr + 1;
			end
		end
		if (operations_cntr == 4) begin					// Записать регистр 0xF0
			if (s_axis_cmd_ready) begin
				s_axis_cmd_address  <= device_addr;
				s_axis_cmd_write <= 1;
				s_axis_cmd_valid <= 1;
				
				operations_cntr <= operations_cntr + 1;
			end
		end
		if (operations_cntr == 5) begin
			s_axis_cmd_write	<= 0;
			s_axis_cmd_valid    <= 0;
			
			if (s_axis_data_tready) begin
				s_axis_data_tdata 	<= 8'hF0;
				s_axis_data_tvalid	<= 1;
				
				operations_cntr <= operations_cntr + 1;
			end
		end
		if (operations_cntr == 6) begin					
			s_axis_data_tvalid	<= 0;
			if (s_axis_cmd_ready) begin					// Адрес 0xF0 записан, можем начинать чтение младшего Байта
				s_axis_cmd_address  <= device_addr;
				s_axis_cmd_read		<= 1;
				s_axis_cmd_valid    <= 1;
				
				m_axis_data_tready	<= 1;
				
				operations_cntr <= operations_cntr + 1;
			end
		end
		if (operations_cntr == 7) begin					// Младший байт прочитан - выставляем статус, выходим из операции
			s_axis_cmd_read		<= 0;
			s_axis_cmd_valid    <= 0;
			
			if (m_axis_data_tvalid) begin
				read_data[7:0] <= m_axis_data_tdata;
				
				data_hv_read 	<= 1;
				operations_cntr <= operations_cntr + 1;
			end
		end
		if (operations_cntr == 8) begin
			data_hv_read 	<= 0;
			operations_cntr <= 0;
		end
	end
	if (start_write) begin								// Операция записи
		if (operations_cntr == 0) begin					// Записать адрес регистра
			if (s_axis_cmd_ready) begin
				s_axis_cmd_address  <= device_addr;
				s_axis_cmd_write	<= 1;
				s_axis_cmd_valid    <= 1;
				
				operations_cntr <= operations_cntr + 1;			
			end
		end
		if (operations_cntr == 1) begin
			s_axis_cmd_write	<= 0;
			s_axis_cmd_valid    <= 0;
			
			if (s_axis_data_tready) begin
				s_axis_data_tdata 	<= reg_addr;
				s_axis_data_tvalid	<= 1;
				
				operations_cntr <= operations_cntr + 1;
			end
		end
		if (operations_cntr == 2) begin
			s_axis_data_tvalid	<= 0;
			if (s_axis_cmd_ready) begin					// Адрес регистра записан, можем начинать запись старшего Байта
				s_axis_cmd_address  <= device_addr;
				s_axis_cmd_write	<= 1;
				s_axis_cmd_valid    <= 1;
		
				operations_cntr <= operations_cntr + 1;
			end
		end
		if (operations_cntr == 3) begin
			s_axis_cmd_write	<= 0;
			s_axis_cmd_valid    <= 0;
			
			if (s_axis_data_tready) begin
				s_axis_data_tdata 	<= data_to_write[15:8];
				s_axis_data_tvalid	<= 1;
				
				operations_cntr <= operations_cntr + 1;
			end			
		end
		if (operations_cntr == 4) begin					// Записать регистр 0xF0
			s_axis_data_tvalid	<= 0;
			if (s_axis_cmd_ready) begin
				s_axis_cmd_address  <= device_addr;
				s_axis_cmd_write <= 1;
				s_axis_cmd_valid <= 1;
				
				operations_cntr <= operations_cntr + 1;
			end
		end
		if (operations_cntr == 5) begin
			s_axis_cmd_write	<= 0;
			s_axis_cmd_valid    <= 0;
			
			if (s_axis_data_tready) begin
				s_axis_data_tdata 	<= data_to_write[7:0];
				s_axis_data_tvalid	<= 1;
				
				operations_cntr <= operations_cntr + 1;
			end
		end
		if (operations_cntr == 6) begin					// Младший байт записан - выставляем статус, выходим из операции
			s_axis_data_tvalid	<= 0;
			if (s_axis_cmd_ready) begin					
				data_hv_written <= 1;
								
				operations_cntr <= operations_cntr + 1;
				
				s_axis_cmd_stop  <= 1;
				s_axis_cmd_valid <= 1;
			end
		end
		if (operations_cntr == 7) begin
			data_hv_written 	<= 0;
			operations_cntr 	<= 0;
			
			s_axis_cmd_stop  <= 0;
			s_axis_cmd_valid <= 0;
		end
		
	end
end

i2c_master i2c_master_inst 
(
    .clk			(sys_clk),
    .rst			(sys_rst),

    /*
     * Host interface
     */
    .s_axis_cmd_address					(s_axis_cmd_address)	,
    .s_axis_cmd_start					(s_axis_cmd_start)		,
    .s_axis_cmd_read					(s_axis_cmd_read)		,
    .s_axis_cmd_write					(s_axis_cmd_write)		,
    .s_axis_cmd_write_multiple        	(s_axis_cmd_write_multiple)	,
    .s_axis_cmd_stop        			(s_axis_cmd_stop)			,
    .s_axis_cmd_valid					(s_axis_cmd_valid)			,
    .s_axis_cmd_ready					(s_axis_cmd_ready)			,

    .s_axis_data_tdata					(s_axis_data_tdata)			,
    .s_axis_data_tvalid					(s_axis_data_tvalid)		,
    .s_axis_data_tready					(s_axis_data_tready)		,
    .s_axis_data_tlast					(s_axis_data_tlast)			,

    .m_axis_data_tdata					(m_axis_data_tdata)			,
	.m_axis_data_tvalid					(m_axis_data_tvalid)		,
    .m_axis_data_tready					(m_axis_data_tready)		,
    .m_axis_data_tlast					(m_axis_data_tlast)			,

    /*
     * I2C interface
     */
    .scl_i								(scl_i)						,
    .scl_o								(scl_o)						,
    .scl_t								(scl_t)						,
    .sda_i                              (sda_i)						,
    .sda_o                              (sda_o)						,
    .sda_t                              (sda_t)						,

    /*
     * Status
     */
    .busy			(busy)			,
    .bus_control	(bus_control)	,
    .bus_active		(bus_active)	,
    .missed_ack		(missed_ack)	,

    /*
     * Configuration
     */
    .prescale		(prescale)		,
    .stop_on_idle	()
);

endmodule