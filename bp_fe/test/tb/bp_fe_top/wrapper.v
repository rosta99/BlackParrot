
module wrapper
 import bp_common_pkg::*;
 import bp_common_aviary_pkg::*;
 import bp_common_cfg_link_pkg::*;
 import bp_fe_pkg::*;
 import bp_fe_icache_pkg::*;
 import bp_cce_pkg::*;
 import bp_me_pkg::*;
 #(parameter bp_params_e bp_params_p = BP_CFG_FLOWVAR
   `declare_bp_proc_params(bp_params_p)
   `declare_bp_fe_be_if_widths(vaddr_width_p, paddr_width_p, asid_width_p, branch_metadata_fwd_width_p)
   `declare_bp_cache_service_if_widths(paddr_width_p, ptag_width_p, icache_sets_p, icache_assoc_p, dword_width_p, icache_block_width_p, icache_fill_width_p, icache)
   `declare_bp_mem_if_widths(paddr_width_p, cce_block_width_p, lce_id_width_p, lce_assoc_p, cce_mem)

    , localparam cfg_bus_width_lp = `bp_cfg_bus_width(vaddr_width_p, core_id_width_p, cce_id_width_p, lce_id_width_p, cce_pc_width_p, cce_instr_width_p)
   )
  (input                                              clk_i
   , input                                            reset_i

   , input [cfg_bus_width_lp-1:0]                     cfg_bus_i

   // To Mock Backend
   , input [fe_cmd_width_lp-1:0]                      fe_cmd_i
   , input                                            fe_cmd_v_i
   , output logic                                     fe_cmd_yumi_o

   , output logic [fe_queue_width_lp-1:0]             fe_queue_o
   , output logic                                     fe_queue_v_o
   , input                                            fe_queue_ready_i

   // Memory Interface
   , output [cce_mem_msg_width_lp-1:0]                mem_cmd_o
   , output                                           mem_cmd_v_o
   , input                                            mem_cmd_ready_i

   , input [cce_mem_msg_width_lp-1:0]                 mem_resp_i
   , input                                            mem_resp_v_i
   , output                                           mem_resp_yumi_o
   );

  `declare_bp_cache_service_if(paddr_width_p, ptag_width_p, icache_sets_p, icache_assoc_p, dword_width_p, icache_block_width_p, icache_fill_width_p, icache);
  bp_icache_req_s icache_req_lo;
  logic icache_req_ready_li, icache_req_v_lo;
  bp_icache_req_metadata_s icache_req_metadata_lo;
  logic icache_req_metadata_v_lo;
  logic icache_req_complete_lo, icache_req_critical_lo;

  bp_icache_data_mem_pkt_s icache_data_mem_pkt_li;
  logic icache_data_mem_pkt_v_li;
  logic icache_data_mem_pkt_yumi_lo;
  logic [icache_block_width_p-1:0] icache_data_mem_lo;

  bp_icache_tag_mem_pkt_s icache_tag_mem_pkt_li;
  logic icache_tag_mem_pkt_v_li;
  logic icache_tag_mem_pkt_yumi_lo;
  logic [icache_tag_info_width_lp-1:0] icache_tag_mem_lo;

  bp_icache_stat_mem_pkt_s icache_stat_mem_pkt_li;
  logic icache_stat_mem_pkt_v_li;
  logic icache_stat_mem_pkt_yumi_lo;
  logic [icache_stat_info_width_lp-1:0] icache_stat_mem_lo;

  bp_fe_top
   #(.bp_params_p(bp_params_p))
   fe
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.cfg_bus_i(cfg_bus_i)

     ,.fe_cmd_i(fe_cmd_i)
     ,.fe_cmd_v_i(fe_cmd_v_i)
     ,.fe_cmd_yumi_o(fe_cmd_yumi_o)

     ,.fe_queue_o(fe_queue_o)
     ,.fe_queue_v_o(fe_queue_v_o)
     ,.fe_queue_ready_i(fe_queue_ready_i)

     ,.cache_req_o(icache_req_lo)
     ,.cache_req_v_o(icache_req_v_lo)
     ,.cache_req_ready_i(icache_req_ready_li)
     ,.cache_req_metadata_o(icache_req_metadata_lo)
     ,.cache_req_metadata_v_o(icache_req_metadata_v_lo)
     ,.cache_req_complete_i(icache_req_complete_lo)
     ,.cache_req_critical_i(icache_req_critical_lo)

     ,.data_mem_pkt_i(icache_data_mem_pkt_li)
     ,.data_mem_pkt_v_i(icache_data_mem_pkt_v_li)
     ,.data_mem_pkt_yumi_o(icache_data_mem_pkt_yumi_lo)
     ,.data_mem_o(icache_data_mem_lo)

     ,.tag_mem_pkt_i(icache_tag_mem_pkt_li)
     ,.tag_mem_pkt_v_i(icache_tag_mem_pkt_v_li)
     ,.tag_mem_pkt_yumi_o(icache_tag_mem_pkt_yumi_lo)
     ,.tag_mem_o(icache_tag_mem_lo)

     ,.stat_mem_pkt_v_i(icache_stat_mem_pkt_v_li)
     ,.stat_mem_pkt_i(icache_stat_mem_pkt_li)
     ,.stat_mem_pkt_yumi_o(icache_stat_mem_pkt_yumi_lo)
     ,.stat_mem_o(icache_stat_mem_lo)
     );

  logic icache_credits_full_lo, icache_credits_empty_lo;
  bp_uce
   #(.bp_params_p(bp_params_p)
     ,.uce_mem_data_width_p(icache_fill_width_p)
     ,.assoc_p(icache_assoc_p)
     ,.sets_p(icache_sets_p)
     ,.block_width_p(icache_block_width_p)
     ,.fill_width_p(icache_fill_width_p)
     )
   icache_uce
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.lce_id_i('0)

     ,.cache_req_i(icache_req_lo)
     ,.cache_req_v_i(icache_req_v_lo)
     ,.cache_req_ready_o(icache_req_ready_li)
     ,.cache_req_metadata_i(icache_req_metadata_lo)
     ,.cache_req_metadata_v_i(icache_req_metadata_v_lo)

     ,.cache_req_complete_o(icache_req_complete_lo)
     ,.cache_req_critical_o(icache_req_critical_lo)

     ,.tag_mem_pkt_o(icache_tag_mem_pkt_li)
     ,.tag_mem_pkt_v_o(icache_tag_mem_pkt_v_li)
     ,.tag_mem_pkt_yumi_i(icache_tag_mem_pkt_yumi_lo)
     ,.tag_mem_i(icache_tag_mem_lo)

     ,.data_mem_pkt_o(icache_data_mem_pkt_li)
     ,.data_mem_pkt_v_o(icache_data_mem_pkt_v_li)
     ,.data_mem_pkt_yumi_i(icache_data_mem_pkt_yumi_lo)
     ,.data_mem_i(icache_data_mem_lo)

     ,.stat_mem_pkt_o(icache_stat_mem_pkt_li)
     ,.stat_mem_pkt_v_o(icache_stat_mem_pkt_v_li)
     ,.stat_mem_pkt_yumi_i(icache_stat_mem_pkt_yumi_lo)
     ,.stat_mem_i(icache_stat_mem_lo)

     ,.credits_full_o(icache_credits_full_lo)
     ,.credits_empty_o(icache_credits_empty_lo)

     ,.mem_cmd_o(mem_cmd_o)
     ,.mem_cmd_v_o(mem_cmd_v_o)
     ,.mem_cmd_ready_i(mem_cmd_ready_i)

     ,.mem_resp_i(mem_resp_i)
     ,.mem_resp_v_i(mem_resp_v_i)
     ,.mem_resp_yumi_o(mem_resp_yumi_o)
     );

endmodule

