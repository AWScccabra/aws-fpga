// =============================================================================
// Copyright 2016 Amazon.com, Inc. or its affiliates.
// All Rights Reserved Worldwide.
// Amazon Confidential information
// Restricted NDA Material
// =============================================================================

module test_peek_poke();

`define CFG_REG           64'h00
`define CNTL_REG          64'h08
`define NUM_INST          64'h10
`define MAX_RD_REQ        64'h14

`define WR_INSTR_INDEX    64'h1c
`define WR_ADDR_LOW       64'h20
`define WR_ADDR_HIGH      64'h24
`define WR_DATA           64'h28
`define WR_LEN            64'h2c

`define RD_INSTR_INDEX    64'h3c
`define RD_ADDR_LOW       64'h40
`define RD_ADDR_HIGH      64'h44
`define RD_DATA           64'h48
`define RD_LEN            64'h4c

`define RD_ERR            64'hb0
`define RD_ERR_ADDR_LOW   64'hb4
`define RD_ERR_ADDR_HIGH  64'hb8
`define RD_ERR_INDEX      64'hbc

`define WR_CYCLE_CNT_LOW  64'hf0
`define WR_CYCLE_CNT_HIGH 64'hf4
`define RD_CYCLE_CNT_LOW  64'hf8
`define RD_CYCLE_CNT_HIGH 64'hfc

