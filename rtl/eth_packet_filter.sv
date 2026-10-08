// SPDX-License-Identifier: MIT
// Byte-stream Ethernet ingress filter.
// Input and output use one byte per cycle with AXI-stream-like valid/ready/last.
module eth_packet_filter #(
    parameter logic [47:0] LOCAL_MAC       = 48'h02_00_00_00_00_01,
    parameter logic [15:0] ALLOWED_ETYPE_0 = 16'h0800, // IPv4
    parameter logic [15:0] ALLOWED_ETYPE_1 = 16'h0806  // ARP
) (
    input  logic        clk,
    input  logic        rst,
    input  logic        s_valid,
    output logic        s_ready,
    input  logic [7:0]  s_data,
    input  logic        s_last,
    output logic        m_valid,
    input  logic        m_ready,
    output logic [7:0]  m_data,
    output logic        m_last,
    output logic [31:0] accepted_frames,
    output logic [31:0] dropped_frames
);
    typedef enum logic [1:0] {RX_HEADER, EMIT_HEADER, FORWARD, DISCARD} state_t;
    state_t state;
    logic [7:0] header [0:13];
    logic [3:0] header_count;
    logic [3:0] emit_count;
    logic       header_last;

    always_comb begin
        s_ready = 1'b0;
        m_valid = 1'b0;
        m_data  = 8'h00;
        m_last  = 1'b0;
        case (state)
            RX_HEADER: begin
                s_ready = 1'b1;
            end
            EMIT_HEADER: begin
                m_valid = 1'b1;
                m_data  = header[emit_count];
                m_last  = (emit_count == 4'd13) && header_last;
            end
            FORWARD: begin
                s_ready = m_ready;
                m_valid = s_valid;
                m_data  = s_data;
                m_last  = s_last;
            end
            DISCARD: begin
                s_ready = 1'b1;
            end
            default: begin end
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state           <= RX_HEADER;
            header_count    <= '0;
            emit_count      <= '0;
            header_last     <= 1'b0;
            accepted_frames <= '0;
            dropped_frames  <= '0;
        end else begin
            case (state)
                RX_HEADER: if (s_valid && s_ready) begin
                    header[header_count] <= s_data;
                    if (s_last && header_count != 4'd13) begin
                        // Ethernet headers are always 14 bytes; discard runt frames.
                        dropped_frames <= dropped_frames + 1'b1;
                        header_count   <= '0;
                    end else if (header_count == 4'd13) begin
                        // Bytes 0..5 are destination MAC and bytes 12..13 Ethertype.
                        header_count <= '0;
                        if ((({header[0], header[1], header[2], header[3], header[4], header[5]} == LOCAL_MAC) ||
                             ({header[0], header[1], header[2], header[3], header[4], header[5]} == 48'hFF_FF_FF_FF_FF_FF)) &&
                            (({header[12], s_data} == ALLOWED_ETYPE_0) || ({header[12], s_data} == ALLOWED_ETYPE_1))) begin
                            accepted_frames <= accepted_frames + 1'b1;
                            emit_count <= '0;
                            header_last <= s_last;
                            state <= EMIT_HEADER;
                        end else begin
                            dropped_frames <= dropped_frames + 1'b1;
                            state <= s_last ? RX_HEADER : DISCARD;
                        end
                    end else begin
                        header_count <= header_count + 1'b1;
                    end
                end
                EMIT_HEADER: if (m_valid && m_ready) begin
                    if (emit_count == 4'd13) begin
                        emit_count <= '0;
                        state <= header_last ? RX_HEADER : FORWARD;
                    end else begin
                        emit_count <= emit_count + 1'b1;
                    end
                end
                FORWARD: if (s_valid && s_ready && s_last) begin
                    state <= RX_HEADER;
                end
                DISCARD: if (s_valid && s_ready && s_last) begin
                    state <= RX_HEADER;
                end
                default: state <= RX_HEADER;
            endcase
        end
    end
endmodule
