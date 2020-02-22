module bp_io_tile
 import bp_common_pkg::*;
 import bp_common_rv64_pkg::*;
 import bp_common_aviary_pkg::*;
 import bp_cce_pkg::*;
 import bp_me_pkg::*;
 import bsg_noc_pkg::*;
 import bsg_wormhole_router_pkg::*;
 #(parameter bp_params_e bp_params_p = e_bp_inv_cfg
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

   , input                                       io_clk_i
   , input                                       io_reset_i

   , input [io_noc_did_width_p-1:0]              my_did_i
   , input [coh_noc_cord_width_p-1:0]            my_cord_i

   , input [S:W][coh_noc_ral_link_width_lp-1:0]  coh_lce_req_link_i
   , output [S:W][coh_noc_ral_link_width_lp-1:0] coh_lce_req_link_o

   , input [S:W][coh_noc_ral_link_width_lp-1:0]  coh_lce_cmd_link_i
   , output [S:W][coh_noc_ral_link_width_lp-1:0] coh_lce_cmd_link_o

   , input [E:W][io_noc_ral_link_width_lp-1:0]   io_cmd_link_i
   , output [E:W][io_noc_ral_link_width_lp-1:0]  io_cmd_link_o

   , input [E:W][io_noc_ral_link_width_lp-1:0]   io_resp_link_i
   , output [E:W][io_noc_ral_link_width_lp-1:0]  io_resp_link_o
   );
  
bp_io_socket
  #(.bp_params_p(bp_params_p))
  io_socket
   (.core_clk_i(core_clk_i)
    ,.core_reset_i(core_reset_i)

    ,.coh_clk_i(coh_clk_i)
    ,.coh_reset_i(coh_reset_i)

    ,.io_clk_i(io_clk_i)
    ,.io_reset_i(io_reset_i)

    ,.my_did_i(my_did_i)
    ,.my_cord_i(my_cord_i)

    ,.coh_lce_req_link_i(coh_lce_req_link_i)
    ,.coh_lce_req_link_o(coh_lce_req_link_o)

    ,.coh_lce_cmd_link_i(coh_lce_cmd_link_i)
    ,.coh_lce_cmd_link_o(coh_lce_cmd_link_o)

    ,.io_cmd_link_i(io_cmd_link_i)
    ,.io_cmd_link_o(io_cmd_link_o)

    ,.io_resp_link_i(io_resp_link_i)
    ,.io_resp_link_o(io_resp_link_o)
    );
   
endmodule

