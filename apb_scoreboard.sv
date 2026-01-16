//------------------------------------------------------------------------------
// File    : apb_scoreboard.sv
// Author  : ken, Lu Wei-Ru
// Created : 2026-01-14
// Brief   : APB scoreboard that compares ACT (observed) transactions from the
//           monitor against EXP (predicted) transactions from the reference
//           model. Uses two distinct analysis_imps (write_act/write_exp) to
//           receive streams, queues them to handle timing/skew, then pops and
//           compares in order (addr/write alignment, WDATA/RDATA/SLVERR, and
//           optionally wait_cycles). Tracks compare/error counts and prints a
//           summary in report_phase.
//------------------------------------------------------------------------------

`ifndef _APB_SCOREBOARD_SV
`define _APB_SCOREBOARD_SV

// 先宣告兩種不同的 analysis_imp，避免 callback 都叫 write()
`uvm_analysis_imp_decl(_act)
`uvm_analysis_imp_decl(_exp)

class apb_scoreboard extends uvm_component;
    `uvm_component_utils(apb_scoreboard)

    // ACT: from monitor
    uvm_analysis_imp_act #(apb_seq_item, apb_scoreboard) act_imp;

    // EXP: from ref model
    uvm_analysis_imp_exp #(apb_seq_item, apb_scoreboard) exp_imp;

    apb_seq_item act_q[$];
    apb_seq_item exp_q[$];

    int unsigned num_cmp;
    int unsigned num_err;

    bit compare_wait_cycles = 0;

    extern function new(string name="apb_scoreboard", uvm_component parent=null);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual function void write_act(apb_seq_item tr);
    extern virtual function void write_exp(apb_seq_item tr);
    extern virtual function void try_compare();
    extern virtual function void report_phase(uvm_phase phase);
endclass : apb_scoreboard

function apb_scoreboard::new(string name="apb_scoreboard", uvm_component parent=null);
    super.new(name, parent);
    act_imp = new("act_imp", this);
    exp_imp = new("exp_imp", this);
endfunction

function void apb_scoreboard::build_phase(uvm_phase phase);
    super.build_phase(phase);
    num_cmp = 0;
    num_err = 0;
endfunction

// monitor -> scoreboard
function void apb_scoreboard::write_act(apb_seq_item tr);
    apb_seq_item c = apb_seq_item::type_id::create("act_copy");
    c.copy(tr);
    act_q.push_back(c);
    try_compare();
endfunction

// ref_model -> scoreboard
function void apb_scoreboard::write_exp(apb_seq_item tr);
    apb_seq_item c = apb_seq_item::type_id::create("exp_copy");
    c.copy(tr);
    exp_q.push_back(c);
    try_compare();
endfunction

function void apb_scoreboard::try_compare();
    apb_seq_item act, exp;

    while (act_q.size() > 0 && exp_q.size() > 0) begin
        act = act_q.pop_front();
        exp = exp_q.pop_front();
        num_cmp++;

        // Alignment check (to avoid comparing mismatched transactions)
        if (act.addr !== exp.addr || act.write !== exp.write) begin
            num_err++;
            `uvm_error(get_type_name(),
            $sformatf("ALIGN mismatch: act(addr=0x%0h write=%0b) exp(addr=0x%0h write=%0b)",
                        act.addr, act.write, exp.addr, exp.write))
            continue;
        end

        if (act.write && act.wdata !== exp.wdata) begin
            num_err++;
            `uvm_error(get_type_name(),
            $sformatf("WDATA mismatch: addr=0x%0h act=0x%0h exp=0x%0h",
                        act.addr, act.wdata, exp.wdata))
        end

        if (act.slverr !== exp.slverr) begin
            num_err++;
            `uvm_error(get_type_name(),
            $sformatf("SLVERR mismatch: addr=0x%0h write=%0b act=%0b exp=%0b",
                        act.addr, act.write, act.slverr, exp.slverr))
        end

        if (!act.write && act.rdata !== exp.rdata) begin
            num_err++;
            `uvm_error(get_type_name(),
            $sformatf("RDATA mismatch: addr=0x%0h act=0x%0h exp=0x%0h",
                        act.addr, act.rdata, exp.rdata))
        end

        if (compare_wait_cycles && act.wait_cycles !== exp.wait_cycles) begin
            num_err++;
            `uvm_error(get_type_name(),
            $sformatf("WAIT_CYCLES mismatch: addr=0x%0h act=%0d exp=%0d",
                        act.addr, act.wait_cycles, exp.wait_cycles))
        end
    end
endfunction

function void apb_scoreboard::report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(),
    $sformatf("SCOREBOARD summary: compared=%0d errors=%0d act_left=%0d exp_left=%0d",
                num_cmp, num_err, act_q.size(), exp_q.size()),
    UVM_NONE)
endfunction

`endif