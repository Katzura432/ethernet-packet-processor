# Verification Results

## Simulation status

**PASS** — Vivado XSim 2026.1 completed the directed RTL simulation successfully on October 8, 2026.

![XSim GUI showing the completed passing simulation](assets/xsim-pass.png)

The captured simulator window shows the completed run at 1255 ns, the two forwarded frames, and `PASS: all filtering checks completed`.

## Test coverage

| Ethernet frame | Expected behavior | Observed behavior |
| --- | --- | --- |
| Local-unicast IPv4 | Forward | Forwarded |
| Broadcast ARP | Forward | Forwarded |
| Local-unicast VLAN 100 ARP | Forward | Forwarded |
| Other-destination IPv4 | Drop | Dropped |
| Local-unicast IPv6 | Drop | Dropped |

## Checked results

| Measurement | Expected | Observed |
| --- | ---: | ---: |
| Accepted frames | 3 | 3 |
| Dropped frames | 2 | 2 |
| Forwarded frames | 3 | 3 |
| Forwarded bytes | 58 | 58 |

## XSim output

```text
Forwarded frame with 18 bytes
Forwarded frame with 36 bytes
Forwarded frame with 58 bytes
PASS: all filtering checks completed
```

## Reproduce

From the repository root, run:

```powershell
& 'E:\Vivado\2026.1\Vivado\bin\vivado.bat' -mode batch -source scripts\run_sim.tcl
```
