`default_nettype none

module m_Top_Module_User
#(
    parameter BITS = 32,
	 parameter MPRJ_IO_PADS = 38
)
(

`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire wbs_stb_i,
    input wire wbs_cyc_i,
    input wire wbs_we_i,
    input wire [3:0] wbs_sel_i,
    input wire [31:0] wbs_dat_i,
    input wire [31:0] wbs_adr_i,
    output wire wbs_ack_o,
    output wire [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  wire [127:0] la_data_in,
    output wire [127:0] la_data_out,
    input  wire [127:0] la_oenb,

    // IOs
    input wire [MPRJ_IO_PADS-1:0] io_in,
    output wire [MPRJ_IO_PADS-1:0] io_out,
    output wire [MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output wire [2:0] irq
);
    wire clk;
    wire rst;

    wire valid;
    wire [3:0] wstrb;
    wire [31:0] la_write;

    // WB MI A
    assign valid = wbs_cyc_i && wbs_stb_i; // if a (bus cycle is in progress) and (the current SLAVE is selected) asserted valid
    assign wstrb = wbs_sel_i & {4{wbs_we_i}}; //Indicates when and which byte of the counter is to be written

    // IO
    assign io_oeb = {(MPRJ_IO_PADS-1){rst}};  //Output GPIO, module status 

    // IRQ
    assign irq = 3'b000;	// Unused

    // LA
    assign la_data_out = {{(127-BITS){1'b0}}, io_out}; //Sends the count data to the microcontroller via the logic analyzer signals.
    // Assuming LA probes [63:32] are for controlling the count register  
    assign la_write = ~la_oenb[63:32] & ~{BITS{valid}};// control signal to write a value from the microcontroller to the counter 
    // Assuming LA probes [65:64] are for controlling the count clk & reset  
    assign clk = (~la_oenb[64]) ? la_data_in[64]: wb_clk_i;
    assign rst = (~la_oenb[65]) ? la_data_in[65]: wb_rst_i;

    counter #(
        .BITS(BITS)
    ) counter(
        .clk(clk),
        .reset(rst),
		  .clk_enb(la_oenb[66]), //clock enable
        .ready(wbs_ack_o),
        .valid(valid),
        .rdata(wbs_dat_o),   //Output data Wishbone
        .wdata(wbs_dat_i),	  //Input data Wishbone
        .wstrb(wstrb),
        .la_write(la_write),
        .la_input(la_data_in[63:32]),
        .count(io_out) 		 //Output count GPIO
    );

endmodule
