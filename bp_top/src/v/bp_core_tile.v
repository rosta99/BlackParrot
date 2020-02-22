/**
 *
 * bp_core_tile.v
 *
 */

module bp_core_tile
 import bp_common_pkg::*;
 import bp_common_rv64_pkg::*;
 import bp_common_aviary_pkg::*;
 import bp_be_pkg::*;
 import bp_cce_pkg::*;
 import bsg_noc_pkg::*;
 import bp_common_cfg_link_pkg::*;
 import bsg_wormhole_router_pkg::*;
 import bp_me_pkg::*;
 #(parameter bp_params_e bp_params_p = e_bp_inv_cfg
   `declare_bp_proc_params(bp_params_p)
   `declare_bp_me_if_widths(paddr_width_p, cce_block_width_p, lce_id_width_p, lce_assoc_p)
   `declare_bp_lce_cce_if_widths(cce_id_width_p, lce_id_width_p, paddr_width_p, lce_assoc_p, dword_width_p, cce_block_width_p)

   , localparam coh_noc_ral_link_width_lp = `bsg_ready_and_link_sif_width(coh_noc_flit_width_p)
   , localparam mem_noc_ral_link_width_lp = `bsg_ready_and_link_sif_width(mem_noc_flit_width_p)
   )
  (input                                         core_clk_i
   , input                                       core_reset_i

   , input                                       coh_clk_i
   , input                                       coh_reset_i

   , input                                       mem_clk_i
   , input                                       mem_reset_i

   , input [io_noc_did_width_p-1:0]              my_did_i
   , input [coh_noc_cord_width_p-1:0]            my_cord_i

   , input [S:W][coh_noc_ral_link_width_lp-1:0]  coh_lce_req_link_i
   , output [S:W][coh_noc_ral_link_width_lp-1:0] coh_lce_req_link_o

   , input [S:W][coh_noc_ral_link_width_lp-1:0]  coh_lce_cmd_link_i
   , output [S:W][coh_noc_ral_link_width_lp-1:0] coh_lce_cmd_link_o

   , input [S:W][coh_noc_ral_link_width_lp-1:0]  coh_lce_resp_link_i
   , output [S:W][coh_noc_ral_link_width_lp-1:0] coh_lce_resp_link_o

   , input [mem_noc_ral_link_width_lp-1:0]       mem_cmd_link_i
   , output [mem_noc_ral_link_width_lp-1:0]      mem_cmd_link_o

   , input [mem_noc_ral_link_width_lp-1:0]       mem_resp_link_i
   , output [mem_noc_ral_link_width_lp-1:0]      mem_resp_link_o
   );

  `declare_bp_lce_cce_if(cce_id_width_p, lce_id_width_p, paddr_width_p, lce_assoc_p, dword_width_p, cce_block_width_p)
  `declare_bp_me_if(paddr_width_p, cce_block_width_p, lce_id_width_p, lce_assoc_p)
  `declare_bp_cfg_bus_s(vaddr_width_p, core_id_width_p, cce_id_width_p, lce_id_width_p, cce_pc_width_p, cce_instr_width_p);  
  // Declare the routing links
  `declare_bsg_ready_and_link_sif_s(coh_noc_flit_width_p, bp_coh_ready_and_link_s);
  `declare_bsg_ready_and_link_sif_s(mem_noc_flit_width_p, bp_mem_ready_and_link_s);

logic timer_irq_li, software_irq_li, external_irq_li;
bp_cfg_bus_s cfg_bus_lo;
logic [dword_width_p-1:0] cfg_irf_data_li;
logic [vaddr_width_p-1:0] cfg_npc_data_li;
logic [dword_width_p-1:0] cfg_csr_data_li;
logic [1:0]               cfg_priv_data_li;

// Proc-side connections network connections
bp_lce_cce_req_s  [1:0] lce_req_lo;
logic             [1:0] lce_req_v_lo, lce_req_ready_li;
bp_lce_cce_resp_s [1:0] lce_resp_lo;
logic             [1:0] lce_resp_v_lo, lce_resp_ready_li;
bp_lce_cmd_s      [1:0] lce_cmd_li;
logic             [1:0] lce_cmd_v_li, lce_cmd_yumi_lo;
bp_lce_cmd_s      [1:0] lce_cmd_lo;
logic             [1:0] lce_cmd_v_lo, lce_cmd_ready_li;

