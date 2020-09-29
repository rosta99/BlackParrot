/**
 * bp_common_bedrock_if.h
 *
 * This file defines the LCE-CCE and CCE-MEM interfaces in the BlackParrot BedRock cohrence
 * system.
 *
 * This file is derived from bp_common/bp_common_bedrock_if.vh
 *
 */

#ifndef BP_COMMON_BEDROCK_IF_H
#define BP_COMMON_BEDROCK_IF_H

typedef enum {
  e_bedrock_msg_size_1        = 0  // 1 byte
  ,e_bedrock_msg_size_2       = 1  // 2 bytes
  ,e_bedrock_msg_size_4       = 2  // 4 bytes
  ,e_bedrock_msg_size_8       = 3  // 8 bytes
  ,e_bedrock_msg_size_16      = 4  // 16 bytes
  ,e_bedrock_msg_size_32      = 5  // 32 bytes
  ,e_bedrock_msg_size_64      = 6  // 64 bytes
  ,e_bedrock_msg_size_128     = 7  // 128 bytes
} bp_bedrock_msg_size_e;

#define bp_bedrock_msg_size_width 3

// Mem Commands
typedef enum {
  e_bedrock_mem_rd               = 0
  ,e_bedrock_mem_wr              = 1
  ,e_bedrock_mem_uc_rd           = 2
  ,e_bedrock_mem_uc_wr           = 3
  ,e_bedrock_mem_pre             = 4
  ,e_bedrock_mem_lr              = 5
  ,e_bedrock_mem_sc              = 6
  ,e_bedrock_mem_amoswap         = 7
  ,e_bedrock_mem_amoadd          = 8
  ,e_bedrock_mem_amoxor          = 9
  ,e_bedrock_mem_amoand          = 10
  ,e_bedrock_mem_amoor           = 11
  ,e_bedrock_mem_amomin          = 12
  ,e_bedrock_mem_amomax          = 13
  ,e_bedrock_mem_amominu         = 14
  ,e_bedrock_mem_amomaxu         = 15
} bp_bedrock_mem_type_e;

#define bp_bedrock_mem_type_width 4

// LCE Requests
typedef enum {
  e_bedrock_req_rd          = 0 // Read-miss
  ,e_bedrock_req_wr         = 1 // Write-miss
  ,e_bedrock_req_uc_rd      = 2 // Uncached Load
  ,e_bedrock_req_uc_wr      = 3 // Uncached Store
  ,e_bedrock_req_amoswap    = 4
  ,e_bedrock_req_amoadd     = 5
  ,e_bedrock_req_amoxor     = 6
  ,e_bedrock_req_amoand     = 7
  ,e_bedrock_req_amoor      = 8
  ,e_bedrock_req_amomin     = 9
  ,e_bedrock_req_amomax     = 10
  ,e_bedrock_req_amominu    = 11
  ,e_bedrock_req_amomaxu    = 12
} bp_bedrock_req_type_e;

#define bp_bedrock_req_type_width 4

typedef enum {
  e_bedrock_req_excl             = 0 // Exclusive cache line request (read-only, exclusive request)
  ,e_bedrock_req_not_excl        = 1 // Non-Exclusive cache line request (read-only, shared request)
} bp_bedrock_req_non_excl_e;

#define bp_bedrock_req_non_excl_width 1

// LCE Commands
typedef enum {
  e_bedrock_cmd_sync             = 0
  ,e_bedrock_cmd_set_clear       = 1
  ,e_bedrock_cmd_inv             = 2
  ,e_bedrock_cmd_st              = 3
  ,e_bedrock_cmd_data            = 4
  ,e_bedrock_cmd_st_wakeup       = 5
  ,e_bedrock_cmd_wb              = 6
  ,e_bedrock_cmd_st_wb           = 7
  ,e_bedrock_cmd_tr              = 8
  ,e_bedrock_cmd_st_tr           = 9
  ,e_bedrock_cmd_st_tr_wb        = 10
  ,e_bedrock_cmd_uc_data         = 11
  ,e_bedrock_cmd_uc_req_done     = 12
  ,e_bedrock_cmd_custom_13       = 13
  ,e_bedrock_cmd_custom_14       = 14
  ,e_bedrock_cmd_custom_15       = 15
} bp_bedrock_cmd_type_e;

#define bp_bedrock_cmd_type_width 4

// LCE Responses
typedef enum {
  e_bedrock_resp_sync_ack         = 0 // Sync Ack
  ,e_bedrock_resp_inv_ack         = 1 // Invalidate Tag Ack
  ,e_bedrock_resp_coh_ack         = 2 // Coherence Ack
  ,e_bedrock_resp_wb              = 3 // Normal Writeback Response
  ,e_bedrock_resp_null_wb         = 4 // Null Writeback Response
} bp_bedrock_resp_type_e;

#define bp_bedrock_resp_type_width 4

// Coherence States
typedef enum {
  e_COH_I  = 0
  ,e_COH_S = 1
  ,e_COH_E = 2
  ,e_COH_F = 3
  // 4 = potentially dirty, not owned, not shared
  // 5 = potentially dirty, not owned, shared
  ,e_COH_M = 6
  ,e_COH_O = 7
} bp_coh_states_e;

#define bp_coh_shared_bit 0
#define bp_coh_owned_bit 1
#define bp_coh_dirty_bit 2

#define bp_coh_bits 3

#endif // BP_COMMON_BEDROCK_IF_H
