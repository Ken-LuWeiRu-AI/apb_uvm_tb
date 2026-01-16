//------------------------------------------------------------------------------
// File    : apb_read_seq.sv
// Author  : ken, Lu Wei-Ru
// Created : 2026-01-14
// Brief   : APB read sequence for the UVM environment.
//           Generates a programmable number of READ transactions (num_reads)
//           and sends them to the APB sequencer/driver. The sequence can be
//           configured to produce only legal addresses (0x00~0x07) or to mix in
//           illegal addresses (0x00~0x0F) via allow_illegal_addr, so you can
//           trigger/verify DUT PSLVERR behavior on out-of-range accesses.
//------------------------------------------------------------------------------

`ifndef _APB_READ_SEQ_SV
`define _APB_READ_SEQ_SV

class apb_read_seq extends uvm_sequence #(apb_seq_item);
  `uvm_object_utils(apb_read_seq)

  // how many reads to generate
  rand int unsigned num_reads;

  // allow illegal address generation (addr > 0x07) to trigger PSLVERR in your DUT
  rand bit allow_illegal_addr;

  //--------------------------------------------------------------------
  // Methods
  //--------------------------------------------------------------------
  extern function new(string name="apb_read_seq");
  extern task body();

endclass

// Function: new
// Definition: class constructor
function apb_read_seq::new(string name="apb_read_seq");
  super.new(name);
  num_reads = 10;
  allow_illegal_addr = 0;
endfunction

// Function: body
// Definition: body method that gets executed once sequence is started
task apb_read_seq::body();
  apb_seq_item tr;

  `uvm_info(get_type_name(),
            $sformatf("Start apb_read_seq: num_reads=%0d allow_illegal_addr=%0b",
                      num_reads, allow_illegal_addr),
            UVM_LOW)

  repeat (num_reads) begin
    tr = apb_seq_item::type_id::create("tr");

    start_item(tr);

    // Force this item to be a READ
    if (allow_illegal_addr) begin
      // mix legal + illegal addresses (0x00~0x0F)
      assert(tr.randomize() with {
        write == 0;
        addr inside {[8'h00:8'h0F]};
      }) else `uvm_fatal(get_type_name(), "Randomize failed in apb_read_seq (allow_illegal_addr=1)")
    end
    else begin
      // legal only (0x00~0x07)
      assert(tr.randomize() with {
        write == 0;
        addr inside {[8'h00:8'h07]};
      }) else `uvm_fatal(get_type_name(), "Randomize failed in apb_read_seq (allow_illegal_addr=0)")
    end

    finish_item(tr);

    `uvm_info(get_type_name(),
              $sformatf("READ issued: addr=0x%0h", tr.addr),
              UVM_MEDIUM)
  end

  `uvm_info(get_type_name(), "Finish apb_read_seq", UVM_LOW)
endtask

`endif
