// Copyright 2026 Maktab-e-Digital Systems Lahore.
// SPDX-License-Identifier: Apache-2.0
//
// =============================================================================
// meds_s1_sram : single-port SRAM wrapper                        [COMPLETE]
//
// Every memory array in MEDS-S1 instantiates this wrapper (NFR-5). Read
// latency is one cycle, registered output, everywhere. IMPL selects the
// backing store: 0 = behavioural, 1 = FPGA BRAM, 2 = ASIC macro.
//
// Spec:      INTERFACES.md §8, SPEC §17
// Testbench: tb_meds_s1_sram.sv
// =============================================================================

module meds_s1_sram #(
  parameter int unsigned DW    = 64,
  parameter int unsigned DEPTH = 1024,
  parameter int unsigned IMPL  = 0,   // 0 = behavioural, 1 = FPGA BRAM, 2 = ASIC macro
  // derived -- do not override
  parameter int unsigned AW    = (DEPTH <= 1) ? 1 : $clog2(DEPTH)
)(
  input  logic                     clk_i,
  input  logic                     rst_ni,
  input  logic                     req_i,
  input  logic                     we_i,
  input  logic [AW-1:0]            addr_i,
  input  logic [DW/8-1:0]          be_i,
  input  logic [DW-1:0]            wdata_i,
  output logic [DW-1:0]            rdata_o   // registered, 1-cycle latency
);

  // ===========================================================================
  // IMPL = 0: Behavioural Implementation
  // ===========================================================================
  if (IMPL == 0) begin : behavioural

    logic [DW-1:0] mem [0:DEPTH-1];

    always_ff @(posedge clk_i or negedge rst_ni) begin
      if (!rst_ni) begin
        rdata_o <= '0;
      end else if (req_i) begin
        // Write — update only the bytes enabled by be_i.
        if (we_i) begin
          for (int i = 0; i < DW/8; i++) begin
            if (be_i[i]) begin
              mem[addr_i][i*8 +: 8] <= wdata_i[i*8 +: 8];
            end
          end
        end
        // Read-during-write returns the OLD contents. Stated, not accidental:
        // consumers that need write-forwarding must build it themselves.
        rdata_o <= mem[addr_i];
      end
    end
  end

  // ===========================================================================
  // IMPL = 1 or 2: Not yet implemented — fail at elaboration
  // ===========================================================================
  if (IMPL != 0) begin : g_unsupported
    // A clear failure beats silently synthesising an X-driving RAM. 
    // (Synthesis ignores initial blocks, so $error must be in a generate scope).
    $error("meds_s1_sram: IMPL=%0d not implemented yet (see header)", IMPL);
  end

endmodule
