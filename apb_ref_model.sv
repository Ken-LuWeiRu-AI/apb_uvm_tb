//------------------------------------------------------------------------------
// File    : apb_ref_model.sv
// Author  : ken, Lu Wei-Ru
// Created : 2026-01-14
// Brief   : APB reference model (golden model) for the UVM environment.
//           Consumes *actual* APB transactions observed by the monitor via an
//           analysis_imp (in_imp), maintains a mirrored memory image, and
//           produces *expected* transactions via an analysis_port (exp_ap) for
//           the scoreboard to compare against DUT behavior.
//
//           Features:
//           - Mirror memory (0x00~0x07) updated on legal writes.
//           - Generates expected read data from the mirror.
//           - Predicts PSLVERR for illegal accesses (writes always; reads
//             optionally controlled by slverr_on_illegal_read).
//           - Optionally forwards wait_cycles for timing comparisons.
//------------------------------------------------------------------------------

`ifndef _APB_REF_MODEL_SV
`define _APB_REF_MODEL_SV

class apb_ref_model extends uvm_component;
  `uvm_component_utils(apb_ref_model)

  // input: from monitor (actual observed)
  uvm_analysis_imp #(apb_seq_item, apb_ref_model) in_imp;

  // output: expected transactions to scoreboard
  uvm_analysis_port #(apb_seq_item) exp_ap;

  // mirror memory
  logic [7:0] mirror_mem [0:7];

  // option: illegal read expect slverr?
  bit slverr_on_illegal_read = 0;

  extern function new(string name="apb_ref_model", uvm_component parent=null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void reset_model();
  extern virtual function void write(apb_seq_item tr);
endclass : apb_ref_model


function apb_ref_model::new(string name="apb_ref_model", uvm_component parent=null);
  super.new(name, parent);
  in_imp = new("in_imp", this);
  exp_ap = new("exp_ap", this);
endfunction

function void apb_ref_model::build_phase(uvm_phase phase);
  super.build_phase(phase);
  reset_model();
endfunction 

function void apb_ref_model::reset_model();
  for (int i=0; i<8; i++) mirror_mem[i] = 8'h00;
endfunction

// called by in_imp
function void apb_ref_model::write(apb_seq_item tr);
  apb_seq_item exp_tr;
  bit illegal;
  logic [2:0] idx;

  exp_tr = apb_seq_item::type_id::create("exp_tr", this);

  // copy request fields (so scoreboard can match)
  exp_tr.addr       = tr.addr;
  exp_tr.write      = tr.write;
  exp_tr.wdata      = tr.wdata;
  exp_tr.wait_cycles= tr.wait_cycles; // optional: if you want compare wait_cycles too

  illegal = (tr.addr > 8'h07);
  idx     = tr.addr[2:0];

  // expected slverr
  if (tr.write) begin
    exp_tr.slverr = illegal; // your DUT: illegal WRITE -> slverr=1
  end else begin
    exp_tr.slverr = (slverr_on_illegal_read) ? illegal : 1'b0;
  end

  // expected rdata for read
  if (!tr.write) begin
    exp_tr.rdata = mirror_mem[idx];
  end else begin
    exp_tr.rdata = '0; // don't care for write
  end

  // update mirror on legal write
  if (tr.write && !illegal) begin
    mirror_mem[idx] = tr.wdata;
  end

  `uvm_info(get_type_name(),
    $sformatf("REF expected: %s", exp_tr.convert2string()),
    UVM_LOW)

  // broadcast expected to scoreboard
  exp_ap.write(exp_tr);
endfunction 

`endif // _APB_REF_MODEL_SV
