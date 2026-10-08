// SPDX-License-Identifier: MIT
// L2 admission control followed by IPv4 5-tuple metadata extraction.
module eth_ingress_processor #(parameter logic [47:0] LOCAL_MAC = 48'h02_00_00_00_00_01) (
    input logic clk, rst, s_valid, s_last, m_ready, input logic [7:0] s_data,
    output logic s_ready, m_valid, m_last, output logic [7:0] m_data,
    output logic [31:0] accepted_frames, dropped_frames, ipv4_frames, tcp_frames, udp_frames,
    output logic meta_valid, meta_vlan_valid, output logic [11:0] meta_vlan_id,
    output logic [31:0] meta_src_ip, meta_dst_ip, output logic [15:0] meta_src_port, meta_dst_port,
    output logic [7:0] meta_protocol
);
    logic f_valid, f_ready, f_last; logic [7:0] f_data;
    eth_packet_filter #(.LOCAL_MAC(LOCAL_MAC)) l2_filter (.clk,.rst,.s_valid,.s_ready,.s_data,.s_last,.m_valid(f_valid),.m_ready(f_ready),.m_data(f_data),.m_last(f_last),.accepted_frames,.dropped_frames);
    ipv4_metadata_parser parser (.clk,.rst,.s_valid(f_valid),.s_ready(f_ready),.s_data(f_data),.s_last(f_last),.m_valid,.m_ready,.m_data,.m_last,.meta_valid,.meta_vlan_valid,.meta_vlan_id,.meta_src_ip,.meta_dst_ip,.meta_src_port,.meta_dst_port,.meta_protocol,.ipv4_frames,.tcp_frames,.udp_frames);
endmodule
