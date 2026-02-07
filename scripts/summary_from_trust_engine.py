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


def read_last_row_dict(csv_path):
    last=None
    with open(csv_path, errors='ignore') as f:
        rd=csv.DictReader(f)
        for row in rd:
            if row:
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
        rd=csv.DictReader(f)
        for row in rd:
            if row:
                last=row
    if last and 'parent_switch_rate' in last:
        try:
            return float(last['parent_switch_rate'])
        except:
            return None
    return None


def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('results_dir', help='results/experiments-...')
    ap.add_argument('--out', default='summary_from_trust_engine.csv')
    args=ap.parse_args()

    rows=[]
    invalid_rows=[]
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
        e1_num=e1_den=e3_num=e3_den=None
        if os.path.exists(exposure_path):
            last_dict=read_last_row_dict(exposure_path)
            if last_dict:
                try:
                    e1=float(last_dict.get('e1',''))
                except:
                    pass
                try:
                    e3=float(last_dict.get('e3',''))
                except:
                    pass
                try:
                    e1_num=float(last_dict.get('e1_num',''))
                    e1_den=float(last_dict.get('e1_den',''))
                    e3_num=float(last_dict.get('e3_num',''))
                    e3_den=float(last_dict.get('e3_den',''))
                except:
                    pass
            else:
                last=read_last_row(exposure_path)
                if last and len(last)>=7:
                    try:
                        e1=float(last[5]); e3=float(last[6])
                        e1_num=float(last[2])
                        e1_den=float(last[1])
                        e3_den=float(last[4])
                        if e3 is not None and e3_den:
                            e3_num=(e3 * e3_den) / 100.0
                    except:
                        pass
        parent_switch=None
        sink_adv_attacker=None
        sink_stab_attacker=None
        sink_adv_mean=None
        sink_stab_mean=None
        if os.path.exists(parent_path):
            parent_switch=read_parent_switch_avg(parent_path)
        if parent_switch is None:
            stats_path=os.path.join(run_dir,'stats.csv')
            if os.path.exists(stats_path):
                parent_switch=read_stats_last_switch(stats_path)
                last_stats=read_last_row_dict(stats_path)
                if last_stats:
                    try: sink_adv_attacker=float(last_stats.get('sink_adv_attacker',''))
                    except: pass
                    try: sink_stab_attacker=float(last_stats.get('sink_stab_attacker',''))
                    except: pass
                    try: sink_adv_mean=float(last_stats.get('sink_adv_mean',''))
                    except: pass
                    try: sink_stab_mean=float(last_stats.get('sink_stab_mean',''))
                    except: pass

        # parse run name (supports legacy and new naming)
        attack_rate=None; trust=None; seed=None; topo=None; lam=None; gam=None; mode=None; delta=None; alpha=None
        m=re.search(r'_p(\d+)_', name)
        if m:
            attack_rate=int(m.group(1))
        m=re.search(r'_atk(\d+)_', name)
        if m:
            attack_rate=int(m.group(1))
        m=re.search(r'_s(\d+)$', name)
        if m:
            seed=int(m.group(1))
        topo=name.split('_')[0]
        trust=None
        m=re.search(r'_trust(\d+)_', name)
        if m:
            trust=int(m.group(1))
        else:
            trust=1 if '_trust_' in name else 0
            if '_notrust_' in name:
                trust=0
        m=re.search(r'_lam(\d+)_gam(\d+)_', name)
        if m:
            lam=int(m.group(1)); gam=int(m.group(2))
        else:
            lam=0
            gam=1
        m=re.search(r'_mode(\d+)_', name)
        if m:
            mode=int(m.group(1))
        m=re.search(r'_d(\d+)_', name)
        if m:
            delta=int(m.group(1))
        m=re.search(r'_a([0-9.]+)_', name)
        if m:
            try:
                alpha=float(m.group(1))
            except:
                alpha=None

        invalid_reason=[]
        if tx == 0:
            invalid_reason.append('tx=0')
        if rx == 0:
            invalid_reason.append('rx=0')
        if tx < rx:
            invalid_reason.append('tx<rx')
        if e1_den is not None and e1_den == 0:
            invalid_reason.append('e1_den=0')
        if e3_den is not None and e3_den == 0:
            invalid_reason.append('e3_den=0')

        row={
            'run': name,
            'topology': topo,
            'attack_rate': attack_rate,
            'trust': trust if trust is not None else '',
            'lambda': lam if lam is not None else '',
            'gamma': gam if gam is not None else '',
            'attack_mode': mode if mode is not None else '',
            'sink_delta': delta if delta is not None else '',
            'trust_alpha': alpha if alpha is not None else '',
            'seed': seed,
            'pdr': f"{pdr:.2f}",
            'avg_delay_ms': f"{avg_delay:.2f}" if avg_delay is not None else '',
            'tx': tx,
            'rx': rx,
            'lost': tx-rx,
            'e1': f"{e1:.2f}" if e1 is not None else '',
            'e3': f"{e3:.2f}" if e3 is not None else '',
            'e1_num': f"{e1_num:.0f}" if e1_num is not None else '',
            'e1_den': f"{e1_den:.0f}" if e1_den is not None else '',
            'e3_num': f"{e3_num:.0f}" if e3_num is not None else '',
            'e3_den': f"{e3_den:.0f}" if e3_den is not None else '',
            'parent_switch_rate': f"{parent_switch:.4f}" if parent_switch is not None else '',
            'sink_adv_attacker': f"{sink_adv_attacker:.4f}" if sink_adv_attacker is not None else '',
            'sink_stab_attacker': f"{sink_stab_attacker:.4f}" if sink_stab_attacker is not None else '',
            'sink_adv_mean': f"{sink_adv_mean:.4f}" if sink_adv_mean is not None else '',
            'sink_stab_mean': f"{sink_stab_mean:.4f}" if sink_stab_mean is not None else '',
        }
        if invalid_reason:
            row['invalid_reason']=';'.join(invalid_reason)
            invalid_rows.append(row)
        else:
            rows.append(row)

    out_path=os.path.join(args.results_dir, args.out)
    with open(out_path,'w',newline='') as f:
        fieldnames=['run','topology','attack_rate','trust','lambda','gamma','attack_mode','sink_delta','trust_alpha','seed','pdr','avg_delay_ms','tx','rx','lost','e1','e1_num','e1_den','e3','e3_num','e3_den','parent_switch_rate','sink_adv_attacker','sink_stab_attacker','sink_adv_mean','sink_stab_mean']
        w=csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        for r in sorted(rows, key=lambda x:x['run']):
            w.writerow(r)

    if invalid_rows:
        invalid_path=os.path.join(args.results_dir, 'invalid_runs.csv')
        with open(invalid_path,'w',newline='') as f:
            fieldnames=['run','topology','attack_rate','trust','lambda','gamma','attack_mode','sink_delta','trust_alpha','seed','tx','rx','lost','e1','e1_num','e1_den','e3','e3_num','e3_den','invalid_reason']
            w=csv.DictWriter(f, fieldnames=fieldnames)
            w.writeheader()
            for r in sorted(invalid_rows, key=lambda x:x['run']):
                w.writerow({k:r.get(k,'') for k in fieldnames})

    print(out_path)

if __name__=='__main__':
    main()