`define WR_START_BIT   32'h00000001
`define RD_START_BIT   32'h00000002

   import tb_type_defines_pkg::*;

   logic [63:0]  pcim_addr;
   logic [31:0]  pcim_data;

   logic [31:0]  read_data;

   logic [63:0]  cycle_count;
   logic [63:0]  error_addr;

   logic [3:0]   error_index;

   int           timeout_count;

   int           error_count;
   int           fail;

   initial begin
      error_count = 0;
      fail = 0;

      pcim_addr = 64'h0000_0000_1234_0000;
      pcim_data = 32'h6c93_af50;

      tb.power_up();

      tb.nsec_delay(500);
      tb.poke_stat(.addr(8'h0c), .ddr_idx(0), .data(32'h0000_0000));
      tb.poke_stat(.addr(8'h0c), .ddr_idx(1), .data(32'h0000_0000));
      tb.poke_stat(.addr(8'h0c), .ddr_idx(2), .data(32'h0000_0000));

      $display("[%t] : Programming cl_tst registers for PCIe", $realtime);

      // Enable Incr ID mode, Sync mode, and Read Compare
      tb.poke(.addr(`CFG_REG), .data(32'h0100_0018), .intf(AxiPort::PORT_OCL));

      // Set the max number of read requests
      tb.poke(.addr(`MAX_RD_REQ), .data(32'h0000_000f), .intf(AxiPort::PORT_OCL));

      tb.poke(.addr(`WR_INSTR_INDEX), .data(32'h0000_0000), .intf(AxiPort::PORT_OCL));   // write index
      tb.poke(.addr(`WR_ADDR_LOW), .data(pcim_addr[31:0]), .intf(AxiPort::PORT_OCL));    // write address low
      tb.poke(.addr(`WR_ADDR_HIGH), .data(pcim_addr[63:32]), .intf(AxiPort::PORT_OCL));  // write address high
      tb.poke(.addr(`WR_DATA), .data(pcim_data[31:0]), .intf(AxiPort::PORT_OCL));        // write data
      tb.poke(.addr(`WR_LEN), .data(32'h0000_0001), .intf(AxiPort::PORT_OCL));           // write 128 bytes

      tb.poke(.addr(`RD_INSTR_INDEX), .data(32'h0000_0000), .intf(AxiPort::PORT_OCL));   // read index
      tb.poke(.addr(`RD_ADDR_LOW), .data(pcim_addr[31:0]), .intf(AxiPort::PORT_OCL));    // read address low
      tb.poke(.addr(`RD_ADDR_HIGH), .data(pcim_addr[63:32]), .intf(AxiPort::PORT_OCL));  // read address high
      tb.poke(.addr(`RD_DATA), .data(pcim_data[31:0]), .intf(AxiPort::PORT_OCL));        // read data
      tb.poke(.addr(`RD_LEN), .data(32'h0000_0001), .intf(AxiPort::PORT_OCL));           // read 128 bytes

      // Number of instructions, zero based ([31:16] for read, [15:0] for write)
      tb.poke(.addr(`NUM_INST), .data(32'h0000_0000), .intf(AxiPort::PORT_OCL));

      // Start writes and reads
      tb.poke(.addr(`CNTL_REG), .data(`WR_START_BIT | `RD_START_BIT), .intf(AxiPort::PORT_OCL));

      $display("[%t] : Waiting for PCIe write and read activity to complete", $realtime);
      #500ns;

      timeout_count = 0;
      do begin
         tb.peek(.addr(`CNTL_REG), .data(read_data), .intf(AxiPort::PORT_OCL));
         timeout_count++;
      end while ((read_data[2:0] !== 3'b000) && (timeout_count < 100));

      if ((timeout_count == 100) && (read_data[2:0] !== 3'b000)) begin
         $display("[%t] : *** ERROR *** Timeout waiting for writes and reads to complete.", $realtime);
         error_count++;
      end else begin
         // Stop reads and writes ([1] for reads, [0] for writes)
         tb.poke(.addr(`CNTL_REG), .data(32'h0000_0000), .intf(AxiPort::PORT_OCL));

         $display("[%t] : Checking some register values", $realtime);

         cycle_count = 64'h0;
         // Check that the write timer value is non-zero
         tb.peek(.addr(`WR_CYCLE_CNT_LOW), .data(read_data), .intf(AxiPort::PORT_OCL));
         cycle_count[31:0] = read_data;
         tb.peek(.addr(`WR_CYCLE_CNT_HIGH), .data(read_data), .intf(AxiPort::PORT_OCL));
         cycle_count[63:32] = read_data;
         if (cycle_count == 64'h0) begin
            $display("[%t] : *** ERROR *** Write Timer value was 0x0 at end of test.", $realtime);
            error_count++;
         end

         cycle_count = 64'h0;
         // Check that the read timer value is non-zero
         tb.peek(.addr(`RD_CYCLE_CNT_LOW), .data(read_data), .intf(AxiPort::PORT_OCL));
         cycle_count[31:0] = read_data;
         tb.peek(.addr(`RD_CYCLE_CNT_HIGH), .data(read_data), .intf(AxiPort::PORT_OCL));
         cycle_count[63:32] = read_data;
         if (cycle_count == 64'h0) begin
            $display("[%t] : *** ERROR *** Read Timer value was 0x0 at end of test.", $realtime);
            error_count++;
         end

         $display("[%t] : Checking for read compare errors", $realtime);

         // Check for compare error
         tb.peek(.addr(`RD_ERR), .data(read_data), .intf(AxiPort::PORT_OCL));
         if (read_data != 32'h0000_0000) begin
            tb.peek(.addr(`RD_ERR_ADDR_LOW), .data(read_data), .intf(AxiPort::PORT_OCL));
            error_addr[31:0] = read_data;
            tb.peek(.addr(`RD_ERR_ADDR_HIGH), .data(read_data), .intf(AxiPort::PORT_OCL));
            error_addr[63:32] = read_data;
            tb.peek(.addr(`RD_ERR_INDEX), .data(read_data), .intf(AxiPort::PORT_OCL));
            error_index = read_data[3:0];
            $display("[%t] : *** ERROR *** Read compare error from address 0x%016x, index 0x%1x", $realtime, error_addr, error_index);
            error_count++;
         end
      end

      tb.power_down();

      //---------------------------
      // Report pass/fail status
      //---------------------------
      $display("[%t] : Checking total error count...", $realtime);
      if (error_count > 0) begin
         fail = 1;
      end
      $display("[%t] : Detected %3d errors during this test", $realtime, error_count);

      if (fail) begin
         $display("[%t] : *** TEST FAILED ***", $realtime);
      end else begin
         $display("[%t] : *** TEST PASSED ***", $realtime);
      end

      $finish;
   end

endmodule // test_peek_poke
