# Project handoff

Project location: `C:\Users\Manish\ethernet-packet-processor`

## Current state

- A SystemVerilog Ethernet ingress packet filter is implemented in `rtl/eth_packet_filter.sv`.
- It accepts local-unicast/broadcast IPv4 and ARP frames, and drops other frames.
- The Vivado/XSim testbench in `sim/tb_eth_packet_filter.sv` passes.
- Test command used successfully:

```powershell
& 'E:\Vivado\2026.1\Vivado\bin\vivado.bat' -mode batch -source scripts\run_sim.tcl
```

## Remaining task

Create a GitHub repository named `ethernet-packet-processor`, initialize the local directory as a Git repository if necessary, commit the source (excluding generated XSim/Vivado files via `.gitignore`), add the GitHub remote, and push `main`.

Before publishing, verify GitHub access with:

```powershell
git --version
gh auth status
```
