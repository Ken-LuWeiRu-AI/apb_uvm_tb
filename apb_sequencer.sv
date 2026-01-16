//------------------------------------------------------------------------------
// File    : apb_sequencer.sv
// Author  : ken, Lu Wei-Ru
// Created : 2026-01-14
// Brief   : UVM sequencer for APB transactions. Provides arbitration and
//           sequencing of apb_seq_item objects from sequences to the APB driver.
//           Acts as the central request channel between test sequences and the
//           active agent's driver.
//------------------------------------------------------------------------------

`ifndef _APB_SEQUENCER_SV
`define _APB_SEQUENCER_SV

class apb_sequencer extends uvm_sequencer #(apb_seq_item);
  `uvm_component_utils(apb_sequencer)

  function new(string name="apb_sequencer", uvm_component parent=null);
    super.new(name, parent);
  endfunction

endclass

`endif
