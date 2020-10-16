
module bp_nonsynth_host
 import bp_common_pkg::*;
 import bp_common_aviary_pkg::*;
 import bp_be_pkg::*;
 import bp_common_rv64_pkg::*;
 import bp_cce_pkg::*;
 import bsg_noc_pkg::*;
 import bp_common_cfg_link_pkg::*;
 import bp_me_pkg::*;
 #(parameter bp_params_e bp_params_p = e_bp_default_cfg
   `declare_bp_proc_params(bp_params_p)
   `declare_bp_mem_if_widths(paddr_width_p, cce_block_width_p, lce_id_width_p, lce_assoc_p, cce_mem)

   , parameter host_max_outstanding_p = 32
   )
  (input                                     clk_i
   , input                                   reset_i

   , input [cce_mem_msg_width_lp-1:0]        io_cmd_i
   , input                                   io_cmd_v_i
   , output logic                            io_cmd_ready_o

   , output logic [cce_mem_msg_width_lp-1:0] io_resp_o
   , output logic                            io_resp_v_o
   , input                                   io_resp_yumi_i

   , output logic                            icache_trace_en_o
   , output logic                            dcache_trace_en_o
   , output logic                            lce_trace_en_o
   , output logic                            cce_trace_en_o
   , output logic                            dram_trace_en_o
   , output logic                            vm_trace_en_o
   , output logic                            cmt_trace_en_o
   , output logic                            core_profile_en_o
   , output logic                            pc_profile_en_o
   , output logic                            branch_profile_en_o
   );

  import "DPI-C" context function void start();
  import "DPI-C" context function int scan();
  import "DPI-C" context function void pop();
  
  initial start();
 
  logic do_scan;
  bsg_strobe
   #(.width_p(128))
   scan_strobe
    (.clk_i(clk_i)
     ,.reset_r_i(reset_i)
     ,.init_val_r_i('0)
     ,.strobe_r_o(do_scan)
     ); 
  logic [63:0] ch;
  always_ff @(posedge clk_i)
    if (do_scan)
      ch = scan();

  `declare_bp_mem_if(paddr_width_p, cce_block_width_p, lce_id_width_p, lce_assoc_p, cce_mem);
  
  // HOST I/O mappings
  //localparam host_dev_base_addr_gp     = 32'h03??_????;
  
  // Host I/O mappings (arbitrarily decided for now)
  //   Overall host controls 32'h0300_0000-32'h03FF_FFFF
  
  localparam bootrom_base_addr_gp        = paddr_width_p'(64'h0001_????);
  localparam getchar_base_addr_gp        = paddr_width_p'(64'h0010_0000);
  localparam putchar_base_addr_gp        = paddr_width_p'(64'h0010_1000);
  localparam finish_base_addr_gp         = paddr_width_p'(64'h0010_2???);
  localparam dump_base_addr_gp           = paddr_width_p'(64'h0010_3000);
  localparam icache_trace_base_addr_gp   = paddr_width_p'(64'h0010_3018);
  localparam dcache_trace_base_addr_gp   = paddr_width_p'(64'h0010_3020);
  localparam lce_trace_base_addr_gp      = paddr_width_p'(64'h0010_3028);
  localparam cce_trace_base_addr_gp      = paddr_width_p'(64'h0010_3030);
  localparam dram_trace_base_addr_gp     = paddr_width_p'(64'h0010_3038);
  localparam vm_trace_base_addr_gp       = paddr_width_p'(64'h0010_3040);
  localparam cmt_trace_base_addr_gp      = paddr_width_p'(64'h0010_3048);
  localparam core_profile_base_addr_gp   = paddr_width_p'(64'h0010_3050);
  localparam pc_profile_base_addr_gp     = paddr_width_p'(64'h0010_3058);
  localparam branch_profile_base_addr_gp = paddr_width_p'(64'h0010_3060);
  
  `bp_cast_i(bp_cce_mem_msg_s, io_cmd);
  `bp_cast_o(bp_cce_mem_msg_s, io_resp);
  
  bp_cce_mem_msg_s io_cmd_lo;
  logic io_cmd_v_lo, io_cmd_yumi_li;
  bsg_fifo_1r1w_small
   #(.width_p($bits(bp_cce_mem_msg_s)), .els_p(host_max_outstanding_p))
   small_fifo
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
  
     ,.data_i(io_cmd_cast_i)
     ,.v_i(io_cmd_v_i)
     ,.ready_o(io_cmd_ready_o)
  
     ,.data_o(io_cmd_lo)
     ,.v_o(io_cmd_v_lo)
     ,.yumi_i(io_cmd_yumi_li)
     );
  assign io_resp_v_o = io_cmd_v_lo;
  assign io_cmd_yumi_li = io_resp_yumi_i;
  wire [2:0] domain_id = io_cmd_lo.header.addr[paddr_width_p-1-:3];
  
  wire putchar_cmd_v        = io_cmd_v_lo & (io_cmd_lo.header.addr inside {putchar_base_addr_gp});
  wire getchar_cmd_v        = io_cmd_v_lo & (io_cmd_lo.header.addr inside {getchar_base_addr_gp});
  wire finish_cmd_v         = io_cmd_v_lo & (io_cmd_lo.header.addr inside {finish_base_addr_gp});
  wire bootrom_cmd_v        = io_cmd_v_lo & (io_cmd_lo.header.addr inside {bootrom_base_addr_gp});
  wire dump_cmd_v           = io_cmd_v_lo & (io_cmd_lo.header.addr inside {dump_base_addr_gp});
  wire icache_trace_cmd_v   = io_cmd_v_lo & (io_cmd_lo.header.addr inside {icache_trace_base_addr_gp});
  wire dcache_trace_cmd_v   = io_cmd_v_lo & (io_cmd_lo.header.addr inside {dcache_trace_base_addr_gp});
  wire lce_trace_cmd_v      = io_cmd_v_lo & (io_cmd_lo.header.addr inside {lce_trace_base_addr_gp});
  wire cce_trace_cmd_v      = io_cmd_v_lo & (io_cmd_lo.header.addr inside {cce_trace_base_addr_gp});
  wire dram_trace_cmd_v     = io_cmd_v_lo & (io_cmd_lo.header.addr inside {dram_trace_base_addr_gp});
  wire vm_trace_cmd_v       = io_cmd_v_lo & (io_cmd_lo.header.addr inside {vm_trace_base_addr_gp});
  wire cmt_trace_cmd_v      = io_cmd_v_lo & (io_cmd_lo.header.addr inside {cmt_trace_base_addr_gp});
  wire core_profile_cmd_v   = io_cmd_v_lo & (io_cmd_lo.header.addr inside {core_profile_base_addr_gp});
  wire pc_profile_cmd_v     = io_cmd_v_lo & (io_cmd_lo.header.addr inside {pc_profile_base_addr_gp});
  wire branch_profile_cmd_v = io_cmd_v_lo & (io_cmd_lo.header.addr inside {branch_profile_base_addr_gp});
  
  // Memory-mapped I/O is 64 bit aligned
  localparam lg_num_core_lp = `BSG_SAFE_CLOG2(num_core_p);
  localparam byte_offset_width_lp = 3;
  wire [lg_num_core_lp-1:0] io_cmd_core_enc = io_cmd_lo.header.addr[byte_offset_width_lp+:lg_num_core_lp];
  wire [num_core_p-1:0] finish_w_v_li = finish_cmd_v << io_cmd_core_enc;

  logic [num_core_p-1:0] finish_r;
  bsg_dff_reset_set_clear
   #(.width_p(num_core_p))
   finish_accumulator
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
  
     ,.set_i(finish_w_v_li)
     ,.clear_i('0)
     ,.data_o(finish_r)
     );
  
  always_ff @(negedge clk_i)
    begin
      if (putchar_cmd_v)
        begin
          $write("%c", io_cmd_lo.data[0+:8]);
          $fflush(32'h8000_0001);
        end
      else if (getchar_cmd_v)
          pop();
      else if (io_cmd_v_i & (domain_id != '0))
          $display("Warning: Accesing illegal domain %0h. Sending loopback message!", domain_id);
      else if (&finish_r)
        begin
          $display("All cores finished! Terminating...");
          $finish();
        end

      for (integer i = 0; i < num_core_p; i++)
        begin
          // PASS when returned value in finish packet is zero
          if (finish_w_v_li[i] & (~io_cmd_lo.data[0]))
            $display("[CORE%0x FSH] PASS", i);
          // FAIL when returned value in finish packet is non-zero
          if (finish_w_v_li[i] & ( io_cmd_lo.data[0]))
            $display("[CORE%0x FSH] FAIL", i);
        end
    end

  localparam bootrom_els_p = 1024;
  localparam lg_bootrom_els_lp = `BSG_SAFE_CLOG2(bootrom_els_p);
  // bit helps with x pessimism with undersized bootrom
  bit [lg_bootrom_els_lp-1:0] bootrom_addr_li;
  bit [dword_width_p-1:0] bootrom_data_lo;
  assign bootrom_addr_li = io_cmd_lo.header.addr[3+:lg_bootrom_els_lp];
  bsg_nonsynth_test_rom
   #(.filename_p("bootrom.mem")
     ,.data_width_p(dword_width_p)
     ,.addr_width_p(lg_bootrom_els_lp)
     ,.hex_not_bin_p(1)
     )
   bootrom
    (.addr_i(bootrom_addr_li)
     ,.data_o(bootrom_data_lo)
     );

  logic [dword_width_p-1:0] bootrom_final_lo;
  bsg_bus_pack
   #(.width_p(dword_width_p))
   bootrom_pack
    (.data_i(bootrom_data_lo)
     ,.size_i(io_cmd_lo.header.size[0+:2])
     ,.sel_i(io_cmd_lo.header.addr[0+:3])
     ,.data_o(bootrom_final_lo)
     );

  bp_cce_mem_msg_s host_io_resp_lo, bootrom_io_resp_lo;
  
  assign host_io_resp_lo = '{header: io_cmd_lo.header, data: ch};
  assign bootrom_io_resp_lo = '{header: io_cmd_lo.header, data: bootrom_final_lo};

  assign io_resp_cast_o = bootrom_cmd_v ? bootrom_io_resp_lo : host_io_resp_lo;

  always_ff @(posedge clk_i)
    if (reset_i)
      {icache_trace_en_o, dcache_trace_en_o, lce_trace_en_o
       ,cce_trace_en_o, dram_trace_en_o, vm_trace_en_o, cmt_trace_en_o
       ,core_profile_en_o, pc_profile_en_o, branch_profile_en_o
       } <= '0;
    //else if (dump_cmd_v & io_cmd_lo.data[0])
    //  begin
    //    $vcdpluson;
    //    $vcdplusmemon;
    //    $vcdplusautoflushon;
    //  end
    //else if (dump_cmd_v & ~io_cmd_lo.data[0])
    //  begin
    //    $vcdplusoff;
    //    $vcdplusmemoff;
    //    $vcdplusautoflushoff;
    //  end
    else if (icache_trace_cmd_v)
      icache_trace_en_o <= io_cmd_lo.data[0];
    else if (dcache_trace_cmd_v)
      dcache_trace_en_o <= io_cmd_lo.data[0];
    else if (lce_trace_cmd_v)
      lce_trace_en_o <= io_cmd_lo.data[0];
    else if (cce_trace_cmd_v)
      cce_trace_en_o <= io_cmd_lo.data[0];
    else if (dram_trace_cmd_v)
      dram_trace_en_o <= io_cmd_lo.data[0];
    else if (vm_trace_cmd_v)
      vm_trace_en_o <= io_cmd_lo.data[0];
    else if (cmt_trace_cmd_v)
      cmt_trace_en_o <= io_cmd_lo.data[0];
    else if (core_profile_cmd_v)
      core_profile_en_o <= io_cmd_lo.data[0];
    else if (pc_profile_cmd_v)
      pc_profile_en_o <= io_cmd_lo.data[0];
    else if (branch_profile_cmd_v)
      branch_profile_en_o <= io_cmd_lo.data[0];

endmodule

