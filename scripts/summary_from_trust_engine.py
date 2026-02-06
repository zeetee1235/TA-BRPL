#!/usr/bin/env python3
import argparse
import csv
import os
import re
from collections import defaultdict


def parse_log(log_path):
    tx=set()
    rx=set()
    delays=[]
    with open(log_path, errors='ignore') as f:
        for line in f:
            line=line.strip()
            if line.startswith('CSV,TX,'):
                parts=line.split(',')
                if len(parts)>=4:
                    try:
                        node=int(parts[2]); seq=int(parts[3])
                        tx.add((node,seq))
                    except:
                        pass
            elif line.startswith('CSV,RX,'):
                parts=line.split(',')
                # CSV,RX,node=1,src_ip,seq,... or CSV,RX,src_ip,seq,...
                if len(parts)>=5 and parts[2]=='node=1':
                    src=parts[3]; seq=parts[4]
                elif len(parts)>=4:
                    src=parts[2]; seq=parts[3]
                else:
                    continue
                try:
                    rx.add((src,int(seq)))
                except:
                    pass
            elif line.startswith('CSV,DELAY,'):
                parts=line.split(',')
                if len(parts)>=3:
                    try:
                        delay=int(parts[2])
                        delays.append(delay)
                    except:
                        pass
    tx_count=len(tx)
    rx_count=len(rx)
    pdr=(rx_count*100/tx_count) if tx_count>0 else 0.0
    avg_delay=(sum(delays)/len(delays)) if delays else None
    return tx_count, rx_count, pdr, avg_delay


def read_last_row(csv_path):
    last=None
    with open(csv_path, errors='ignore') as f:
        for row in csv.reader(f):
            if row and not row[0].startswith('#'):
                last=row
    return last


def read_parent_switch_avg(csv_path):
    rates=[]
    with open(csv_path, errors='ignore') as f:
        rd=csv.DictReader(f)
        for r in rd:
            try:
                rates.append(float(r['switch_rate']))
            except:
                pass
    return sum(rates)/len(rates) if rates else None


def read_stats_last_switch(stats_path):
    last=None
    with open(stats_path, errors='ignore') as f:
        for row in csv.reader(f):
            if row and row[0] != 'line':
                last=row
    if last and len(last)>=8:
        try:
            return float(last[7])
        except:
            return None
    return None


def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('results_dir', help='results/experiments-...')
    ap.add_argument('--out', default='summary_from_trust_engine.csv')
    args=ap.parse_args()

    rows=[]
    for name in os.listdir(args.results_dir):
        run_dir=os.path.join(args.results_dir, name)
        if not os.path.isdir(run_dir):
            continue
        log_path=os.path.join(run_dir,'logs','COOJA.testlog')
        exposure_path=os.path.join(run_dir,'exposure.csv')
        parent_path=os.path.join(run_dir,'parent_switch.csv')
        if not os.path.exists(log_path):
            continue

        tx, rx, pdr, avg_delay = parse_log(log_path)

        e1=e3=None
        if os.path.exists(exposure_path):
            last=read_last_row(exposure_path)
            if last and len(last)>=7:
                try:
                    e1=float(last[5]); e3=float(last[6])
                except:
                    pass
        parent_switch=None
        if os.path.exists(parent_path):
            parent_switch=read_parent_switch_avg(parent_path)
        if parent_switch is None:
            stats_path=os.path.join(run_dir,'stats.csv')
            if os.path.exists(stats_path):
                parent_switch=read_stats_last_switch(stats_path)

        # parse run name
        attack_rate=None; trust=None; seed=None; topo=None
        m=re.search(r'_p(\d+)_', name)
        if m: attack_rate=int(m.group(1))
        m=re.search(r'_s(\d+)$', name)
        if m: seed=int(m.group(1))
        topo=name.split('_')[0]
        trust=1 if '_trust_' in name else 0
        if '_notrust_' in name: trust=0

        rows.append({
            'run': name,
            'topology': topo,
            'attack_rate': attack_rate,
            'trust': trust,
            'seed': seed,
            'pdr': f"{pdr:.2f}",
            'avg_delay_ms': f"{avg_delay:.2f}" if avg_delay is not None else '',
            'tx': tx,
            'rx': rx,
            'lost': tx-rx,
            'e1': f"{e1:.2f}" if e1 is not None else '',
            'e3': f"{e3:.2f}" if e3 is not None else '',
            'parent_switch_rate': f"{parent_switch:.4f}" if parent_switch is not None else ''
        })

    out_path=os.path.join(args.results_dir, args.out)
    with open(out_path,'w',newline='') as f:
        fieldnames=['run','topology','attack_rate','trust','seed','pdr','avg_delay_ms','tx','rx','lost','e1','e3','parent_switch_rate']
        w=csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        for r in sorted(rows, key=lambda x:x['run']):
            w.writerow(r)

    print(out_path)

if __name__=='__main__':
    main()
