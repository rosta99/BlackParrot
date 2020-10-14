module testbench
 import bp_common_pkg::*;
 import bp_common_aviary_pkg::*;
 import bp_common_cfg_link_pkg::*;
 import bp_fe_pkg::*;
 import bp_be_dcache_pkg::*;
 import bp_fe_icache_pkg::*;
 import bp_me_pkg::*;
 import bp_cce_pkg::*;
 #(parameter bp_params_e bp_params_p = BP_CFG_FLOWVAR
   `declare_bp_proc_params(bp_params_p)
   `declare_bp_mem_if_widths(paddr_width_p, cce_block_width_p, lce_id_width_p, lce_assoc_p, cce_mem)

   , parameter trace_file_p = "test.tr"

   , parameter [paddr_width_p-1:0] mem_offset_p = dram_base_addr_gp
   , parameter mem_cap_in_bytes_p = 2**25
   , parameter mem_file_p = "prog.mem"
   , parameter dram_fixed_latency_p = 0
   )
  (input   clk_i
   , input reset_i
   , input dram_clk_i
   , input dram_reset_i
   );

  `declare_bp_mem_if(paddr_width_p, cce_block_width_p, lce_id_width_p, lce_assoc_p, cce_mem)
  `declare_bp_cfg_bus_s(vaddr_width_p, core_id_width_p, cce_id_width_p, lce_id_width_p, cce_pc_width_p, cce_instr_width_p);
  bp_cfg_bus_s cfg_bus_li;

  always_comb
    begin
      cfg_bus_li = '0;
      cfg_bus_li.freeze      = '0;
      cfg_bus_li.core_id     = '0;
      cfg_bus_li.icache_id   = '0;
      cfg_bus_li.icache_mode = e_lce_mode_normal;
    end

  `declare_bp_fe_be_if(vaddr_width_p, paddr_width_p, asid_width_p, branch_metadata_fwd_width_p);
  bp_fe_cmd_s fe_cmd_li;
  logic fe_cmd_v_li, fe_cmd_yumi_lo;
  bp_fe_queue_s fe_queue_lo;
  logic fe_queue_v_lo, fe_queue_ready_li;
  bp_cce_mem_msg_s mem_cmd_lo;
  logic mem_cmd_v_lo, mem_cmd_ready_li;
  bp_cce_mem_msg_s mem_resp_li;
  logic mem_resp_v_li, mem_resp_yumi_lo;
  wrapper 
   #(.bp_params_p(bp_params_p))
   wrapper
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.cfg_bus_i(cfg_bus_li)

     ,.fe_cmd_i(fe_cmd_li)
     ,.fe_cmd_v_i(fe_cmd_v_li)
     ,.fe_cmd_yumi_o(fe_cmd_yumi_lo)

     ,.fe_queue_o(fe_queue_lo)
     ,.fe_queue_v_o(fe_queue_v_lo)
     ,.fe_queue_ready_i(fe_queue_ready_li)

     ,.mem_cmd_o(mem_cmd_lo)
     ,.mem_cmd_v_o(mem_cmd_v_lo)
     ,.mem_cmd_ready_i(mem_cmd_ready_li)

     ,.mem_resp_i(mem_resp_li)
     ,.mem_resp_v_i(mem_resp_v_li)
     ,.mem_resp_yumi_o(mem_resp_yumi_lo)
     );

  // TODO: Mock backend, not stub
  assign fe_cmd_li = '0;
  assign fe_cmd_v_li = '0;
  assign fe_queue_ready_li = '0;

  bp_mem
   #(.bp_params_p(bp_params_p)
     ,.mem_offset_p(mem_offset_p)
     ,.mem_load_p(1)
     ,.mem_file_p(mem_file_p)
     ,.mem_cap_in_bytes_p(mem_cap_in_bytes_p)
     ,.dram_fixed_latency_p(dram_fixed_latency_p)
     )
   mem
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.mem_cmd_i(mem_cmd_lo)
     ,.mem_cmd_v_i(mem_cmd_v_lo)
     ,.mem_cmd_ready_o(mem_cmd_ready_li)

     ,.mem_resp_o(mem_resp_li)
     ,.mem_resp_v_o(mem_resp_v_li)
     ,.mem_resp_yumi_i(mem_resp_yumi_lo)

     ,.dram_clk_i(dram_clk_i)
     ,.dram_reset_i(dram_reset_i)
     );

endmodule

