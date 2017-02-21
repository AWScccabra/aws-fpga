// =============================================================================
// Copyright 2016 Amazon.com, Inc. or its affiliates.
// All Rights Reserved Worldwide.
// =============================================================================

module axil_bfm 
   (
    input               axil_clk,
    input               axil_rst_n,
    output logic        axil_awvalid,
    output logic [31:0] axil_awaddr, 
    input               axil_awready,

    //Write data
    output logic        axil_wvalid,
    output logic [31:0] axil_wdata,
    output logic [3:0]  axil_wstrb,
    input               axil_wready,
    
    //Write response
    input               axil_bvalid,
    input [1:0]         axil_bresp,
    output logic        axil_bready,
    
    //Read address
    output logic        axil_arvalid,
    output logic [31:0] axil_araddr,
    input               axil_arready,
    
    //Read data/response
    input               axil_rvalid,
    input [31:0]        axil_rdata,
    input [1:0]         axil_rresp,
    
    output logic        axil_rready

   );

`include "axi_bfm_defines.svh"
   
   AXI_Command axil_wr_cmds[$];
   AXI_Data    axil_wr_data[$];
   AXI_Command axil_rd_cmds[$];
   AXI_Data    axil_rd_data[$];
   AXI_Command axil_b_resps[$];
   
   bit           debug;

   initial begin
      debug = 1'b0;
/* TODO: Use the code below once plusarg support is enabled
      if ($test$plusargs("DEBUG")) begin
         debug = 1'b1;
      end else begin
         debug = 1'b0;
      end
*/
   end


   //=================================================
   //
   // AXI-L Interface
   //
   //=================================================

   //
   // Address Write Channel
   //

   always @(posedge axil_clk) begin
      if (axil_wr_cmds.size() != 0) begin

         axil_awaddr  <= axil_wr_cmds[0].addr[31:0];
         
         axil_awvalid <= !axil_awvalid ? 1'b1 :
                               !axil_awready ? 1'b1 : 1'b0;
         
         if (axil_awready && axil_awvalid) begin
            if (debug) begin
               $display("[%t] : DEBUG popping cmd fifo - %d", $realtime, axil_wr_cmds.size());
            end
            axil_wr_cmds.pop_front();
         end

      end
      else
         axil_awvalid <= 1'b0;
   end


   //
   // write Data Channel
   //

   always @(posedge axil_clk) begin

      if (axil_wr_data.size() != 0) begin

         axil_wdata <= axil_wr_data[0].data[31:0];
         axil_wstrb <= axil_wr_data[0].strb[3:0];
         
         axil_wvalid <= !axil_wvalid ? 1'b1 :
                              !axil_wready ? 1'b1 : 1'b0;
         
         if (axil_wready && axil_wvalid) begin
            if (debug) begin
               $display("[%t] : DEBUG popping wr data fifo - %d", $realtime, axil_wr_data.size());
            end
            axil_wr_data.pop_front();
         end
         
      end
      else
         axil_wvalid <= 1'b0;
   end

   //
   // B Response Channel
   //
   always @(posedge axil_clk) begin
      axil_bready <= 1'b1;
   end

   always @(posedge axil_clk) begin
      AXI_Command resp;

      if (axil_bvalid & axil_bready) begin
         resp.resp     = axil_bresp[0];

         axil_b_resps.push_back(resp);
      end

   end


   //
   // Address Read Channel
   //

   always @(posedge axil_clk) begin
      if (axil_rd_cmds.size() != 0) begin

         axil_araddr  <= axil_rd_cmds[0].addr[31:0];
         
         axil_arvalid <= !axil_arvalid ? 1'b1 :
                               !axil_arready ? 1'b1 : 1'b0;
         
         if (axil_arready && axil_arvalid) begin
            if (debug) begin
               $display("[%t] : DEBUG popping cmd fifo - %d", $realtime, axil_rd_cmds.size());
            end
            axil_rd_cmds.pop_front();
         end

      end
      else
         axil_arvalid <= 1'b0;
   end

   //
   // Read Data Channel
   //
   always @(posedge axil_clk) begin
      axil_rready <= (axil_rd_data.size() < 16) ? 1'b1 : 1'b0;
   end

   always @(posedge axil_clk) begin
      AXI_Data data;

      if (axil_rvalid & axil_rready) begin
         data.data     = axil_rdata[31:0];

         if (debug) begin
            for (int i=0; i<16; i++) begin
               $display("[%t] - DEBUG read data [%2d]: 0x%08h", $realtime, i, axil_rdata[(i*32)+:32]);
            end
         end
         
         axil_rd_data.push_back(data);
      end

   end


   
   task poke(input logic [31:0] addr, logic [31:0] data);
      AXI_Command axi_cmd;
      AXI_Data    axi_data;

      logic [1:0] resp;
      
      axi_cmd.addr[31:0] = addr;
      axi_cmd.len  = 0;

      axil_wr_cmds.push_back(axi_cmd);

      axi_data.data[31:0] = data;
      axi_data.strb = 4'h0f;
      axi_data.last = 1'b1;

      #20ns axil_wr_data.push_back(axi_data);
      
      while (axil_b_resps.size() == 0)
        #20ns;
      
      resp = axil_b_resps[0].resp;
      axil_b_resps.pop_front();
      
   endtask // poke

   task peek(input logic [31:0] addr, output logic [31:0] data);
      AXI_Command axi_cmd;
      
      axi_cmd.addr[31:0] = addr;
      axi_cmd.len  = 0;

      axil_rd_cmds.push_back(axi_cmd);

      while (axil_rd_data.size() == 0)
        #20ns;
      
      data = axil_rd_data[0].data[31:0];
      axil_rd_data.pop_front();
      
   endtask // peek


endmodule // axil_bfm