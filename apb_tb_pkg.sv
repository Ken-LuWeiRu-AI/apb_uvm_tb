//------------------------------------------------------------------------------
// File    : apb_tb_pkg.sv
// Author  : ken, Lu Wei-Ru
// Created : 2026-01-14
// Brief   : APB UVM testbench package that aggregates and compiles all UVM TB
//           components (sequence item, sequencer, driver, monitor, agent, ref
//           model, scoreboard, env, sequences, and test) into a single package
//           namespace (apb_tb_pkg). This centralizes include order and makes the
//           testbench importable via `import apb_tb_pkg::*;` from the top module.
//           Note: interface definitions (apb_if.sv) should be compiled/`included
//           outside the package to avoid parsing errors and to keep design units
//           (interface/module) separate from package/class code.
//------------------------------------------------------------------------------

package apb_tb_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
//   `include "apb_if.sv"	
  `include "apb_defines.sv"
  `include "apb_seq_item.sv"
  `include "apb_sequencer.sv"
  `include "apb_driver.sv"
  `include "apb_monitor.sv"
  `include "apb_agent.sv"
  `include "apb_ref_model.sv"
  `include "apb_scoreboard.sv"
  `include "apb_env.sv"
  `include "apb_write_seq.sv"
  `include "apb_read_seq.sv"
  `include "apb_test.sv"
endpackage
