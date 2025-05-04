#!/usr/bin/env python3
import json
import argparse
from pathlib import Path

def load_bom(path):
    return json.loads(Path(path).read_text())

def extract_components(bom):
    hosts = {}
    groups = {'hardware': [], 'virtual-machines': [], 'containers': []}
    for comp in bom.get('components', []):
        ref = comp['bom-ref']
        props = {p['name']: p['value'] for p in comp.get('properties', [])}
        ext = next((e for e in comp.get('extensions', []) if e.get('extensionType')=='tagitek.config'), {})

        hv = {}
        # ansible_playbook
        if 'ansiblePlaybook' in ext:
            hv['ansible_playbook'] = ext['ansiblePlaybook']
        # env, volumes, ports, schedules
        for key in ('env','volumes','ports','schedules','n8nWorkflows','n8nNodes'):
            if key in ext:
                hv[key] = ext[key]
        # parse IP from Network property
        net = props.get('Network','')
        for part in net.split(';'):
            if part.strip().lower().startswith('ip:'):
                hv['ansible_host'] = part.split(':',1)[1].strip()

        hosts[ref] = hv

        t = comp['type']
        if t.startswith('hardware'):
            groups['hardware'].append(ref)
        elif t.startswith('virtual-machine'):
            groups['virtual-machines'].append(ref)
        elif t.startswith('container'):
            groups['containers'].append(ref)

    return hosts, groups

def build_inventory(hosts, groups):
    inv = {'_meta': {'hostvars': hosts}}
    for g,v in groups.items():
        inv[g] = {'hosts': v}
    return inv

def main():
    p = argparse.ArgumentParser()
    p.add_argument('--bom', required=True)
    p.add_argument('--out', default='inventory.json')
    args = p.parse_args()

    bom = load_bom(args.bom)
    hosts, groups = extract_components(bom)
    inv = build_inventory(hosts, groups)
    Path(args.out).write_text(json.dumps(inv, indent=2))
    print(f"Wrote inventory to {args.out}")

if __name__=='__main__':
    main()
