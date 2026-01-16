//------------------------------------------------------------------------------
// File    : apb_monitor.sv
// Author  : ken, Lu Wei-Ru
// Created : 2026-01-14
// Brief   : Passive APB bus monitor. Samples APB signals via the MON modport
//           clocking block, reconstructs each transfer across SETUP/ACCESS
//           phases, counts wait states until PREADY, captures PSLVERR and
//           read data (PRDATA) when applicable, then publishes the observed
//           apb_seq_item through an analysis_port to the ref model/scoreboard.
//           Resets internal state when PRESETn is deasserted.
//------------------------------------------------------------------------------

`ifndef _APB_MONITOR_SV
`define _APB_MONITOR_SV

class apb_monitor extends uvm_monitor;
  `uvm_component_utils(apb_monitor)

  // Passive monitor uses MON modport / clocking block
  virtual apb_if.MON_MP vif;

  // Send observed transfers to scoreboard/model
  uvm_analysis_port #(apb_seq_item) ap;

  // Internal state for current transfer
  apb_seq_item    tr;
  bit             in_transfer;
  int unsigned    wait_cnt;

  bit setup_phase;
  bit access_phase;

	//--------------------------------------------------------------------
	//	Methods
	//--------------------------------------------------------------------
    extern function new(string name="apb_monitor", uvm_component parent=null);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual task run_phase(uvm_phase phase);
endclass: apb_monitor

// Function: new
// Definition: class constructor
function apb_monitor::new(string name="apb_monitor", uvm_component parent=null);
    super.new(name, parent);
    ap = new("ap", this);
endfunction

// Function: build_phase
// Definition: standard uvm_phase
function void apb_monitor::build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual apb_if.MON_MP)::get(this, "", "vif", vif)) begin
        `uvm_fatal(get_type_name(), "No virtual interface (vif) for apb_monitor. Set it via uvm_config_db.")
    end
endfunction

// Task: run_phase
// Definition: standard uvm_phase	
task apb_monitor::run_phase(uvm_phase phase);
    super.run_phase(phase);

    in_transfer = 0;
    wait_cnt    = 0;
    tr          = null;

    forever begin
        @(vif.mon_cb);

        // Reset active: clear internal state, do not sample transfers
        if (vif.PRESETn !== 1'b1) begin
        in_transfer = 0;
        wait_cnt    = 0;
        tr          = null;
        continue;
        end

        // Detect phases from sampled signals
        setup_phase  = (vif.mon_cb.PSEL && !vif.mon_cb.PENABLE);
        access_phase = (vif.mon_cb.PSEL &&  vif.mon_cb.PENABLE);

        // Start of a new transfer at SETUP phase
        if (setup_phase) begin
        tr = apb_seq_item::type_id::create("tr", this);

        // latch request info at setup  
        tr.addr  = vif.mon_cb.PADDR;
        tr.write = vif.mon_cb.PWRITE;
        tr.wdata = vif.mon_cb.PWDATA;

        tr.rdata       = '0;
        tr.slverr      = 0;
        tr.wait_cycles = 0;

        in_transfer = 1;
        wait_cnt    = 0;
        end

        // During ACCESS, count wait states if not ready yet
        if (in_transfer && access_phase) begin
            if (vif.mon_cb.PREADY !== 1'b1) begin
                wait_cnt++;
            end else begin
                // Transfer completes when PREADY==1
                tr.wait_cycles = wait_cnt;
                tr.slverr      = vif.mon_cb.PSLVERR;

                if (!tr.write) begin
                tr.rdata = vif.mon_cb.PRDATA;
                end

                `uvm_info(get_type_name(),
                        $sformatf("Observed: %s", tr.convert2string()),
                        UVM_MEDIUM)

                // Publish observed transaction
                ap.write(tr);

                // done
                in_transfer = 0;
                wait_cnt    = 0;
                tr          = null;
            end
        end

        // If bus goes idle unexpectedly, drop partial state
        if (in_transfer && !vif.mon_cb.PSEL) begin
            in_transfer = 0;
            wait_cnt    = 0;
            tr          = null;
        end
    end
endtask

`endif // _APB_MONITOR_SV
