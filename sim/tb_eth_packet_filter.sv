`timescale 1ns/1ps
module tb_eth_packet_filter;
    logic clk = 0, rst = 1, s_valid, s_ready, s_last, m_valid, m_ready = 1;
    logic [7:0] s_data, m_data;
    logic m_last;
    logic [31:0] accepted_frames, dropped_frames;
    int received_bytes = 0, received_frames = 0;

    eth_packet_filter #(.LOCAL_MAC(48'h02_00_00_00_00_01)) dut (.*);
    always #5 clk = ~clk;
    always @(posedge clk) if (m_valid && m_ready) begin
        received_bytes++;
        if (m_last) begin
            received_frames++;
            $display("Forwarded frame with %0d bytes", received_bytes);
        end
    end

    task automatic send_frame(input logic [47:0] da, input logic [15:0] etype);
        logic [7:0] bytes [0:17];
        int i;
        begin
            {bytes[0],bytes[1],bytes[2],bytes[3],bytes[4],bytes[5]} = da;
            {bytes[6],bytes[7],bytes[8],bytes[9],bytes[10],bytes[11]} = 48'h10_20_30_40_50_60;
            {bytes[12],bytes[13]} = etype;
            bytes[14]=8'hDE; bytes[15]=8'hAD; bytes[16]=8'hBE; bytes[17]=8'hEF;
            for (i=0; i<18; i++) begin
                // Drive before the active edge and retain the item until accepted.
                @(negedge clk); s_valid = 1; s_data = bytes[i]; s_last = (i == 17);
                do @(posedge clk); while (!s_ready);
            end
            @(negedge clk); s_valid = 0; s_last = 0;
        end
    endtask

    task automatic send_vlan_arp(input logic [47:0] da, input logic [11:0] vlan_id);
        logic [7:0] bytes [0:21];
        int i;
        begin
            {bytes[0],bytes[1],bytes[2],bytes[3],bytes[4],bytes[5]} = da;
            {bytes[6],bytes[7],bytes[8],bytes[9],bytes[10],bytes[11]} = 48'h10_20_30_40_50_60;
            bytes[12]=8'h81; bytes[13]=8'h00; bytes[14]={4'h0,vlan_id[11:8]}; bytes[15]=vlan_id[7:0];
            bytes[16]=8'h08; bytes[17]=8'h06; bytes[18]=8'hDE; bytes[19]=8'hAD; bytes[20]=8'hBE; bytes[21]=8'hEF;
            for (i=0; i<22; i++) begin
                @(negedge clk); s_valid = 1; s_data = bytes[i]; s_last = (i == 21);
                do @(posedge clk); while (!s_ready);
            end
            @(negedge clk); s_valid = 0; s_last = 0;
        end
    endtask

    initial begin
        s_valid=0; s_data=0; s_last=0;
        repeat (3) @(posedge clk); rst <= 0;
        send_frame(48'h02_00_00_00_00_01, 16'h0800); // accepted IPv4 unicast
        send_frame(48'hFF_FF_FF_FF_FF_FF, 16'h0806); // accepted broadcast ARP
        send_vlan_arp(48'h02_00_00_00_00_01, 12'd100); // accepted VLAN-tagged ARP
        send_frame(48'h02_00_00_00_00_02, 16'h0800); // reject: other MAC
        send_frame(48'h02_00_00_00_00_01, 16'h86DD); // reject: IPv6 disabled
        repeat (20) @(posedge clk);
        if (accepted_frames != 3 || dropped_frames != 2 || received_bytes != 58 || received_frames != 3) $fatal(1, "Test failed: accepted=%0d dropped=%0d bytes=%0d frames=%0d", accepted_frames, dropped_frames, received_bytes, received_frames);
        $display("PASS: all filtering checks completed");
        $finish;
    end
endmodule
