// SPDX-License-Identifier: MIT
// Pass-through parser that emits IPv4 5-tuple metadata for accepted frames.
module ipv4_metadata_parser (
    input logic clk, rst, s_valid, s_last, m_ready,
    input logic [7:0] s_data,
    output logic s_ready, m_valid, m_last,
    output logic [7:0] m_data,
    output logic meta_valid, meta_vlan_valid,
    output logic [11:0] meta_vlan_id,
    output logic [31:0] meta_src_ip, meta_dst_ip,
    output logic [15:0] meta_src_port, meta_dst_port,
    output logic [7:0] meta_protocol,
    output logic [31:0] ipv4_frames, tcp_frames, udp_frames
);
    logic [15:0] byte_index, l3_start, l4_start;
    logic [7:0] etype_hi, ip_ihl;
    logic vlan_frame, ipv4_frame;
    assign s_ready = m_ready;
    assign m_valid = s_valid;
    assign m_data = s_data;
    assign m_last = s_last;

    always_ff @(posedge clk) begin
        if (rst) begin
            byte_index <= '0; l3_start <= '0; l4_start <= '0; etype_hi <= '0; ip_ihl <= '0;
            vlan_frame <= 1'b0; ipv4_frame <= 1'b0; meta_valid <= 1'b0; meta_vlan_valid <= 1'b0;
            meta_vlan_id <= '0; meta_src_ip <= '0; meta_dst_ip <= '0; meta_src_port <= '0; meta_dst_port <= '0; meta_protocol <= '0;
            ipv4_frames <= '0; tcp_frames <= '0; udp_frames <= '0;
        end else begin
            meta_valid <= 1'b0;
            if (s_valid && s_ready) begin
                if (byte_index == 16'd12 || byte_index == 16'd16) etype_hi <= s_data;
                if (byte_index == 16'd13) begin
                    vlan_frame <= ({etype_hi,s_data} == 16'h8100) || ({etype_hi,s_data} == 16'h88A8);
                    meta_vlan_valid <= ({etype_hi,s_data} == 16'h8100) || ({etype_hi,s_data} == 16'h88A8);
                    if ({etype_hi,s_data} == 16'h0800) begin ipv4_frame <= 1'b1; l3_start <= 16'd14; ipv4_frames <= ipv4_frames + 1'b1; end
                end
                if (vlan_frame && byte_index == 16'd14) meta_vlan_id[11:8] <= s_data[3:0];
                if (vlan_frame && byte_index == 16'd15) meta_vlan_id[7:0] <= s_data;
                if (vlan_frame && byte_index == 16'd17 && {etype_hi,s_data} == 16'h0800) begin
                    ipv4_frame <= 1'b1; l3_start <= 16'd18; ipv4_frames <= ipv4_frames + 1'b1;
                end
                if (ipv4_frame) begin
                    if (byte_index == l3_start) begin
                        ip_ihl <= {s_data[3:0],2'b00};
                        if (s_data[7:4] != 4'd4 || s_data[3:0] < 4'd5) ipv4_frame <= 1'b0;
                    end
                    if (byte_index == l3_start + 16'd9) begin
                        meta_protocol <= s_data;
                        if (s_data == 8'd6) tcp_frames <= tcp_frames + 1'b1;
                        if (s_data == 8'd17) udp_frames <= udp_frames + 1'b1;
                    end
                    if (byte_index == l3_start+12) meta_src_ip[31:24] <= s_data;
                    if (byte_index == l3_start+13) meta_src_ip[23:16] <= s_data;
                    if (byte_index == l3_start+14) meta_src_ip[15:8] <= s_data;
                    if (byte_index == l3_start+15) meta_src_ip[7:0] <= s_data;
                    if (byte_index == l3_start+16) meta_dst_ip[31:24] <= s_data;
                    if (byte_index == l3_start+17) meta_dst_ip[23:16] <= s_data;
                    if (byte_index == l3_start+18) meta_dst_ip[15:8] <= s_data;
                    if (byte_index == l3_start+19) begin
                        meta_dst_ip[7:0] <= s_data; l4_start <= l3_start + ip_ihl;
                        if (meta_protocol != 8'd6 && meta_protocol != 8'd17) meta_valid <= 1'b1;
                    end
                    if (byte_index == l4_start) meta_src_port[15:8] <= s_data;
                    if (byte_index == l4_start+1) meta_src_port[7:0] <= s_data;
                    if (byte_index == l4_start+2) meta_dst_port[15:8] <= s_data;
                    if (byte_index == l4_start+3) begin meta_dst_port[7:0] <= s_data; meta_valid <= 1'b1; end
                end
                if (s_last) begin byte_index <= '0; vlan_frame <= 1'b0; ipv4_frame <= 1'b0; end
                else byte_index <= byte_index + 1'b1;
            end
        end
    end
endmodule
