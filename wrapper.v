`default_nettype none
`ifdef FORMAL
    `define MPRJ_IO_PADS 38
`endif

`define USE_WB  1
`define USE_LA  1
`define USE_IO  1
//`define USE_MEM 0
`define USE_IRQ 1

module zube_wrapped_project (
`ifdef USE_POWER_PINS
    inout vccd1,
    inout vssd1,
`endif
    // interface as user_proj_example.v
    input wire wb_clk_i,
`ifdef USE_WB
    input wire wb_rst_i,
    input wire wbs_stb_i,
    input wire wbs_cyc_i,
    input wire wbs_we_i,
    input wire [3:0] wbs_sel_i,
    input wire [31:0] wbs_dat_i,
    input wire [31:0] wbs_adr_i,
    output wire wbs_ack_o,
    output wire [31:0] wbs_dat_o,
`endif

    // Logic Analyzer Signals
    // only provide first 32 bits to reduce wiring congestion
`ifdef USE_LA
    input  wire [31:0] la1_data_in,
    output wire [31:0] la1_data_out,
    input  wire [31:0] la1_oenb,
`endif

    // IOs
`ifdef USE_IO
    input  wire [`MPRJ_IO_PADS-1:0] io_in,
    output wire [`MPRJ_IO_PADS-1:0] io_out,
    output wire [`MPRJ_IO_PADS-1:0] io_oeb,
`endif

    // IRQ
`ifdef USE_IRQ
    output wire [2:0] user_irq,
`endif

`ifdef USE_CLK2
    // extra user clock
    input wire user_clock2,
`endif

    // active input, only connect tristated outputs if this is high
    input wire active
);

    // all outputs must be tristated before being passed onto the project
    wire buf_wbs_ack_o;
    wire [31:0] buf_wbs_dat_o;
    wire [31:0] buf_la1_data_out;
    wire [`MPRJ_IO_PADS-1:0] buf_io_out;
    wire [`MPRJ_IO_PADS-1:0] buf_io_oeb;
    wire [2:0] buf_user_irq;

    `ifdef FORMAL
    // formal can't deal with z, so set all outputs to 0 if not active
    `ifdef USE_WB
    assign wbs_ack_o    = active ? buf_wbs_ack_o    : 1'b0;
    assign wbs_dat_o    = active ? buf_wbs_dat_o    : 32'b0;
    `endif
    `ifdef USE_LA
    assign la1_data_out = active ? buf_la1_data_out  : 32'b0;
    `endif
    `ifdef USE_IO
    assign io_out       = active ? buf_io_out       : {`MPRJ_IO_PADS{1'b0}};
    assign io_oeb       = active ? buf_io_oeb       : {`MPRJ_IO_PADS{1'b0}};
    `endif
    `ifdef USE_IRQ
    assign user_irq     = active ? buf_user_irq     : 3'b0;
    `endif
    `include "properties.v"
    `else
    // tristate buffers

    `ifdef USE_WB
    assign wbs_ack_o    = active ? buf_wbs_ack_o    : 1'bz;
    assign wbs_dat_o    = active ? buf_wbs_dat_o    : 32'bz;
    `endif
    `ifdef USE_LA
    assign la1_data_out  = active ? buf_la1_data_out  : 32'bz;
    `endif
    `ifdef USE_IO
    assign io_out       = active ? buf_io_out       : {`MPRJ_IO_PADS{1'bz}};
    assign io_oeb       = active ? buf_io_oeb       : {`MPRJ_IO_PADS{1'bz}};
    `endif
    `ifdef USE_IRQ
    assign user_irq     = active ? buf_user_irq     : 3'bz;
    `endif
    `endif

    // set oeb so that unused outputs (top 2, bottom 8) are enabled
    assign buf_io_oeb[`MPRJ_IO_PADS-1:36] = 2'b11;
    assign buf_io_out[`MPRJ_IO_PADS-1:36] = 2'b0;
    assign buf_io_oeb[7:0] = 8'hFF;
    assign buf_io_out[7:0] = 8'h0;
    // Set unused LA bits
    assign buf_la1_data_out[31:0] = 32'h00000000;
    // Set unused IRQs
    assign buf_user_irq[2:1] = 2'b0;

    // Instantiate your module here,
    // connecting what you need of the above signals.
    // Use the buffered outputs for your module's outputs.
    zube_wrapper zube_wrapper0(
    .clk(wb_clk_i),
    .reset_b(la1_data_in[0]),
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
    .irq_out(buf_user_irq[0])

    );

endmodule
`default_nettype wire
