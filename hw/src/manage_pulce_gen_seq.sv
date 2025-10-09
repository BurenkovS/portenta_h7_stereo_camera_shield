//
//	 	Модуль, генерирующий управляющие импульсы. 
//		
//
//		Simultaneous_mode 	- новый кадр снимается, старый - вычитывается (в этом режиме больший fps).
// 		Sequential mode		- снимаем текущий кадр, затем его выдаём

`define		MODE_SEQUENTIAL			1
`define		MODE_SIMULTANEOUS		0

`define		DEFAULT_LINE_LENGTH		752
`define		MINIMAL_START_LINE_T	659
`define		MIN_LINE_DECREASING		589				// минимальный размер строки, при котором мы уменьшаем межстрочную паузу
													// если строку зададут меньше этого размера, межстрочная пауза всё равно

module manage_pulce_gen_seq
(
	input				clk_27M			,
	input				rst				,
	
	input 	[9:0]		param_frame_width	,						// длина строки
	input	[8:0]		param_frame_height	,						// количество строк

	input 	[10:0]		param_start_line_base	,					// две составляющие для управления start_line
	input 	[10:0]		param_start_line_gap	,
	
	output		 	 	exposure		,
	output				start_frame		,
	output				start_line		,
		
	input	[23:0]		target_EXPOSURE		, 						// целевой показатель 
	
	// ! ВНИМАНИЕ ! это сигнал домена входного dcmi_pix clk !
	input				dcmi_vsync									// вход строба кадра (мы не должны, даже при неправильных настройках, выдавать запрос нового кадра пока идёт текущий)
	
);

parameter VSYNC_ACTIVE = 0;												// когда такой уровень - кадра нет
parameter START_DELAY =  31'd2_700_000/10;	

reg				dcmi_vsync_27M_dff	;									// защелкнем dcmi_vsync в общий для блока тактовый домен во избежание метастабильности 
reg				dcmi_vsync_27M_dff2	;

reg		[10:0]	pix_in_row_cntr		;										// счётчики времени для выдачи пикселей матрицы
reg		[7:0]	pre_gap_cntr		;

reg				run_frame_givout;
reg				run_pre_cntr;

reg				start_line_d1;												// Растянем импульсы на три такта
reg				start_line_d2;
reg				start_line_int;

reg				start_frame_d1;
reg				start_frame_d2;
reg				start_frame_int;

reg				exposure_d1;
reg				exposure_d2;
reg				exposure_int;

reg 	[10:0]	loc_param_frame_width;						// внутренние экземпляры, что бы параметры не менялись "налету"
reg		[9:0]	loc_param_frame_height;
reg		[23:0]	loc_exp_to_read	;							
reg		[24:0]	loc_frame_period	;
reg		[10:0]	loc_start_line_base;
reg		[10:0]	loc_start_line_gap	;

reg		[10:0]	decr;										// насколько текущая длина строки меньше 
// для тестовых режимов
reg		[24:0]	cntr_after_frame_end		;
reg				run_cntr_after_frame_end	;
reg				dcmi_vsync_d1					;
wire			frame_end						;	

reg				first_exp_done		;

reg		[31:0]	start_pulce_delay		;					// задержка стартового импульса
reg				run_start_pulce_delay	;

reg		[24:0]	loc_target_EXPOSURE		;

//////////////////////////////////////////////////////////////////
//	ключевые параметры для управления выдержкой
//////////////////////////////////////////////////////////////////

reg		[23:0]	EXP_shift;							// сколько надо прибавить к положению импульса EXP, если его поставить сразу за loc_minimal_SF2E, что бы получить желаемую выдержку
													// данная величина не равна 0, если целевое значение выдержки меньше, чем [минимальное значение между START_FRAME-ами минус loc_minimal_SF2E]
													// то есть данная переменная будет использоваться в случаях максимального FPS.

////////////////////////////////////////////////////////////////// 
//  переменные для выстраивания обратной связи
////////////////////////////////////////////////////////////////// 
reg				was_start_exp;						// флаг - первый exposure уже был
reg 			was_second_exp;						// флаг - был второй exposure
reg				etalon_init;						// признак - необходимо инициализировать эталон
reg				run_etalon_init;					// на данном кадре идёт вычисление эталонной выдержки
reg		[24:0]	etalon_EXPOSURE	;					// эталонное значение: максимальная выдержка при максимальном FPS
reg		[24:0]	cur_EXPOSURE_measured	;			// измеренное значение от EXPOSURE до START_FRAME
reg				run_cur_EXPOSURE_measure;

// Для sequential-режима
wire	[7:0]	FV2E_shift;							// от конца текущего кадра до EXPOSURE нового

reg				run_cntr_e2sf	;
reg		[31:0]	cntr_e2sf		;


assign			frame_end = ((dcmi_vsync_d1 == !VSYNC_ACTIVE) & (dcmi_vsync_27M_dff2 == VSYNC_ACTIVE)) ? 1 : 0;						// конец кадра

assign exposure 	= exposure_int | exposure_d1 | exposure_d2;
assign start_line 	= start_line_int | start_line_d1 | start_line_d2;
assign start_frame 	= start_frame_int | start_frame_d1 | start_frame_d2;

assign FV2E_shift   = 8;

always @(posedge clk_27M)
begin
	if (rst) begin
		pix_in_row_cntr	<= 0;
		
		exposure_int   <= 1'b0;
		exposure_d1 <= 1'b0;
		exposure_d2 <= 1'b0;  	 
		
		start_line_int <= 1'b0;
		start_line_d1 <= 1'b0;
		start_line_d2 <= 1'b0;
	
		start_frame_int <= 1'b0;
		start_frame_d1 <= 1'b0;
		start_frame_d2 <= 1'b0;	
		
	end
	
	loc_start_line_base	<= param_start_line_base;
	loc_start_line_gap	<= param_start_line_gap;
	
	if (rst) begin										// начальный импульс
		start_pulce_delay 		<= 0;
		run_start_pulce_delay	<= 0;
		first_exp_done			<= 0;
	end
	else begin
		if (run_start_pulce_delay == 0 && first_exp_done == 0) begin
			run_start_pulce_delay	<= 1;
			was_start_exp	<= 0;
			was_second_exp	<= 0;
		end
	end
	
	if ((first_exp_done == 0) && run_start_pulce_delay) begin
		if (start_pulce_delay != START_DELAY) begin			// здесь задержка 1 сек. (27 MHz) будет равна  27_000_000
			start_pulce_delay <= start_pulce_delay + 1;
		end
		else begin
			exposure_int   		<= 1;
			first_exp_done	  	<= 1;
			run_start_pulce_delay	<= 0;
		end
	end
	
	dcmi_vsync_d1 <= dcmi_vsync_27M_dff2;
	
	if (frame_end && first_exp_done) begin							
		cntr_after_frame_end 		<= 0;
		run_cntr_after_frame_end 	<= 1;
	end
	
	if (run_cntr_after_frame_end) begin
		if (cntr_after_frame_end >= FV2E_shift) begin					// в sequential-режиме после окончания кадра отсчитать и запустить exposure 
			run_cntr_after_frame_end	<= 0;
			exposure_int 				<= 1;
		end
		else begin
			cntr_after_frame_end	<= cntr_after_frame_end + 1;
		end
	end
	
	if (exposure_int) begin							
		run_cntr_e2sf	<= 1;											// exposure to start frame 
		cntr_e2sf 		<= 0;
		exposure_int	<= 0;
	end
	
	
	if (run_cntr_e2sf ) begin
		if (cntr_e2sf >= loc_target_EXPOSURE) begin				
			start_frame_int 	<= 1;
			run_cntr_e2sf	    <= 0;
		end
		else begin
			cntr_e2sf		<= cntr_e2sf + 1;
		end
	end
	//
	/////////////////////////////////////////////// формирование start_line ////////////////////////////////////////////////////////
	//
	if (start_frame_int) begin								
		pix_in_row_cntr		<= 0;
				
		start_line_int		<= 0;
		
		run_pre_cntr		<= 1;
		pre_gap_cntr		<= 0;
	end
	
	if (run_pre_cntr) begin									// пауза перед выдачей первой строки
		if (pre_gap_cntr == loc_start_line_gap) begin
			run_frame_givout 	<= 1;
			start_line_int 		<= 1;
			run_pre_cntr		<= 0;
		end
		else begin
			pre_gap_cntr <= pre_gap_cntr + 1;
		end	
	end
		
	if (run_frame_givout) begin								// в SIMULTANEOUS режиме сигнал START_LINE молотит безостановочно
		if (pix_in_row_cntr != (loc_start_line_base + loc_start_line_gap - decr)) begin
			pix_in_row_cntr <= pix_in_row_cntr + 1;
		end
		else begin
			start_line_int <= 1;
			pix_in_row_cntr <= 0;
		end
	end
	if (exposure_int == 1) begin
		run_frame_givout 	<= 0;
	end
	//
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	if (start_frame_int) begin
		start_frame_int <= 0;
	end
	
	if (start_line_int) begin
		start_line_int <= 0;
	end
	
	start_line_d1 <= start_line_int;
	start_line_d2 <= start_line_d1;
	
	start_frame_d1 <= start_frame_int;
	start_frame_d2 <= start_frame_d1;
	
	exposure_d1 <= exposure_int;
	exposure_d2 <= exposure_d1;
	
	dcmi_vsync_27M_dff 	<= dcmi_vsync;										// единственная точка входа сигнала в блок
	dcmi_vsync_27M_dff2	<= dcmi_vsync_27M_dff;
end

always @(posedge clk_27M)
begin
	if (start_frame_int) begin
		loc_param_frame_width <= param_frame_width;
		loc_param_frame_height <= param_frame_height;
	end
	if (start_frame_d1) begin
		if ( `MIN_LINE_DECREASING <= loc_param_frame_width) begin
			decr <= `DEFAULT_LINE_LENGTH - loc_param_frame_width;
		end else begin
			decr <= `DEFAULT_LINE_LENGTH - `MIN_LINE_DECREASING;			// decr не может стать больше 163
		end
	end
	
	if (exposure_int || run_start_pulce_delay) begin						// перезапись локальных копий (и их инициализация)
		loc_target_EXPOSURE	<= target_EXPOSURE	;
	end
end



endmodule