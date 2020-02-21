
module bp_cac_tile
 import bp_common_pkg::*;
 import bp_common_aviary_pkg::*;
 import bp_cce_pkg::*;
 import bp_me_pkg::*;
 import bsg_cache_pkg::*;
   import bp_be_pkg::*;
   import bsg_noc_pkg::*;
   import bp_common_cfg_link_pkg::*;
   import bsg_wormhole_router_pkg::*;
 #(parameter bp_params_e bp_params_p = e_bp_inv_cfg
   , parameter bp_enable_accelerator_p = 0
   `declare_bp_proc_params(bp_params_p)
   `declare_bp_me_if_widths(paddr_width_p, cce_block_width_p, lce_id_width_p, lce_assoc_p)
   `declare_bp_lce_cce_if_widths(cce_id_width_p, lce_id_width_p, paddr_width_p, lce_assoc_p, dword_width_p, cce_block_width_p)

   , localparam coh_noc_ral_link_width_lp = `bsg_ready_and_link_sif_width(coh_noc_flit_width_p)
   , localparam io_noc_ral_link_width_lp = `bsg_ready_and_link_sif_width(io_noc_flit_width_p)
   )
  (input                                         core_clk_i
   , input                                       core_reset_i

   , input                                       coh_clk_i
   , input                                       coh_reset_i

   , input [coh_noc_cord_width_p-1:0]            my_cord_i

   , input [S:W][coh_noc_ral_link_width_lp-1:0]  coh_lce_req_link_i
   , output [S:W][coh_noc_ral_link_width_lp-1:0] coh_lce_req_link_o

   , input [S:W][coh_noc_ral_link_width_lp-1:0]  coh_lce_cmd_link_i
   , output [S:W][coh_noc_ral_link_width_lp-1:0] coh_lce_cmd_link_o

   , input [S:W][coh_noc_ral_link_width_lp-1:0]  coh_lce_resp_link_i
   , output [S:W][coh_noc_ral_link_width_lp-1:0] coh_lce_resp_link_o
   );


  `declare_bp_me_if(paddr_width_p, cce_block_width_p, lce_id_width_p, lce_assoc_p);
  `declare_bp_lce_cce_if(cce_id_width_p, lce_id_width_p, paddr_width_p, lce_assoc_p, dword_width_p, cce_block_width_p);

  bp_cce_mem_msg_s cce_io_cmd_lo;
  logic cce_io_cmd_v_lo, cce_io_cmd_ready_li;
  bp_cce_mem_msg_s cce_io_resp_li;
  logic cce_io_resp_v_li, cce_io_resp_yumi_lo;

  bp_lce_cce_req_s  lce_req_lo;
  logic             lce_req_v_lo, lce_req_ready_li;
  bp_lce_cce_resp_s lce_resp_lo;
  logic             lce_resp_v_lo, lce_resp_ready_li;
  bp_lce_cmd_s      lce_cmd_li;
  logic             lce_cmd_v_li, lce_cmd_yumi_lo;
  bp_lce_cmd_s      lce_cmd_lo;
  logic             lce_cmd_v_lo, lce_cmd_ready_li;

  logic [lce_id_width_p-1:0] lce_id_lo;

  bp_coherent_accelerator_example
   #(.bp_params_p(bp_params_p)
     , .bp_enable_accelerator_p(bp_enable_accelerator_p)
     )
   accelerator_link
    (.clk_i(core_clk_i)
     ,.reset_i(core_reset_i)

     ,.lce_id_i(lce_id_lo)

     ,.io_cmd_i(cce_io_cmd_lo)
     ,.io_cmd_v_i(cce_io_cmd_v_lo)
     ,.io_cmd_ready_o(cce_io_cmd_ready_li)

     ,.io_resp_o(cce_io_resp_li)
     ,.io_resp_v_o(cce_io_resp_v_li)
     ,.io_resp_yumi_i(cce_io_resp_yumi_lo)

     ,.lce_req_o(lce_req_lo)
     ,.lce_req_v_o(lce_req_v_lo)
     ,.lce_req_ready_i(lce_req_ready_li)

     ,.lce_cmd_o(lce_cmd_lo)
     ,.lce_cmd_v_o(lce_cmd_v_lo)
     ,.lce_cmd_ready_i(lce_cmd_ready_li)

     ,.lce_resp_o(lce_resp_lo)
     ,.lce_resp_v_o(lce_resp_v_lo)
     ,.lce_resp_ready_i(lce_resp_ready_li)

     ,.lce_cmd_i(lce_cmd_li)
     ,.lce_cmd_v_i(lce_cmd_v_li)
     ,.lce_cmd_yumi_o(lce_cmd_yumi_lo)

     );
   

  bp_cac_socket 
   #(.bp_params_p(bp_params_p))
  cac_socket
   (.core_clk_i(core_clk_i)
    ,.core_reset_i(core_reset_i)

    ,.coh_clk_i(coh_clk_i)
    ,.coh_reset_i(coh_reset_i)

    ,.my_cord_i(my_cord_i)
    ,.lce_id_o(lce_id_lo)
    
    //tile side connections
    ,.io_cmd_o(cce_io_cmd_lo)
    ,.io_cmd_v_o(cce_io_cmd_v_lo)
    ,.io_cmd_ready_i(cce_io_cmd_ready_li)
    
    ,.io_resp_i(cce_io_resp_li)
    ,.io_resp_v_i(cce_io_resp_v_li)
    ,.io_resp_yumi_o(cce_io_resp_yumi_lo)
    
    ,.lce_req_i(lce_req_lo)
    ,.lce_req_v_i(lce_req_v_lo)
    ,.lce_req_ready_o(lce_req_ready_li)
    
    ,.lce_cmd_i(lce_cmd_lo)
    ,.lce_cmd_v_i(lce_cmd_v_lo)
    ,.lce_cmd_ready_o(lce_cmd_ready_li)
    
    ,.lce_resp_i(lce_resp_lo)
    ,.lce_resp_v_i(lce_resp_v_lo)
    ,.lce_resp_ready_o(lce_resp_ready_li)
    
    ,.lce_cmd_o(lce_cmd_li)
    ,.lce_cmd_v_o(lce_cmd_v_li)
    ,.lce_cmd_yumi_i(lce_cmd_yumi_lo)

    //network side connections
    ,.coh_lce_req_link_i(coh_lce_req_link_i)
    ,.coh_lce_req_link_o(coh_lce_req_link_o)

    ,.coh_lce_cmd_link_i(coh_lce_cmd_link_i)
    ,.coh_lce_cmd_link_o(coh_lce_cmd_link_o)

    ,.coh_lce_resp_link_i(coh_lce_resp_link_i)
    ,.coh_lce_resp_link_o(coh_lce_resp_link_o)
    );

endmodule

