//------------------------------------------------------------------------------
// File    : apb_write_seq.sv
// Author  : ken, Lu Wei-Ru
// Created : 2026-01-14
// Brief   : UVM sequence that generates a configurable number of APB WRITE
//           transactions (apb_seq_item). Supports optional illegal address
//           generation to exercise DUT error handling (e.g., PSLVERR). Each
//           item is randomized with write==1 and an address range based on
//           allow_illegal_addr, then issued to the sequencer/driver.
//------------------------------------------------------------------------------

`ifndef _APB_WRITE_SEQ_SV
`define _APB_WRITE_SEQ_SV

class apb_write_seq extends uvm_sequence #(apb_seq_item);
  `uvm_object_utils(apb_write_seq)

  // how many writes to generate
  rand int unsigned num_writes;

  // allow illegal address generation (addr > 0x07) to trigger PSLVERR in your DUT
  rand bit allow_illegal_addr;

	//--------------------------------------------------------------------
	//	Methods
	//--------------------------------------------------------------------
    extern function new(string name="apb_write_seq");
    extern task body();

endclass

// Function: new
// Definition: class constructor	
function apb_write_seq::new(string name="apb_write_seq");
    super.new(name);
    num_writes = 10;
    allow_illegal_addr = 0;
endfunction

// Function: body
// Definition: body method that gets executed once sequence is started 
task apb_write_seq::body();
    apb_seq_item tr;

    `uvm_info(get_type_name(),
                $sformatf("Start apb_write_seq: num_writes=%0d allow_illegal_addr=%0b",
                        num_writes, allow_illegal_addr),
                UVM_LOW)

    repeat (num_writes) begin
        tr = apb_seq_item::type_id::create("tr");

        start_item(tr);

        // Force this item to be a WRITE
        if (allow_illegal_addr) begin
        // mix legal + illegal addresses (0x00~0x0F)
        assert(tr.randomize() with {
            write == 1;
            addr inside {[8'h00:8'h0F]};
        }) else `uvm_fatal(get_type_name(), "Randomize failed in apb_write_seq (allow_illegal_addr=1)")
        end
        else begin
        // legal only (0x00~0x07)
        assert(tr.randomize() with {
            write == 1;
            addr inside {[8'h00:8'h07]};
        }) else `uvm_fatal(get_type_name(), "Randomize failed in apb_write_seq (allow_illegal_addr=0)")
        end

        finish_item(tr);

        `uvm_info(get_type_name(),
                $sformatf("WRITE issued: addr=0x%0h wdata=0x%0h",
                            tr.addr, tr.wdata),
                UVM_MEDIUM)
    end

    `uvm_info(get_type_name(), "Finish apb_write_seq", UVM_LOW)
endtask

`endif
