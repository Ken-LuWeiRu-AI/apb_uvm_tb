//------------------------------------------------------------------------------
// File    : apb_defines.sv
// Author  : ken, Lu Wei-Ru
// Created : 2026-01-14
// Brief   : Global APB parameter definitions for the UVM testbench. Defines
//           address and data bus widths (ADDR_WIDTH, DATA_WIDTH) shared by
//           the APB interface, DUT, and verification components to ensure
//           consistent signal sizing across the environment.
//------------------------------------------------------------------------------

`ifndef _APB_DEFINES_
`define _APB_DEFINES_

`define ADDR_WIDTH 8
`define DATA_WIDTH 8

`endif