//------------------------------------------------------------------------------
// File    : apb_test.sv
// Author  : ken, Lu Wei-Ru
// Created : 2026-01-14
// Brief   : UVM test that builds the APB verification environment (env), passes
//           configurable knobs (active/passive mode, illegal-read SLVERR option,
//           and optional wait-cycle comparison) down to the environment, then
//           runs a simple directed flow: a write sequence followed by a read
//           sequence on the agent sequencer. Uses UVM objections to control the
//           duration of the test.
//------------------------------------------------------------------------------

`ifndef _APB_TEST_SV
`define _APB_TEST_SV

class apb_test extends uvm_test;
    `uvm_component_utils(apb_test)

    apb_env env;

    // knobs
    uvm_active_passive_enum is_active = UVM_ACTIVE;
    bit slverr_on_illegal_read = 0;
    bit compare_wait_cycles    = 0;

    extern function new(string name="apb_test", uvm_component parent=null);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual task run_phase(uvm_phase phase);
endclass : apb_test

function apb_test::new(string name="apb_test", uvm_component parent=null);
    super.new(name, parent);
endfunction: new

function void apb_test::build_phase(uvm_phase phase);
    super.build_phase(phase);

    env = apb_env::type_id::create("env", this);

    // push knobs down to env before env.build_phase uses them
    env.is_active             = is_active;
    env.slverr_on_illegal_read= slverr_on_illegal_read;
    env.compare_wait_cycles   = compare_wait_cycles;
endfunction: build_phase

task apb_test::run_phase(uvm_phase phase);
    apb_write_seq wseq;
    apb_read_seq  rseq;

    phase.raise_objection(this);

    // 1) write seq
    wseq = apb_write_seq::type_id::create("wseq");
    wseq.num_writes = 10;
    wseq.allow_illegal_addr = 0; // 先跑合法
    wseq.start(env.agent.sequencer);

    // 2) read seq
    rseq = apb_read_seq::type_id::create("rseq");
    rseq.num_reads = 10;
    rseq.allow_illegal_addr = 0; // 先跑合法
    rseq.start(env.agent.sequencer);

    phase.drop_objection(this);
endtask: run_phase

`endif
// _APB_TEST_SV