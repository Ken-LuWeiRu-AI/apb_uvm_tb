//------------------------------------------------------------------------------
// File    : apb_top.sv
// Author  : ken, Lu Wei-Ru
// Created : 2026-01-14
// Brief   : Top-level APB UVM testbench. Generates clock and reset, instantiates
//           the APB interface and DUT, configures virtual interface bindings
//           for the UVM driver and monitor via uvm_config_db, and starts the
//           UVM test (apb_test).
//------------------------------------------------------------------------------


`timescale 1ns/1ps

`include "uvm_macros.svh"    // UVM macros
`include "apb_tb_pkg.sv"        // APB package
`include "apb_if.sv"
import uvm_pkg::*;           // Import UVM package
import apb_tb_pkg::*;               // Import user-defined package (APB environment)

module apb_top;

  // -------------------------
  // Clock / Reset
  // -------------------------
  logic PCLK;
  logic PRESETn;

  initial begin
    PCLK = 0;
    forever #5 PCLK = ~PCLK;   // 100MHz
  end

  initial begin
    PRESETn = 0;
    repeat (5) @(posedge PCLK);
    PRESETn = 1;
  end

  // -------------------------
  // Interface instance
  // -------------------------
  apb_if apb_vif (
    .PCLK(PCLK),
    .PRESETn(PRESETn)
  );

  // -------------------------
  // DUT instance
  // -------------------------
  apb_slave #(.N(4)) dut (
    .PCLK    (PCLK),
    .PRESETn (PRESETn),
    .PSEL    (apb_vif.PSEL),
    .PENABLE (apb_vif.PENABLE),
    .PWRITE  (apb_vif.PWRITE),
    .PADDR   (apb_vif.PADDR),
    .PWDATA  (apb_vif.PWDATA),
    .PRDATA  (apb_vif.PRDATA),
    .PREADY  (apb_vif.PREADY),
    .PSLVERR (apb_vif.PSLVERR)
  );

  // -------------------------
  // UVM config + run_test
  // -------------------------
  initial begin
    // give driver the MASTER modport
    uvm_config_db#(virtual apb_if.MASTER_MP)::set(
      null, "uvm_test_top.env.agent.driver", "vif", apb_vif
    );

    // give monitor the MON modport
    uvm_config_db#(virtual apb_if.MON_MP)::set(
      null, "uvm_test_top.env.agent.monitor", "vif", apb_vif
    );

    // (optional) set default test if you don't pass +UVM_TESTNAME
    run_test("apb_test");
  end

endmodule : apb_top
// apt_top.sv
