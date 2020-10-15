
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
   , parameter start_pc_p                = "inv"
   )
  (input                                clk_i
   , input                              reset_i

   // FE queue interface
   , input [fe_queue_width_lp-1:0]      fe_queue_i
   , input                              fe_queue_v_i
   , output logic                       fe_queue_ready_o

   // FE cmd interface
   , output logic [fe_cmd_width_lp-1:0] fe_cmd_o
   , output logic                       fe_cmd_v_o
   , input                              fe_cmd_yumi_i
   );

  `declare_bp_fe_be_if(vaddr_width_p, paddr_width_p, asid_width_p, branch_metadata_fwd_width_p);
  `bp_cast_o(bp_fe_cmd_s, fe_cmd);
  `bp_cast_i(bp_fe_queue_s, fe_queue);

  // State machine declaration
  enum logic [1:0] {e_reset, e_boot, e_run} state_n, state_r;
  wire is_reset = (state_r == e_reset);
  wire is_boot  = (state_r == e_boot);
  wire is_run   = (state_r == e_run);

  ///////////////////////////////////////////////
  // Output FIFO
  ///////////////////////////////////////////////
  bp_fe_cmd_s fe_cmd_lo;
  logic fe_cmd_v_lo, fe_cmd_ready_li;
  bsg_two_fifo
   #(.width_p($bits(bp_fe_cmd_s)))
   output_fifo
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.data_i(fe_cmd_lo)
     ,.v_i(fe_cmd_v_lo)
     ,.ready_o(fe_cmd_ready_li)

     ,.data_o(fe_cmd_cast_o)
     ,.v_o(fe_cmd_v_o)
     ,.yumi_i(fe_cmd_yumi_i)
     );

  bp_fe_queue_s fe_queue_li;
  logic fe_queue_v_li, fe_queue_yumi_lo;
  bsg_two_fifo
   #(.width_p($bits(bp_fe_queue_s)))
   input_fifo
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.data_i(fe_queue_cast_i)
     ,.v_i(fe_queue_v_i)
     ,.ready_o(fe_queue_ready_o)

     ,.data_o(fe_queue_li)
     ,.v_o(fe_queue_v_li)
     ,.yumi_i(fe_queue_yumi_lo)
     );

  ///////////////////////////////////////////////
  // Trace replay
  ///////////////////////////////////////////////
  struct packed
  {
    logic [3:0]               msg_type;
    logic [instr_width_p-1:0] instr;
    logic [vaddr_width_p-1:0] pc;
  } trace_data_li, trace_data_lo;
  logic trace_v_li, trace_ready_lo;
  logic trace_v_lo, trace_yumi_li;
  logic [trace_rom_addr_width_p-1:0] trace_rom_addr_lo;
  logic [trace_replay_data_width_p+3:0] trace_rom_data_li;
  bsg_trace_replay
  #(.payload_width_p(trace_replay_data_width_p)
    ,.rom_addr_width_p(trace_rom_addr_width_p)
    ,.debug_p(2)
    )
  tr_replay
   (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.en_i(1'b1)

    ,.v_i(trace_v_li)
    ,.data_i(trace_data_li)
    ,.ready_o(trace_ready_lo)

    ,.v_o(trace_v_lo)
    ,.data_o(trace_data_lo)
    ,.yumi_i(trace_yumi_li)

    ,.rom_addr_o(trace_rom_addr_lo)
    ,.rom_data_i(trace_rom_data_li)

    ,.done_o()
    ,.error_o()
    );

  bsg_nonsynth_test_rom
  #(.data_width_p(trace_replay_data_width_p+4)
    ,.addr_width_p(trace_rom_addr_width_p)
    ,.filename_p(trace_file_p)
    )
  rom
   (.addr_i(trace_rom_addr_lo)
    ,.data_o(trace_rom_data_li)
    );

  always_comb
    begin
      fe_cmd_lo = '0;
      fe_cmd_v_lo = '0;

      fe_queue_yumi_lo = '0;

      trace_v_li    = '0;
      trace_data_li = '0;
      trace_yumi_li = '0;

      case (state_r)
        e_reset: state_n = e_boot;
        e_boot:
          begin
            fe_cmd_lo.opcode = e_op_state_reset;
            fe_cmd_lo.vaddr = start_pc_p;

            fe_cmd_v_lo = 1'b1;
            state_n = fe_cmd_yumi_i ? e_run : e_boot;
          end
        e_run:
          begin
            case (fe_queue_li.msg_type)
              e_fe_exception:
                begin
                  if (fe_queue_li.msg.exception.exception_code == e_icache_miss)
                    begin
                      fe_cmd_lo.opcode = e_op_icache_fill_response;
                      fe_cmd_lo.vaddr = fe_queue_li.msg.exception.vaddr;

                      fe_cmd_v_lo = fe_cmd_ready_li & fe_queue_v_li;
                      fe_queue_yumi_lo = fe_cmd_v_lo;
                    end
                end
              e_fe_fetch:
                begin
                  trace_data_li.msg_type = trace_data_lo.msg_type;
                  trace_data_li.pc       = fe_queue_li.msg.fetch.pc;
                  trace_data_li.instr    = fe_queue_li.msg.fetch.instr;

                  trace_v_li = trace_ready_lo & fe_queue_v_li;
                  fe_queue_yumi_lo = trace_v_li;
                end
            endcase
            state_n = e_run;
          end
      endcase
    end


    asfsadfasdfas
    // TODO: Add fe_cmd FSM for sending responses, decouple from fe_queue FSM
    // TODO: Add state reset message
    // TODO: Add redirect message

  always_ff @(posedge clk_i)
    if (reset_i)
        state_r <= e_reset;
    else
      begin
        state_r <= state_n;
      end

endmodule

