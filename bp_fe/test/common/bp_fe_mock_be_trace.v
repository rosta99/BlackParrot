
module bp_fe_mock_be_trace
 import bp_common_pkg::*;
 import bp_common_rv64_pkg::*;
 import bp_common_aviary_pkg::*;
 import bp_be_pkg::*;
 #(parameter bp_params_e bp_params_p = e_bp_default_cfg
   `declare_bp_proc_params(bp_params_p)
   `declare_bp_fe_be_if_widths(vaddr_width_p, paddr_width_p, asid_width_p, branch_metadata_fwd_width_p)

   , parameter trace_replay_data_width_p = "inv"
   , parameter trace_rom_addr_width_p    = "inv"
   , parameter trace_file_p              = "inv"
   )
  (input                                clk_i
   , input                              reset_i

   // FE queue interface
   , input [fe_queue_width_lp-1:0]      fe_queue_i
   , input                              fe_queue_v_i
   , output logic                       fe_queue_ready_o

   // FE cmd interface
   , output logic [fe_cmd_width_lp-1:0]  fe_cmd_o
   , output logic                        fe_cmd_v_o
   , input                               fe_cmd_yumi_i
   );

  `declare_bp_fe_be_if(vaddr_width_p, paddr_width_p, asid_width_p, branch_metadata_fwd_width_p);
  `bp_cast_o(bp_fe_cmd_s, fe_cmd);
  `bp_cast_i(bp_fe_queue_s, fe_queue);

  enum logic [1:0] {e_reset, e_boot, e_run} state_n, state_r;
  wire is_reset = (state_r == e_reset);
  wire is_boot  = (state_r == e_boot);
  wire is_run   = (state_r == e_run);

  assign fe_queue_ready_o = is_run;

  always_comb
    begin
      fe_cmd_cast_o = '0;
      fe_cmd_v_o = '0;

      case (state_r)
        e_reset: state_n = e_boot;
        e_boot:
          begin
            fe_cmd_cast_o.opcode = e_op_state_reset;
            fe_cmd_cast_o.vaddr = '0; // start at PC != '0 ?

            fe_cmd_v_o = 1'b1;
            state_n = fe_cmd_yumi_i ? e_run : e_boot;
          end
        e_run:
          begin
            
            state_n = e_run;
          end
      endcase
    end

  always_ff @(posedge clk_i)
    if (reset_i)
        state_r <= e_reset;
    else
      begin
        state_r <= state_n;
      end

endmodule

