//------------------------------------------------------------------------------
// File    : apb_seq_item.sv
// Author  : ken, Lu Wei-Ru
// Created : 2026-01-14
// Brief   : APB transaction item used in the UVM testbench. This sequence item
//           represents a single APB transfer (read or write), encapsulating
//           address, data, control, and response information. It is generated
//           by sequences, driven by the APB driver, observed by the monitor,
//           and compared by the reference model and scoreboard.
//------------------------------------------------------------------------------

`ifndef _APB_SEQ_ITEM_SV
`define _APB_SEQ_ITEM_SV

class apb_seq_item extends uvm_sequence_item;
  `uvm_object_utils(apb_seq_item)

  // -------------------------
  // Request fields (from sequence -> driver)
  // -------------------------
  rand logic [`ADDR_WIDTH-1:0] addr;
  rand bit                    write;  // 1=write, 0=read
  rand logic [`DATA_WIDTH-1:0] wdata;

  // Optional: constrain to any range you want in specific sequences
  // constraint c_default { }

  // -------------------------
  // Response / observed fields (filled by driver/monitor)
  // -------------------------
  logic [`DATA_WIDTH-1:0] rdata;
  bit                    slverr;

  // Helpful debug info
  int unsigned           wait_cycles;

	//--------------------------------------------------------------------
	//	Methods
	//--------------------------------------------------------------------
    extern function new(string name="apb_seq_item");
    extern function string convert2string();


endclass

// Function: new
// Definition: class constructor
function apb_seq_item::new(string name="apb_seq_item");
    super.new(name);
    rdata       = '0;
    slverr      = 0;
    wait_cycles = 0;
endfunction

// Function: convert2string
// Definition: this function is used to show apb transaction.
function string apb_seq_item::convert2string();
    return $sformatf("APB item: %s addr=0x%0h wdata=0x%0h rdata=0x%0h slverr=%0b wait=%0d",
                        (write ? "WRITE" : "READ"),
                        addr, wdata, rdata, slverr, wait_cycles);
endfunction

`endif
