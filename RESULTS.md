# Verification Results

## Simulation status

**PASS** - Vivado XSim 2026.1 completed the expanded directed RTL regression successfully on October 8, 2026.

The expanded captured run completes at 2975 ns with five accepted frames, five dropped frames, 98 forwarded bytes, and `PASS: all filtering checks completed`.

![Expanded XSim GUI showing all test cases and final counters](assets/xsim-expanded-regression.png)

![Expanded XSim console showing the completed passing result](assets/xsim-expanded-console.png)

## Test coverage

| Ethernet frame | Expected behavior | Observed behavior |
| --- | --- | --- |
| Local-unicast IPv4 | Forward | Forwarded |
| Broadcast ARP | Forward | Forwarded |
| Local-unicast VLAN 100 ARP | Forward | Forwarded |
| Broadcast IPv4 | Forward | Forwarded |
| Local-unicast service-VLAN IPv4 | Forward | Forwarded |
| Other-destination IPv4 | Drop | Dropped |
| Local-unicast IPv6 | Drop | Dropped |
| Other-destination VLAN ARP | Drop | Dropped |
| Local-unicast VLAN IPv6 | Drop | Dropped |
| Ethernet runt frame | Drop | Dropped |

## Checked results

| Measurement | Expected | Observed |
| --- | ---: | ---: |
| Accepted frames | 5 | 5 |
| Dropped frames | 5 | 5 |
| Forwarded frames | 5 | 5 |
| Forwarded bytes | 98 | 98 |

## XSim output

```text
Forwarded frame with 18 bytes
Forwarded frame with 36 bytes
Forwarded frame with 58 bytes
Forwarded frame with 76 bytes
Forwarded frame with 98 bytes
PASS: all filtering checks completed
```

## Reproduce

From the repository root, run:

```powershell
& 'E:\Vivado\2026.1\Vivado\bin\vivado.bat' -mode batch -source scripts\run_sim.tcl
```
