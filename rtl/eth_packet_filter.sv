// SPDX-License-Identifier: MIT
// Byte-stream Ethernet ingress filter with optional single-tag VLAN support.
module eth_packet_filter #(
    parameter logic [47:0] LOCAL_MAC       = 48'h02_00_00_00_00_01,
    parameter logic [15:0] ALLOWED_ETYPE_0 = 16'h0800,
    parameter logic [15:0] ALLOWED_ETYPE_1 = 16'h0806,
    parameter bit          ALLOW_VLAN      = 1'b1
) (
    input logic clk, rst, s_valid, s_last, m_ready,
    input logic [7:0] s_data,
    output logic s_ready, m_valid, m_last,
    output logic [7:0] m_data,
    output logic [31:0] accepted_frames, dropped_frames
);
    typedef enum logic [1:0] {RX_L2, EMIT_L2, FORWARD, DISCARD} state_t;
    state_t state;
    logic [7:0] header [0:17];
    logic [4:0] header_count, emit_count, header_length;
    logic header_last, vlan_frame;

    function automatic logic accepted_type(input logic [15:0] etype);
        accepted_type = (etype == ALLOWED_ETYPE_0) || (etype == ALLOWED_ETYPE_1);
    endfunction

    function automatic logic local_or_broadcast(input logic [47:0] mac);
        local_or_broadcast = (mac == LOCAL_MAC) || (mac == 48'hFF_FF_FF_FF_FF_FF);
    endfunction

    always_comb begin
        s_ready = 1'b0; m_valid = 1'b0; m_data = '0; m_last = 1'b0;
        case (state)
            RX_L2: s_ready = 1'b1;
            EMIT_L2: begin
                m_valid = 1'b1;
                m_data = header[emit_count];
                m_last = (emit_count == header_length - 1'b1) && header_last;
            end
            FORWARD: begin
                s_ready = m_ready; m_valid = s_valid; m_data = s_data; m_last = s_last;
            end
            DISCARD: s_ready = 1'b1;
            default: ;
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= RX_L2; header_count <= '0; emit_count <= '0; header_length <= '0;
            header_last <= 1'b0; vlan_frame <= 1'b0; accepted_frames <= '0; dropped_frames <= '0;
        end else case (state)
            RX_L2: if (s_valid && s_ready) begin
                header[header_count] <= s_data;
                if (s_last && ((!vlan_frame && header_count != 5'd13) ||
                               (vlan_frame && header_count != 5'd17))) begin
                    dropped_frames <= dropped_frames + 1'b1;
                    header_count <= '0; vlan_frame <= 1'b0;
                end else if (header_count == 5'd13) begin
                    if (ALLOW_VLAN && (({header[12], s_data} == 16'h8100) || ({header[12], s_data} == 16'h88A8))) begin
                        vlan_frame <= 1'b1; header_count <= 5'd14;
                    end else begin
                        header_count <= '0;
                        if (local_or_broadcast({header[0],header[1],header[2],header[3],header[4],header[5]}) && accepted_type({header[12],s_data})) begin
                            accepted_frames <= accepted_frames + 1'b1;
                            header_length <= 5'd14; header_last <= s_last; emit_count <= '0; state <= EMIT_L2;
                        end else begin
                            dropped_frames <= dropped_frames + 1'b1; state <= s_last ? RX_L2 : DISCARD;
                        end
                    end
                end else if (vlan_frame && header_count == 5'd17) begin
                    header_count <= '0; vlan_frame <= 1'b0;
                    if (local_or_broadcast({header[0],header[1],header[2],header[3],header[4],header[5]}) && accepted_type({header[16],s_data})) begin
                        accepted_frames <= accepted_frames + 1'b1;
                        header_length <= 5'd18; header_last <= s_last; emit_count <= '0; state <= EMIT_L2;
                    end else begin
                        dropped_frames <= dropped_frames + 1'b1; state <= s_last ? RX_L2 : DISCARD;
                    end
                end else header_count <= header_count + 1'b1;
            end
            EMIT_L2: if (m_valid && m_ready) begin
                if (emit_count == header_length - 1'b1) begin
                    emit_count <= '0; state <= header_last ? RX_L2 : FORWARD;
                end else emit_count <= emit_count + 1'b1;
            end
            FORWARD: if (s_valid && s_ready && s_last) state <= RX_L2;
            DISCARD: if (s_valid && s_ready && s_last) state <= RX_L2;
            default: state <= RX_L2;
        endcase
    end
endmodule
