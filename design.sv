//------------------------------------------------------------------------------
// File    : design.sv
// Author  : ken, Lu Wei-Ru
// Created : 2026-01-14
// Brief   : Simple APB slave DUT with an 8x8 register file (addresses 0x00~0x07).
//           Latches request information in SETUP (PSEL=1, PENABLE=0), then
//           completes the transfer in ACCESS (PSEL=1, PENABLE=1). Supports
//           programmable wait states via parameter N: when N=1, responds
//           immediately; when N>=2, holds PREADY low for (N-1) ACCESS cycles and
//           asserts PREADY on the Nth cycle. For writes to illegal addresses
//           (>0x07), asserts PSLVERR; reads return the stored byte from mem.
//------------------------------------------------------------------------------

module apb_slave #(
  parameter int unsigned N = 4   // number of ACCESS cycles before ready (>=1)
) (
    input  logic        PCLK,     // Peripheral Clock
    input  logic        PRESETn,  // Active Low Reset
    input  logic        PSEL,     // Select slave
    input  logic        PENABLE,  // Enable signal
    input  logic        PWRITE,   // Write 1 / read 0 into/from mem
    input  logic [7:0]  PADDR,    // Address of Slave
    input  logic [7:0]  PWDATA,   // write data
    output logic [7:0]  PRDATA,   // Read data
    output logic        PREADY,   // 1-> slave ready back to idle
    output logic        PSLVERR   // Error
    // later project
    // input  logic [2:0]  PPROT,   // APB4
    // input  logic        PSTRB,   // APB4 (1-bit for 8-bit PWDATA)

);

  // 8x8 memory
  logic [7:0] mem [0:7];  // or logic [63:0] mem_flat;

  // Latched request from SETUP phase
  logic [7:0] addr_q;
  logic       write_q;  // control write data
  logic [7:0] wdata_q;

  // Wait counter for ACCESS phase
  int unsigned wait_cnt;

  // APB phase detect
  wire setup_phase  = PSEL && !PENABLE;
  wire access_phase = PSEL &&  PENABLE;

  // helper
  function automatic bit is_invalid_addr(input logic [7:0] a);
     return (a > 8'h07); // legial domain is 0x00~0x07
  endfunction

  always_ff @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      PREADY  <= 1'b0;
      PSLVERR <= 1'b0;
      PRDATA  <= 8'h00;

      addr_q  <= 8'h00;
      write_q <= 1'b0;
      wdata_q <= 8'h00;

      wait_cnt <= 0;

      for (int i = 0; i < 8; i++) begin
        mem[i] <= 8'h00;
      end
    end else begin
      // defaults each cycle
      PREADY  <= 1'b0;
      PSLVERR <= 1'b0;

      // SETUP: latch request (standard APB behavior)
      if (setup_phase) begin
        addr_q   <= PADDR;
        write_q  <= PWRITE;
        wdata_q  <= PWDATA;
        wait_cnt <= 0;      // start wait for this transaction
      end

      // ACCESS: wait-state handling + complete transfer
      if (access_phase) begin
        // Treat N=1 as "no wait": ready immediately
        if (N <= 1) begin
          PREADY <= 1'b1;

          if (write_q) begin
            if (is_invalid_addr(addr_q)) begin
              PSLVERR <= 1'b1;
            end else begin
              mem[addr_q[2:0]] <= wdata_q;
            end
          end else begin
            PRDATA <= mem[addr_q[2:0]];
          end

        end else begin
          // N>=2: hold PREADY low for N-1 ACCESS cycles, assert on Nth
          if (wait_cnt < (N-1)) begin
            wait_cnt <= wait_cnt + 1;
            PREADY   <= 1'b0;
          end else begin
            PREADY   <= 1'b1;

            if (write_q) begin
              if (is_invalid_addr(addr_q)) begin
                PSLVERR <= 1'b1;
              end else begin
                mem[addr_q[2:0]] <= wdata_q;
              end
            end else begin
              PRDATA <= mem[addr_q[2:0]];
            end
          end
        end
      end
    end
  end

endmodule
