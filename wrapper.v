`default_nettype none
`ifdef FORMAL
    `define MPRJ_IO_PADS 38
`endif
// update this to the name of your module
module zube_wrapped_project(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif
    // wishbone interface
    input wire wb_clk_i,            // clock, runs at system clock
    input wire wb_rst_i,            // main system reset
    input wire wbs_stb_i,           // wishbone write strobe
    input wire wbs_cyc_i,           // wishbone cycle
    input wire wbs_we_i,            // wishbone write enable
    input wire [3:0] wbs_sel_i,     // wishbone write word select
    input wire [31:0] wbs_dat_i,    // wishbone data in
    input wire [31:0] wbs_adr_i,    // wishbone address
    output wire wbs_ack_o,          // wishbone ack
    output wire [31:0] wbs_dat_o,   // wishbone data out

    // Logic Analyzer Signals
    // only provide first 32 bits to reduce wiring congestion
    input  wire [31:0] la_data_in,  // from PicoRV32 to your project
    output wire [31:0] la_data_out, // from your project to PicoRV32
    input  wire [31:0] la_oenb,     // output enable bar (low for active)

    // IOs
    input  wire [`MPRJ_IO_PADS-1:0] io_in,  // in to your project
    output wire [`MPRJ_IO_PADS-1:0] io_out, // out fro your project
    output wire [`MPRJ_IO_PADS-1:0] io_oeb, // out enable bar (low active)

    // IRQ
    output wire [2:0] irq,          // interrupt from project to PicoRV32

    // extra user clock
    input wire user_clock2,

    // active input, only connect tristated outputs if this is high
    input wire active
);

    // all outputs must be tristated before being passed onto the project
    wire buf_wbs_ack_o;
    wire [31:0] buf_wbs_dat_o;
    wire [31:0] buf_la_data_out;
    wire [`MPRJ_IO_PADS-1:0] buf_io_out;
    wire [`MPRJ_IO_PADS-1:0] buf_io_oeb;
    wire [2:0] buf_irq;

    `ifdef FORMAL
    // formal can't deal with z, so set all outputs to 0 if not active
    assign wbs_ack_o    = active ? buf_wbs_ack_o    : 1'b0;
    assign wbs_dat_o    = active ? buf_wbs_dat_o    : 32'b0;
    assign la_data_out  = active ? buf_la_data_out  : 32'b0;
    assign io_out       = active ? buf_io_out       : {`MPRJ_IO_PADS{1'b0}};
    assign io_oeb       = active ? buf_io_oeb       : {`MPRJ_IO_PADS{1'b0}};
    assign irq          = active ? buf_irq          : 3'b0;
    `include "properties.v"
    `else
    // tristate buffers
    assign wbs_ack_o    = active ? buf_wbs_ack_o    : 1'bz;
    assign wbs_dat_o    = active ? buf_wbs_dat_o    : 32'bz;
    assign la_data_out  = active ? buf_la_data_out  : 32'bz;
    assign io_out       = active ? buf_io_out       : {`MPRJ_IO_PADS{1'bz}};
    assign io_oeb       = active ? buf_io_oeb       : {`MPRJ_IO_PADS{1'bz}};
    assign irq          = active ? buf_irq          : 3'bz;
    `endif

    // set oeb so that unused outputs (top 2, bottom 8) are enabled
    assign buf_io_oeb[`MPRJ_IO_PADS-1:36] = 2'b11;
    assign buf_io_out[`MPRJ_IO_PADS-1:36] = 2'b0;
    assign buf_io_oeb[7:0] = 8'hFF;
    assign buf_io_out[7:0] = 8'h0;
    // Set unused LA bits
    assign buf_la_data_out[31:0] = 32'h00000000;
    // Set unused IRQs
    assign buf_irq[2:1] = 2'b0;

    // Instantiate your module here,
    // connecting what you need of the above signals.
    // Use the buffered outputs for your module's outputs.
    zube_wrapper zube_wrapper0(
`ifdef USE_POWER_PINS
    .vccd1(vccd1),  // User area 1 1.8V power
    .vssd1(vssd1),  // User area 1 digital ground
`endif

    .clk(wb_clk_i),
    .reset_b(la_data_in[0]),
    // GPIO 37, 36 and 7..0 are used by other things
    .io_in(io_in[35:8]),
    .io_out(buf_io_out[35:8]),
    .io_oeb(buf_io_oeb[35:8]),
    .wb_cyc_in(wbs_cyc_i),
    .wb_stb_in(wbs_stb_i),
    .wb_we_in(wbs_we_i),
    .wb_addr_in(wbs_adr_i),
    .wb_data_in(wbs_dat_i),
    .wb_ack_out(buf_wbs_ack_o),
    .wb_data_out(buf_wbs_dat_o),
    .irq_out(buf_irq[0])

    );

endmodule
`default_nettype wire
