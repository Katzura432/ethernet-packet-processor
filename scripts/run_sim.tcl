set root [file normalize [file join [file dirname [info script]] ..]]
# Compile directly with XSim. This avoids a board/part dependency for RTL simulation.
exec xvlog --sv [file join $root rtl eth_packet_filter.sv]
exec xvlog --sv [file join $root rtl ipv4_metadata_parser.sv]
exec xvlog --sv [file join $root rtl eth_ingress_processor.sv]
exec xvlog --sv [file join $root sim tb_eth_packet_filter.sv]
exec xelab tb_eth_packet_filter -s tb_eth_packet_filter_regression
exec xsim tb_eth_packet_filter_regression -runall
