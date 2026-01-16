//------------------------------------------------------------------------------
// File    : apb_env.sv
// Author  : ken, Lu Wei-Ru
// Created : 2026-01-14
// Brief   : Top-level UVM environment for the APB testbench. Instantiates and
//           configures the APB agent, reference model, and scoreboard, then
//           connects their analysis/TLM paths. The monitor's observed stream is
//           sent to both the scoreboard (ACT) and the reference model (to
//           generate EXP), and the reference model's predicted stream is sent
//           to the scoreboard for comparison. Provides knobs for active/passive
//           agent mode and optional comparison settings.
//------------------------------------------------------------------------------

`ifndef _APB_ENV_SV
`define _APB_ENV_SV

class apb_env extends uvm_env;
    `uvm_component_utils(apb_env)

    // Components
    apb_agent      agent;
    apb_ref_model  ref_model;
    apb_scoreboard sb;

    // Optional knobs
    uvm_active_passive_enum is_active = UVM_ACTIVE;
    bit slverr_on_illegal_read = 0;
    bit compare_wait_cycles    = 0;

    extern function new (string name="apb_env", uvm_component parent=null);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual function void connect_phase(uvm_phase phase);
endclass : apb_env

function apb_env::new(string name="apb_env", uvm_component parent=null);
    super.new(name, parent);
endfunction

function void apb_env::build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create sub-components
    agent     = apb_agent     ::type_id::create("agent",     this);
    ref_model = apb_ref_model ::type_id::create("ref_model", this);
    sb        = apb_scoreboard::type_id::create("sb",        this);

    // Push config down (optional)
    uvm_config_db#(uvm_active_passive_enum)::set(this, "agent", "is_active", is_active);

    ref_model.slverr_on_illegal_read = slverr_on_illegal_read;
    sb.compare_wait_cycles           = compare_wait_cycles;
endfunction

function void apb_env::connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // -------------------------
    // ACT path: monitor -> scoreboard
    // -------------------------
    agent.monitor.ap.connect(sb.act_imp);

    // -------------------------
    // ACT path: monitor -> ref model (ref model consumes actual to produce expected)
    // -------------------------
    agent.monitor.ap.connect(ref_model.in_imp);

    // -------------------------
    // EXP path: ref model -> scoreboard
    // -------------------------
    ref_model.exp_ap.connect(sb.exp_imp);
endfunction

`endif // _APB_ENV_SV
