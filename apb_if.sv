//------------------------------------------------------------------------------
// File    : apb_if.sv
// Author  : ken, Lu Wei-Ru
// Created : 2026-01-14
// Brief   : APB SystemVerilog interface for the UVM testbench. Defines the APB
//           signal bundle (addr/data/control/response), provides clocking blocks
//           for cycle-accurate sampling/driving (m_cb for the master driver and
//           mon_cb for passive monitoring), and exposes modports (MASTER_MP and
//           MON_MP) used as virtual interfaces in UVM components. Includes a
//           basic protocol assertion (PENABLE implies PSEL) to catch APB usage
//           violations during simulation.
//---------------------------------------------------------------------------

`ifndef _APB_IF_
`define _APB_IF_

`include "apb_defines.sv"

interface apb_if (
  input  logic PCLK,
  input  logic PRESETn
);

  logic PSEL;
  logic PENABLE;
  logic PWRITE;

  logic PREADY;
  logic PSLVERR;
  logic [`ADDR_WIDTH-1:0] PADDR;
  logic [`DATA_WIDTH-1:0] PWDATA;
  logic [`DATA_WIDTH-1:0] PRDATA;

  // Master driver clocking block
  clocking m_cb @(posedge PCLK);
    default input #1step output #0;
    output PSEL, PENABLE, PWRITE, PADDR, PWDATA;
    input  PREADY, PSLVERR, PRDATA;
  endclocking

  // Monitor clocking block
  clocking mon_cb @(posedge PCLK);
    default input #1step output #0;
    input PSEL, PENABLE, PWRITE, PADDR, PWDATA, PREADY, PSLVERR, PRDATA;
  endclocking

  modport MASTER_MP (clocking m_cb, input PCLK, input PRESETn);
  modport MON_MP    (clocking mon_cb, input PCLK, input PRESETn);

  // Assertion
  property p_penable_implies_psel;
    @(posedge PCLK) disable iff (!PRESETn)
      PENABLE |-> PSEL;
  endproperty
  a_penable_implies_psel: assert property (p_penable_implies_psel);

endinterface
`endif