logic reset_r;
always_ff @(posedge core_clk_i)
  reset_r <= core_reset_i;
  
// Module instantiations
bp_core
 #(.bp_params_p(bp_params_p))
 core
  (.clk_i(core_clk_i)
   ,.reset_i(reset_r)

   ,.cfg_bus_i(cfg_bus_lo)
   ,.cfg_irf_data_o(cfg_irf_data_li)
   ,.cfg_npc_data_o(cfg_npc_data_li)
   ,.cfg_csr_data_o(cfg_csr_data_li)
   ,.cfg_priv_data_o(cfg_priv_data_li)

   ,.lce_req_o(lce_req_lo)
   ,.lce_req_v_o(lce_req_v_lo)
   ,.lce_req_ready_i(lce_req_ready_li)

   ,.lce_cmd_i(lce_cmd_li)
   ,.lce_cmd_v_i(lce_cmd_v_li)
   ,.lce_cmd_yumi_o(lce_cmd_yumi_lo)

   ,.lce_cmd_o(lce_cmd_lo)
   ,.lce_cmd_v_o(lce_cmd_v_lo)
   ,.lce_cmd_ready_i(lce_cmd_ready_li)

   ,.lce_resp_o(lce_resp_lo)
   ,.lce_resp_v_o(lce_resp_v_lo)
   ,.lce_resp_ready_i(lce_resp_ready_li)

   ,.timer_irq_i(timer_irq_li)
   ,.software_irq_i(software_irq_li)
   ,.external_irq_i(external_irq_li)
   );


bp_core_socket
 #(.bp_params_p(bp_params_p))
core_socket
 (.core_clk_i(core_clk_i)
   ,.core_reset_i(core_reset_i)

   ,.coh_clk_i(coh_clk_i)
   ,.coh_reset_i(coh_reset_i)

   ,.mem_clk_i(mem_clk_i)
   ,.mem_reset_i(mem_reset_i)

   ,.my_did_i(my_did_i)
   ,.my_cord_i(my_cord_i)

   //core side connections
   ,.cfg_bus_o(cfg_bus_lo)
   ,.cfg_irf_data_i(cfg_irf_data_li)
   ,.cfg_npc_data_i(cfg_npc_data_li)
   ,.cfg_csr_data_i(cfg_csr_data_li)
   ,.cfg_priv_data_i(cfg_priv_data_li)

   ,.lce_req_i(lce_req_lo)
   ,.lce_req_v_i(lce_req_v_lo)
   ,.lce_req_ready_o(lce_req_ready_li)

   ,.lce_cmd_o(lce_cmd_li)
   ,.lce_cmd_v_o(lce_cmd_v_li)
   ,.lce_cmd_yumi_i(lce_cmd_yumi_lo)

   ,.lce_cmd_i(lce_cmd_lo)
   ,.lce_cmd_v_i(lce_cmd_v_lo)
   ,.lce_cmd_ready_o(lce_cmd_ready_li)

   ,.lce_resp_i(lce_resp_lo)
   ,.lce_resp_v_i(lce_resp_v_lo)
   ,.lce_resp_ready_o(lce_resp_ready_li)

   ,.timer_irq_o(timer_irq_li)
   ,.software_irq_o(software_irq_li)
   ,.external_irq_o(external_irq_li)

  //network side connections
  ,.coh_lce_req_link_i(coh_lce_req_link_i)
  ,.coh_lce_req_link_o(coh_lce_req_link_o)

  ,.coh_lce_cmd_link_i(coh_lce_cmd_link_i)
  ,.coh_lce_cmd_link_o(coh_lce_cmd_link_o)

  ,.coh_lce_resp_link_i(coh_lce_resp_link_i)
  ,.coh_lce_resp_link_o(coh_lce_resp_link_o)

  ,.mem_cmd_link_o(mem_cmd_link_o)
  ,.mem_resp_link_i(mem_resp_link_i)

  ,.mem_resp_link_o(mem_resp_link_o)
  ,.mem_cmd_link_i(mem_cmd_link_i)
  );
   
endmodule

