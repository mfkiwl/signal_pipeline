`timescale 1ns / 100ps
module axi_ddr3_top
(
 clock,
 reset,

 axi_awvalid_i,
 axi_awready_o,
 axi_awaddr_i,
 axi_awid_i,
 axi_awlen_i,
 axi_awburst_i,

 axi_wvalid_i,
 axi_wready_o,
 axi_wlast_i,
 axi_wstrb_i,
 axi_wdata_i,

 axi_bvalid_o,
 axi_bready_i,
 axi_bresp_o,
 axi_bid_o,

 axi_arvalid_i,
 axi_arready_o,
 axi_araddr_i,
 axi_arid_i,
 axi_arlen_i,
 axi_arburst_i,

 axi_rready_i,
 axi_rvalid_o,
 axi_rlast_o,
 axi_rresp_o,
 axi_rid_o,
 axi_rdata_o,

 ddr_cke_o
 );

// Settings for DLL=off mode
parameter DDR_FREQ_MHZ = 100;
parameter DDR_CL = 6;
parameter DDR_CWL = 6;

// Size of bursts from memory controller perspective
parameter DDR_BURSTLEN = 4;

// Address widths
parameter DDR_ROW_BITS = 15;
localparam RSB = DDR_ROW_BITS - 1;
parameter DDR_COL_BITS = 10;
localparam CSB = DDR_COL_BITS - 1;

localparam ASB = DDR_ROW_BITS + DDR_COL_BITS - 1; // todo ...

// Data-path widths
parameter PHY_DAT_BITS = DDR_DQ_WIDTH*2;
localparam MSB = PHY_DAT_BITS - 1;
parameter PHY_STB_BITS = DDR_DM_WIDTH*2;
localparam SSB = PHY_STB_BITS - 1;

// AXI4 interconnect properties
  parameter AXI_ID_WIDTH = 4;
  localparam ISB = AXI_ID_WIDTH - 1;


input clock;
input reset;

input axi_awvalid_i;  // AXI4 Write Address Port
output axi_awready_o;
input [ASB:0] axi_awaddr_i;
input [ISB:0] axi_awid_i;
input [7:0] axi_awlen_i;
input [1:0] axi_awburst_i;
input axi_wvalid_i;  // AXI4 Write Data Port
output axi_wready_o;
input [MSB:0] axi_wdata_i;
input [SSB:0] axi_wstrb_i;
input axi_wlast_i;
output axi_bvalid_o;  // AXI4 Write Response
input axi_bready_i;
output [1:0] axi_bresp_o;
output [ISB:0] axi_bid_o;

input axi_arvalid_i;  // AXI4 Read Address Port
output axi_arready_o;
input [ASB:0] axi_araddr_i;
input [ISB:0] axi_arid_i;
input [7:0] axi_arlen_i;
input [1:0] axi_arburst_i;
input axi_rready_i;  // AXI4 Read Data Port
output axi_rvalid_o;
output [MSB:0] axi_rdata_o;
output [1:0] axi_rresp_o;
output [ISB:0] axi_rid_o;
output axi_rlast_o;

output ddr_cke_o;


wire [MSB:0] wdata, rdata;


// -- AXI Requests to DDR3 Requests -- //

ddr3_axi_ctrl
#( .DDR_FREQ_MHZ(DDR_FREQ_MHZ)
) ddr3_axi_ctrl_inst
(  .clock(clock),
   .reset(reset),

   .axi_awvalid_i(axi_awvalid_i),  // AXI4 Write Address Port
   .axi_awready_o(axi_awready_o),
   .axi_awid_i(axi_awid_i),
   .axi_awlen_i(axi_awlen_i),
   .axi_awburst_i(axi_awburst_i),
   .axi_awaddr_i(axi_awaddr_i),

   .axi_wvalid_i(axi_wvalid_i),  // AXI4 Write Data Port
   .axi_wready_o(axi_wready_o),
   .axi_wlast_i (axi_wlast_i),
   .axi_wstrb_i (axi_wstrb_i),
   .axi_wdata_i (axi_wdata_i),

   .axi_bvalid_o(axi_bvalid_o),  // AXI4 Write Response Port
   .axi_bready_i(axi_bready_i),
   .axi_bid_o(axi_bid_o),
   .axi_bresp_o(axi_bresp_o),

   .axi_arvalid_i(axi_arvalid_i),
   .axi_arready_o(axi_arready_o),
   .axi_arid_i(axi_arid_i),
   .axi_arlen_i(axi_arlen_i),
   .axi_arburst_i(axi_arburst_i),
   .axi_araddr_i(axi_araddr_i),

   .axi_rvalid_o(axi_rvalid_o),
   .axi_rready_i(axi_rready_i),
   .axi_rlast_o(axi_rlast_o),
   .axi_rresp_o(axi_rresp_o),
   .axi_rid_o(axi_rid_o),
   .axi_rdata_o(axi_rdata_o),

   .mem_store_o(mem_store),
   .mem_fetch_o(mem_fetch),
   .mem_accept_i(mem_accept),
   .mem_rddata_i(mem_rdata)
);


// -- DDR3 Memory Controller -- //

ddr3_fsm
#( .DDR_BURSTLEN(DDR_BURSTLEN),
   .DDR_ROW_BITS(DDR_ROW_BITS),
   .DDR_COL_BITS(DDR_COL_BITS),
   .DDR_FREQ_MHZ(DDR_FREQ_MHZ)
) ddr3_fsm_inst
(  .clock(clock),
   .reset(reset),

   .dfi_wdata_o(wdata),
   .dfi_rdata_i(rdata)
);


// -- PHY for DDR3, and Architecture-Specific -- //

ddr3_phy
#( .DDR_BURSTLEN(DDR_BURSTLEN),
   .DDR_ROW_BITS(DDR_ROW_BITS),
   .DDR_COL_BITS(DDR_COL_BITS),
   .DDR_FREQ_MHZ(DDR_FREQ_MHZ),
   .DDR_DQ_WIDTH(DDR_DQ_WIDTH),
   .DDR_DM_WIDTH(DDR_DM_WIDTH)
) ddr3_phy_inst
(  .clock(clock),
   .reset(reset),

   .ddr_cke_o(ddr_cke_o),

   .dfi_data_i(wdata),
   .dfi_data_o(rdata)
);


endmodule // axi_ddr3_top
