#!/usr/bin/env python3
"""
Compare normal vs attack scenarios and optionally plot summary.
"""

import sys
import re
import ipaddress
from collections import defaultdict


def parse_log(filename):
    tx_packets = defaultdict(list)
    rx_packets = defaultdict(list)
    delays = []
    rpl_packets = 0
    pending_tx_seqs = []
    inferred_sender_id = None

    with open(filename, 'r') as f:
        for line in f:
            line = line.strip()

            if 'CSV,RX,' in line:
                parts = line.split('CSV,RX,')[1].split(',')
                if len(parts) >= 2:
                    seq = int(parts[1])
                    src_ip = parts[0]
                    try:
                        ip_obj = ipaddress.ip_address(src_ip)
                        node_id = int(ip_obj) & 0xffff
                        rx_packets[node_id].append(seq)
                        if inferred_sender_id is None:
                            inferred_sender_id = node_id
                    except ValueError:
                        pass

            elif 'CSV,RTT,' in line:
                parts = line.split('CSV,RTT,')[1].split(',')
                if len(parts) >= 4:
                    rtt_ticks = int(parts[3])
                    delay_ms = rtt_ticks / 2.0
                    delays.append(delay_ms)

            elif 'TX seq=' in line:
                match = re.search(r'TX seq=(\d+)', line)
                if match:
                    seq = int(match.group(1))
                    node_match = re.search(r'ID:(\d+)', line)
                    if node_match:
                        node_id = int(node_match.group(1))
                        tx_packets[node_id].append(seq)
                    elif inferred_sender_id is not None:
                        tx_packets[inferred_sender_id].append(seq)
                    else:
                        pending_tx_seqs.append(seq)

            if 'RPL:' in line or 'DIO' in line or 'DAO' in line:
                rpl_packets += 1

    if inferred_sender_id is not None and pending_tx_seqs:
        tx_packets[inferred_sender_id].extend(pending_tx_seqs)

    total_tx = sum(len(v) for v in tx_packets.values())
    total_rx = sum(len(v) for v in rx_packets.values())
    pdr = (total_rx / total_tx * 100.0) if total_tx > 0 else 0.0
    avg_delay = sum(delays) / len(delays) if delays else 0.0
    overhead_pct = (rpl_packets / total_tx * 100.0) if total_tx > 0 else 0.0

    return {
        "tx": total_tx,
        "rx": total_rx,
        "pdr": pdr,
        "avg_delay": avg_delay,
        "rpl_packets": rpl_packets,
        "overhead_pct": overhead_pct,
        "delay_samples": len(delays),
    }


def try_plot(output_dir, normal, attack):
    try:
        import matplotlib.pyplot as plt
    except Exception:
        return False

    labels = ["Normal", "Attack"]

    fig, axes = plt.subplots(1, 3, figsize=(12, 4))

    axes[0].bar(labels, [normal["pdr"], attack["pdr"]], color=["#4CAF50", "#F44336"])
    axes[0].set_title("PDR (%)")
    axes[0].set_ylim(0, 100)

    axes[1].bar(labels, [normal["avg_delay"], attack["avg_delay"]], color=["#2196F3", "#FF9800"])
    axes[1].set_title("Avg Delay (ms)")

    axes[2].bar(labels, [normal["overhead_pct"], attack["overhead_pct"]], color=["#9C27B0", "#795548"])
    axes[2].set_title("Control/Data (%)")

    fig.tight_layout()
    out_path = f"{output_dir}/phase3_compare.png"
    fig.savefig(out_path, dpi=150)
    return True


def main():
    if len(sys.argv) < 4:
        print("Usage: python3 tools/compare_scenarios.py <normal_log> <attack_log> <output_dir>")
        sys.exit(1)

    normal_log = sys.argv[1]
    attack_log = sys.argv[2]
    output_dir = sys.argv[3]

    normal = parse_log(normal_log)
    attack = parse_log(attack_log)

    print("\n=== Phase 3 Summary ===")
    print(f"Normal: TX={normal['tx']}, RX={normal['rx']}, PDR={normal['pdr']:.2f}%, "
          f"AvgDelay={normal['avg_delay']:.2f}ms, Overhead={normal['overhead_pct']:.2f}%")
    print(f"Attack: TX={attack['tx']}, RX={attack['rx']}, PDR={attack['pdr']:.2f}%, "
          f"AvgDelay={attack['avg_delay']:.2f}ms, Overhead={attack['overhead_pct']:.2f}%")

    with open(f"{output_dir}/phase3_summary.csv", "w") as f:
        f.write("scenario,tx,rx,pdr,avg_delay_ms,rpl_packets,control_data_pct,delay_samples\n")
        f.write(f"normal,{normal['tx']},{normal['rx']},{normal['pdr']:.2f},"
                f"{normal['avg_delay']:.2f},{normal['rpl_packets']},{normal['overhead_pct']:.2f},"
                f"{normal['delay_samples']}\n")
        f.write(f"attack,{attack['tx']},{attack['rx']},{attack['pdr']:.2f},"
                f"{attack['avg_delay']:.2f},{attack['rpl_packets']},{attack['overhead_pct']:.2f},"
                f"{attack['delay_samples']}\n")

    plotted = try_plot(output_dir, normal, attack)
    if plotted:
        print(f"Plot saved to: {output_dir}/phase3_compare.png")
    else:
        print("matplotlib not available; skipped plot")


if __name__ == '__main__':
    main()
