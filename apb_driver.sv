//------------------------------------------------------------------------------
// File    : apb_driver.sv
// Author  : ken, Lu Wei-Ru
// Created : 2026-01-14
// Brief   : UVM APB master driver. Retrieves apb_seq_item transactions from the
//           sequencer and drives the APB bus through apb_if.MASTER_MP clocking
//           block (m_cb). Implements APB SETUP/ACCESS protocol, holds address/
//           control/data stable during wait states, samples PRDATA/PSLVERR on
//           completion, records wait_cycles, and returns the bus to IDLE.
//------------------------------------------------------------------------------

`ifndef _APB_DRIVER_SV
`define _APB_DRIVER_SV

class apb_driver extends uvm_driver #(apb_seq_item);
  `uvm_component_utils(apb_driver)

  // virtual interface (master side)
  virtual apb_if.MASTER_MP vif;


    //--------------------------------------------------------------------
    //	Methods 
    //--------------------------------------------------------------------	
    extern function new(string name = "apb_driver", uvm_component parent = null);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual task run_phase(uvm_phase phase);
    extern virtual task  drive_idle();
    extern virtual task  wait_reset_release();
    extern virtual task drive_transfer(apb_seq_item tr);
endclass: apb_driver

// Function: new
// Definition: class constructor
function apb_driver::new(string name = "apb_driver", uvm_component parent = null);
    super.new(name, parent);
endfunction: new

// Function: build_phase
// Definition: standard uvm_phase
function void apb_driver::build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual apb_if.MASTER_MP)::get(this, "", "vif", vif)) begin
        `uvm_fatal(get_type_name(), "No virtual interface (vif) for apb_driver. Set it via uvm_config_db.")
    end
endfunction: build_phase

// Task: run_phase
// Definition: standard uvm_phase
task apb_driver::run_phase(uvm_phase phase);
    super.run_phase(phase);

    // Wait for reset release before driving anything
    wait_reset_release();

    forever begin
        apb_seq_item tr;

        seq_item_port.get_next_item(tr);

        `uvm_info(get_type_name(),
                $sformatf("Driving: %s", tr.convert2string()),
                UVM_MEDIUM)

        drive_transfer(tr);

        `uvm_info(get_type_name(),
                $sformatf("Completed: %s", tr.convert2string()),
                UVM_MEDIUM)

        seq_item_port.item_done();
    end
endtask: run_phase


// Task: drive_idle
// Description: Drive bus to IDLE
task apb_driver::drive_idle();
    vif.m_cb.PSEL    <= 1'b0;
    vif.m_cb.PENABLE <= 1'b0;
    vif.m_cb.PWRITE  <= 1'b0;
    vif.m_cb.PADDR   <= '0;  //
    vif.m_cb.PWDATA  <= '0;  // 
endtask: drive_idle

// Task: wait_reset_release
// Description: Wait until reset deasserted
task apb_driver::wait_reset_release();
    // bus safe values during reset
    drive_idle();

    // wait for PRESETn == 1
    while (vif.PRESETn !== 1'b1) begin
        @(vif.m_cb);
        drive_idle();
    end

    // one extra cycle to be safe
    @(vif.m_cb);
    drive_idle();
endtask: wait_reset_release

// Task: drive_transfer
// Definition: Drive a single APB transfer
task apb_driver::drive_transfer(apb_seq_item tr);
    int unsigned wc;

    // default response fields
    tr.wait_cycles = 0;
    tr.slverr      = 0;
    tr.rdata       = '0;

    // -------------------------
    // SETUP phase (PSEL=1, PENABLE=0)
    // -------------------------
    @(vif.m_cb);
    vif.m_cb.PADDR   <= tr.addr;
    vif.m_cb.PWDATA  <= tr.wdata;
    vif.m_cb.PWRITE  <= tr.write;
    vif.m_cb.PSEL    <= 1'b1;
    vif.m_cb.PENABLE <= 1'b0;

    // -------------------------
    // ACCESS phase (PSEL=1, PENABLE=1) until PREADY=1
    // -------------------------
    @(vif.m_cb);
    vif.m_cb.PENABLE <= 1'b1;

    wc = 0;
    // count cycles while waiting for Pready
    while (vif.m_cb.PREADY !== 1'b1) begin
        wc++;
        @(vif.m_cb);
        // keep signals stable during wait states (APB requirement)
        vif.m_cb.PSEL    <= 1'b1;
        vif.m_cb.PENABLE <= 1'b1;
        // PADDR/PWRITE/PWDATA already held by not changing them
    end

    // now transfer completes on this cycle (PREADY=1 sampled)
    tr.wait_cycles = wc;
    tr.slverr      = vif.m_cb.PSLVERR;

    if (!tr.write) begin
        tr.rdata = vif.m_cb.PRDATA;
    end

    // -------------------------
    // Return to IDLE (next cycle)
    // -------------------------
    @(vif.m_cb);
    drive_idle();
endtask: drive_transfer

`endif // _APB_DRIVER_SV