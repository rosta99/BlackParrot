
module bp_cac_socket
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
   , output [lce_id_width_p-1:0]                 lce_id_o
   //tile side connections
   , output [cce_mem_msg_width_lp-1:0]           io_cmd_o
   , output                                      io_cmd_v_o
   , input                                       io_cmd_ready_i

   , input [cce_mem_msg_width_lp-1:0]            io_resp_i
   , input                                       io_resp_v_i
   , output                                      io_resp_yumi_o

   , input [lce_cce_req_width_lp-1:0]            lce_req_i
   , input                                       lce_req_v_i
   , output                                      lce_req_ready_o

   , input [lce_cmd_width_lp-1:0]                lce_cmd_i
   , input                                       lce_cmd_v_i
   , output                                      lce_cmd_ready_o

   , input [lce_cce_resp_width_lp-1:0]           lce_resp_i
   , input                                       lce_resp_v_i
   , output                                      lce_resp_ready_o

   , output [lce_cmd_width_lp-1:0]               lce_cmd_o
   , output                                      lce_cmd_v_o
   , input                                       lce_cmd_yumi_i   

   //network side connections
   , input [S:W][coh_noc_ral_link_width_lp-1:0]  coh_lce_req_link_i
   , output [S:W][coh_noc_ral_link_width_lp-1:0] coh_lce_req_link_o

   , input [S:W][coh_noc_ral_link_width_lp-1:0]  coh_lce_cmd_link_i
   , output [S:W][coh_noc_ral_link_width_lp-1:0] coh_lce_cmd_link_o

   , input [S:W][coh_noc_ral_link_width_lp-1:0]  coh_lce_resp_link_i
   , output [S:W][coh_noc_ral_link_width_lp-1:0] coh_lce_resp_link_o

   );

 

  `declare_bsg_wormhole_concentrator_packet_s(coh_noc_cord_width_p, coh_noc_len_width_p, coh_noc_cid_width_p, lce_cce_req_width_lp, lce_req_packet_s);
  `declare_bsg_wormhole_concentrator_packet_s(coh_noc_cord_width_p, coh_noc_len_width_p, coh_noc_cid_width_p, lce_cmd_width_lp, lce_cmd_packet_s);
  `declare_bsg_wormhole_concentrator_packet_s(coh_noc_cord_width_p, coh_noc_len_width_p, coh_noc_cid_width_p, lce_cce_resp_width_lp, lce_resp_packet_s);
   

  `declare_bp_lce_cce_if(cce_id_width_p, lce_id_width_p, paddr_width_p, lce_assoc_p, dword_width_p, cce_block_width_p)
  `declare_bp_me_if(paddr_width_p, cce_block_width_p, lce_id_width_p, lce_assoc_p)
  
  // Declare the routing links
  `declare_bsg_ready_and_link_sif_s(coh_noc_flit_width_p, bp_coh_ready_and_link_s);

   
  // Tile-side coherence connections
  bp_coh_ready_and_link_s accel_lce_req_link_li, accel_lce_req_link_lo;
  bp_coh_ready_and_link_s accel_lce_cmd_link_li, accel_lce_cmd_link_lo;
  bp_coh_ready_and_link_s accel_lce_resp_link_li, accel_lce_resp_link_lo;
  

  //io-cce-side connections 
  bp_lce_cce_req_s  cce_lce_req_li;
  logic cce_lce_req_v_li, cce_lce_req_yumi_lo;
  bp_lce_cmd_s cce_lce_cmd_lo;
  logic cce_lce_cmd_v_lo, cce_lce_cmd_ready_li;
  

  logic [cce_id_width_p-1:0]  cce_id_li;
  bp_me_cord_to_id
   #(.bp_params_p(bp_params_p))
   id_map
    (.cord_i(my_cord_i)
     ,.core_id_o()
     ,.cce_id_o(cce_id_li)
     ,.lce_id0_o(lce_id_o)
     ,.lce_id1_o()
     );

  bp_io_cce
   #(.bp_params_p(bp_params_p))
   io_cce
    (.clk_i(core_clk_i)
     ,.reset_i(core_reset_i)

     ,.cce_id_i(cce_id_li)

     ,.lce_req_i(cce_lce_req_li)
     ,.lce_req_v_i(cce_lce_req_v_li)
     ,.lce_req_yumi_o(cce_lce_req_yumi_lo)

     ,.lce_cmd_o(cce_lce_cmd_lo)
     ,.lce_cmd_v_o(cce_lce_cmd_v_lo)
     ,.lce_cmd_ready_i(cce_lce_cmd_ready_li)

     ,.io_cmd_o(io_cmd_o)
     ,.io_cmd_v_o(io_cmd_v_o)
     ,.io_cmd_ready_i(io_cmd_ready_i)

     ,.io_resp_i(io_resp_i)
     ,.io_resp_v_i(io_resp_v_i)
     ,.io_resp_yumi_o(io_resp_yumi_o)
     );


