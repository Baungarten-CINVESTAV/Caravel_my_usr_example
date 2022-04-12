
module counter #(
    parameter BITS = 32
)(
    input wire clk,
    input wire reset,
	 input wire clk_enb,
    input wire valid,
    input wire [3:0] wstrb,
    input wire [BITS-1:0] wdata,
    input wire [BITS-1:0] la_write,
    input wire [BITS-1:0] la_input,
    output wire ready,
    output wire [BITS-1:0] rdata,
    output wire [BITS-1:0] count
);
	 reg o_ready_d;
	 reg o_ready_q;
	 
	 reg [BITS-1:0] o_rdata_d;
	 reg [BITS-1:0] o_rdata_q;

	 reg [BITS-1:0] o_count_d;
	 reg [BITS-1:0] o_count_q;

	 assign ready = o_ready_q;
	 assign count = o_count_q;
	 
	 assign rdata = (valid)? o_count_q:o_rdata_q;
	 
	 always@(posedge clk or posedge reset)
	 begin
		if(reset)
		begin
			o_rdata_q <= 0;
			o_ready_q <= 0;
			o_count_q <= 0;
		end
		else if(clk_enb)
		begin
			o_rdata_q <= o_rdata_d;
			o_ready_q <= o_ready_d & valid;
			o_count_q <= o_count_d;
		end
		else
		begin
			o_rdata_q <= o_rdata_q;
			o_ready_q <= o_ready_q;
			o_count_q <= o_count_q;
		end
	 end
	 
always@*
begin
	o_ready_d = 1'd0;
	o_rdata_d = o_rdata_q;
	o_count_d = o_count_q;
	if (~|la_write) //if valid==1 or if la_oenb has one bit asserted the counter will start counting
	begin
		o_count_d = o_count_q + 1'd1;
	end
	
	if (valid && !o_ready_d)
	begin
	 o_ready_d = 1'b1;
	 o_rdata_d = o_count_q;
	 if (wstrb[0]) o_count_d[7:0]   = wdata[7:0];
	 if (wstrb[1]) o_count_d[15:8]  = wdata[15:8];
	 if (wstrb[2]) o_count_d[23:16] = wdata[23:16];
	 if (wstrb[3]) o_count_d[31:24] = wdata[31:24];
	 end 
	 else if (|la_write) 
	 begin
	 o_count_d <= la_write & la_input;
	end
end
	 
endmodule 