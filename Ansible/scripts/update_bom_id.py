#!/usr/bin/env python3
import json, sys
from pathlib import Path

BOM_PATH = sys.argv[1]  # e.g. /etc/ansible/inventories/BOM.json
TYPE     = sys.argv[2]  # 'vm' or 'lxc'
REF      = sys.argv[3]  # the bom-ref of the component

bom = json.loads(Path(BOM_PATH).read_text())
ids  = []
for c in bom['components']:
    for p in c.get('properties',[]):
        if p['name']=='ID':
            ids.append(int(p['value']))

next_id = max(ids or [0]) + (1 if TYPE=='vm' else 0)
if TYPE=='vm' and next_id<1000: next_id=1000
if TYPE=='lxc' and next_id<2000: next_id=2000

# find component and set its ID property
for c in bom['components']:
    if c['bom-ref']==REF:
        # remove existing ID if any
        c['properties'] = [p for p in c['properties'] if p['name']!='ID']
        c['properties'].append({'name':'ID','value':str(next_id)})
        break
else:
    print("Component not found", file=sys.stderr); sys.exit(1)

Path(BOM_PATH).write_text(json.dumps(bom, indent=2))
print(f"Set {REF} ID → {next_id}")