////////////////////////////////////////////////////////////////////
  lce_req_packet_s lce_req_packet_li, lce_req_packet_lo;
  bp_me_wormhole_packet_encode_lce_req
   #(.bp_params_p(bp_params_p))
   req_encode
    (.payload_i(lce_req_i)
     ,.packet_o(lce_req_packet_lo)
     );

  bsg_wormhole_router_adapter
   #(.max_payload_width_p($bits(lce_req_packet_s)-coh_noc_cord_width_p-coh_noc_len_width_p)
     ,.len_width_p(coh_noc_len_width_p)
     ,.cord_width_p(coh_noc_cord_width_p)
     ,.flit_width_p(coh_noc_flit_width_p)
     )
   lce_req_adapter
    (.clk_i(core_clk_i)
     ,.reset_i(core_reset_i)

     ,.packet_i(lce_req_packet_lo)
     ,.v_i(lce_req_v_i)
     ,.ready_o(lce_req_ready_o)

     ,.link_i(accel_lce_req_link_li)
     ,.link_o(accel_lce_req_link_lo)

     ,.packet_o(lce_req_packet_li)
     ,.v_o(cce_lce_req_v_li)
     ,.yumi_i(cce_lce_req_yumi_lo)
     );
   assign cce_lce_req_li = lce_req_packet_li.payload;

  lce_resp_packet_s lce_resp_packet_lo;
  bp_me_wormhole_packet_encode_lce_resp
    #(.bp_params_p(bp_params_p))
    resp_encode
      (.payload_i(lce_resp_i)
       ,.packet_o(lce_resp_packet_lo)
       );

  bsg_wormhole_router_adapter_in
    #(.max_payload_width_p($bits(lce_resp_packet_s)-coh_noc_cord_width_p-coh_noc_len_width_p)
      ,.len_width_p(coh_noc_len_width_p)
      ,.cord_width_p(coh_noc_cord_width_p)
      ,.flit_width_p(coh_noc_flit_width_p)
      )
    lce_resp_adapter_in
    (.clk_i(core_clk_i)
     ,.reset_i(core_reset_i)

     ,.packet_i(lce_resp_packet_lo)
     ,.v_i(lce_resp_v_i)
     ,.ready_o(lce_resp_ready_o)

     ,.link_i(accel_lce_resp_link_li)
     ,.link_o(accel_lce_resp_link_lo)
     );


    bp_coh_ready_and_link_s lce_cmd_link_li, lce_cmd_link_lo;
    bp_coh_ready_and_link_s cce_lce_cmd_link_li, cce_lce_cmd_link_lo;  
    lce_cmd_packet_s lce_cmd_packet_li, lce_cmd_packet_lo;
    bp_me_wormhole_packet_encode_lce_cmd
     #(.bp_params_p(bp_params_p))
     cmd_encode
      (.payload_i(lce_cmd_i)
       ,.packet_o(lce_cmd_packet_lo)
       );

    bsg_wormhole_router_adapter
     #(.max_payload_width_p($bits(lce_cmd_packet_s)-coh_noc_cord_width_p-coh_noc_len_width_p)
       ,.len_width_p(coh_noc_len_width_p)
       ,.cord_width_p(coh_noc_cord_width_p)
       ,.flit_width_p(coh_noc_flit_width_p)
       )
     cmd_adapter
      (.clk_i(core_clk_i)
       ,.reset_i(core_reset_i)

       ,.packet_i(lce_cmd_packet_lo)
       ,.v_i(lce_cmd_v_i)
       ,.ready_o(lce_cmd_ready_o)

       ,.link_i(lce_cmd_link_li)
       ,.link_o(lce_cmd_link_lo)

       ,.packet_o(lce_cmd_packet_li)
       ,.v_o(lce_cmd_v_o)
       ,.yumi_i(lce_cmd_yumi_i)
       );
    assign lce_cmd_o = lce_cmd_packet_li.payload;


   
  lce_cmd_packet_s cce_lce_cmd_packet_lo;
  bp_me_wormhole_packet_encode_lce_cmd
   #(.bp_params_p(bp_params_p))
   cce_cmd_encode
    (.payload_i(cce_lce_cmd_lo)
     ,.packet_o(cce_lce_cmd_packet_lo)
     );
  bsg_wormhole_router_adapter_in
   #(.max_payload_width_p($bits(lce_cmd_packet_s)-coh_noc_cord_width_p-coh_noc_len_width_p)
     ,.len_width_p(coh_noc_len_width_p)
     ,.cord_width_p(coh_noc_cord_width_p)
     ,.flit_width_p(coh_noc_flit_width_p)
     )
    cce_lce_cmd_adapter_in
    (.clk_i(core_clk_i)
     ,.reset_i(core_reset_i)

     ,.packet_i(cce_lce_cmd_packet_lo)
     ,.v_i(cce_lce_cmd_v_lo)
     ,.ready_o(cce_lce_cmd_ready_li)

     ,.link_i(cce_lce_cmd_link_li)
     ,.link_o(cce_lce_cmd_link_lo)
     );


  bp_coh_ready_and_link_s lce_cmd_link_cast_i, lce_cmd_link_cast_o;
  bp_coh_ready_and_link_s cmd_concentrated_link_li, cmd_concentrated_link_lo;
  
  assign lce_cmd_link_cast_i  = accel_lce_cmd_link_li;
  assign accel_lce_cmd_link_lo  = lce_cmd_link_cast_o;
  assign cmd_concentrated_link_li = lce_cmd_link_cast_i;
  assign lce_cmd_link_cast_o = cmd_concentrated_link_lo;
    
  bsg_wormhole_concentrator
   #(.flit_width_p(coh_noc_flit_width_p)
     ,.len_width_p(coh_noc_len_width_p)
     ,.cid_width_p(coh_noc_cid_width_p)
     ,.num_in_p(2)
     ,.cord_width_p(coh_noc_cord_width_p)
     )
   cmd_concentrator
    (.clk_i(core_clk_i)
     ,.reset_i(core_reset_i)

     ,.links_i({cce_lce_cmd_link_lo, lce_cmd_link_lo})
     ,.links_o({cce_lce_cmd_link_li, lce_cmd_link_li})

     ,.concentrated_link_i(cmd_concentrated_link_li)
     ,.concentrated_link_o(cmd_concentrated_link_lo)
     );
