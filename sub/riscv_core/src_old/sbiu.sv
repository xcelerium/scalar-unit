
module sbiu
   import riscv_core_pkg::*;
#(
   //parameter AW = 32
)
(
   input logic clk,
   input logic arst_n,

   // ---------
   // AXI Slave Interface
   //   this module is a slave on ext AXI
   // ---------

   // Read Address Channel
   input  logic      slv_axi_arvalid,
   output logic      slv_axi_arready,
   input  saxi_ar_t  slv_axi_ar,
   
   // Write Address Channel
   input  logic      slv_axi_awvalid,
   output logic      slv_axi_awready,
   input  saxi_aw_t  slv_axi_aw,
   
   // Write Data Channel
   input  logic      slv_axi_wvalid,
   output logic      slv_axi_wready,
   input  saxi_w_t   slv_axi_w,
   
   // Read Response Channel
   output logic      slv_axi_rvalid,
   input  logic      slv_axi_rready,
   output saxi_r_t   slv_axi_r,
   
   // Write Response Channel
   output logic      slv_axi_bvalid,
   input  logic      slv_axi_bready,
   output saxi_b_t   slv_axi_b,

   // ---------
   // Master 0
   //   currently RIF
   //   Used to access core's internal slave(s)
   // ---------

   // Address & Write Data Channel
   output logic                      mst0_rif_val,
   input  logic                      mst0_rif_rdy,
   output logic [P.IMC_SRIF_AW-1:0]  mst0_rif_addr,
   output logic [P.IMC_SRIF_DW-1:0]  mst0_rif_wdata,
   output logic                      mst0_rif_we,
   output logic [P.IMC_SRIF_NBE-1:0] mst0_rif_be,

   // Read Data Channel
   input  logic                      mst0_rif_rdata_val,
   output logic                      mst0_rif_rdata_rdy,
   input  logic [P.IMC_SRIF_DW-1:0]  mst0_rif_rdata,

   // ---------
   // Master 1
   //   currently RIF
   //   Used to access core's internal slave(s)
   // ---------

   // Address & Write Data Channel
   output logic                      mst1_rif_val,
   input  logic                      mst1_rif_rdy,
   output logic [P.DMC_SRIF_AW-1:0]  mst1_rif_addr,
   output logic [P.DMC_SRIF_DW-1:0]  mst1_rif_wdata,
   output logic                      mst1_rif_we,
   output logic [P.DMC_SRIF_NBE-1:0] mst1_rif_be,

   // Read Data Channel
   input  logic                      mst1_rif_rdata_val,
   output logic                      mst1_rif_rdata_rdy,
   input  logic [P.DMC_SRIF_DW-1:0]  mst1_rif_rdata

);

   // Functional requirements
   // Support burst accesses
   // Support full-duplex AXI to simul mst0 & mst1
   
   // V0 Temp requirement relaxation
   // burst access support is optional



endmodule: sbiu
