//
//	Данный модуль потребовался для того, что бы нивелировать следующий вредоносный эффект: 
//	в slave-режиме при старте кадра на один такт так же проваливался бланк строки, что выдавало строку длиной один такт прямо в начале кадра, 
//  что вызывало отбраковку кадра, в котором, в дальнейшем, всё, в общем, было неплохо.
//

module gaps_remover
(
	input 			clkin_27,
	
	input 			frame_valid_n	,
	input			line_valid_n	,
	input 	[13:0]	data			,
	
	output			out_frame_valid_n	,
	output			out_line_valid_n	,
	output	[13:0]	out_data
);

reg			frm_d1, frm_d2, frm_d3;
reg 		ln_d1, ln_d2, ln_d3;

reg [13:0]	data_d1, data_d2, data_d3;

/*assign out_frame_valid_n = frm_d3;
assign out_line_valid_n = ln_d3;
assign out_data = data_d3;*/

//BYPASS mode
assign out_frame_valid_n = frame_valid_n;
assign out_line_valid_n = line_valid_n;
assign out_data = data;

always	@(posedge clkin_27)
begin
	data_d1 <= data;
	data_d2 <= data_d1;
	data_d3 <= data_d2;
	
	frm_d1	<= frame_valid_n;
	frm_d2  <= frm_d1;
	frm_d3  <= frm_d2;
	
	ln_d1 <= line_valid_n;
	ln_d2 <= ln_d1;
	
	if (ln_d3 == 1 && ln_d1 == 1) begin				// ликвидация провала в 1
		ln_d3 <= 1;
	end 
	else begin
		ln_d3 <= ln_d2;
	end

end

endmodule