////////////////////////////////////////////////////////////////

  bp_nd_socket
   #(.flit_width_p(coh_noc_flit_width_p)
     ,.dims_p(coh_noc_dims_p)
     ,.cord_dims_p(coh_noc_dims_p)
     ,.cord_markers_pos_p(coh_noc_cord_markers_pos_p)
     ,.len_width_p(coh_noc_len_width_p)
     ,.routing_matrix_p(StrictYX | YX_Allow_W)
     ,.async_clk_p(async_coh_clk_p)
     ,.num_p(3)
     )
   cac_coh_socket
    (.tile_clk_i(core_clk_i)
     ,.tile_reset_i(core_reset_i)
     ,.network_clk_i(coh_clk_i)
     ,.network_reset_i(coh_reset_i)
     ,.my_cord_i(my_cord_i)
     ,.network_link_i({coh_lce_req_link_i, coh_lce_cmd_link_i, coh_lce_resp_link_i})
     ,.network_link_o({coh_lce_req_link_o, coh_lce_cmd_link_o, coh_lce_resp_link_o})
     ,.tile_link_i({accel_lce_req_link_lo, accel_lce_cmd_link_lo, accel_lce_resp_link_lo})
     ,.tile_link_o({accel_lce_req_link_li, accel_lce_cmd_link_li, accel_lce_resp_link_li})
     );
   
endmodule

