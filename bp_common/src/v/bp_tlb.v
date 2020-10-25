
module bp_tlb
 import bp_common_pkg::*;
 import bp_common_aviary_pkg::*;
 #(parameter bp_params_e bp_params_p = e_bp_default_cfg
   `declare_bp_proc_params(bp_params_p)
   , parameter tlb_els_p       = "inv"
   
   , localparam lg_els_lp      = `BSG_SAFE_CLOG2(tlb_els_p)
   , localparam entry_width_lp = `bp_pte_entry_leaf_width(paddr_width_p)
   )
  (input                               clk_i
   , input                             reset_i
   , input                             flush_i
  
   , input                             v_i
   , input                             w_i
   , input [vtag_width_p-1:0]          vtag_i
   , input [entry_width_lp-1:0]        entry_i
    
   , output logic                      v_o
   , output logic                      miss_v_o
  , output logic [entry_width_lp-1:0]  entry_o
   );

  `declare_bp_fe_be_if(vaddr_width_p, paddr_width_p, asid_width_p, branch_metadata_fwd_width_p);
  
  logic last_read_r;
  wire r_v_li = v_i & ~w_i;
  wire w_v_li = v_i &  w_i;
  bsg_dff_reset_set_clear
   #(.width_p(1))
   last_read_reg
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.set_i(r_v_li)
     ,.clear_i(w_v_li | flush_i)
     ,.data_o(last_read_r)
     );
  
  logic [vtag_width_p-1:0] vtag_r;
  logic bypass_r;
  wire bypass = ((vtag_i == vtag_r) & last_read_r);
  bsg_dff_reset
   #(.width_p(1+vtag_width_p))
   r_v_reg
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.data_i({bypass, vtag_i})
     ,.data_o({bypass_r, vtag_r})
     );

  bp_pte_entry_leaf_s r_entry;
  logic r_v_lo;
  bsg_cam_1r1w_sync
   #(.els_p(tlb_els_p)
     ,.tag_width_p(vtag_width_p)
     ,.data_width_p(entry_width_lp)
     )
   cam
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
  
     ,.w_v_i(w_v_li)
     ,.w_nuke_i(flush_i)
     ,.w_tag_i(vtag_i)
     ,.w_data_i(entry_i)
  
     ,.r_v_i(r_v_li & ~bypass)
     ,.r_tag_i(vtag_i)
  
     ,.r_data_o(r_entry)
     ,.r_v_o(r_v_lo)
     );
  
  bp_pte_entry_leaf_s r_entry_r;
  bsg_dff_reset_en_bypass
   #(.width_p(1+entry_width_lp))
   r_entry_reg
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.en_i(~bypass_r)
     ,.data_i({r_v_lo, r_entry})
     ,.data_o({r_entry_v_r, r_entry_r})
     );
  
  assign entry_o  = r_entry_r;
  assign v_o      = r_entry_v_r;
  assign miss_v_o = ~r_entry_v_r;

endmodule

