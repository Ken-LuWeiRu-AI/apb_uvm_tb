//------------------------------------------------------------------------------
// File    : apb_agent.sv
// Author  : ken, Lu Wei-Ru
// Created : 2026-01-14
// Brief   : UVM APB agent that encapsulates sequencer, driver, and monitor.
//           Supports ACTIVE and PASSIVE modes: in ACTIVE mode, the agent
//           creates and connects the sequencer and driver to generate and
//           drive APB transactions; in PASSIVE mode, only the monitor is
//           instantiated to observe bus activity. Configuration is controlled
//           via uvm_active_passive_enum.
//------------------------------------------------------------------------------
`ifndef _APB_AGENT_SV
`define _APB_AGENT_SV

class apb_agent extends uvm_agent;
  `uvm_component_utils(apb_agent)

  // -------------------------
  // Sub-components
  // -------------------------
  apb_sequencer  sequencer;
  apb_driver     driver;
  apb_monitor    monitor;

  // Active / Passive control
  uvm_active_passive_enum is_active;

  //--------------------------------------------------------------------
  // Methods
  //--------------------------------------------------------------------
  extern function new(string name="apb_agent", uvm_component parent=null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);

endclass : apb_agent

// Function: new
// Definition: class constructor
function apb_agent::new(string name="apb_agent", uvm_component parent=null);
  super.new(name, parent);
endfunction

// Function: build_phase
// Definition: standard uvm_phase
function void apb_agent::build_phase(uvm_phase phase);
  super.build_phase(phase);

  // Get active/passive config (default ACTIVE)
  if (!uvm_config_db#(uvm_active_passive_enum)::get(
        this, "", "is_active", is_active)) begin
    is_active = UVM_ACTIVE;
  end

  // Monitor always exists
  monitor = apb_monitor::type_id::create("monitor", this);

  if (is_active == UVM_ACTIVE) begin
    sequencer = apb_sequencer::type_id::create("sequencer", this);
    driver    = apb_driver   ::type_id::create("driver",    this);
  end
endfunction

// Function: connect_phase
// Definition:  hook up TLM connections
function void apb_agent::connect_phase(uvm_phase phase);
  super.connect_phase(phase);

  if (is_active == UVM_ACTIVE) begin
    driver.seq_item_port.connect(sequencer.seq_item_export);
  end
endfunction

`endif // _APB_AGENT_SV
