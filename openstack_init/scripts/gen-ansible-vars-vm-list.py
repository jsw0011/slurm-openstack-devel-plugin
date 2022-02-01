#!/usr/bin/env python3
import sys
if len(sys.argv) < 2:
    print("Missing input parameters. ./script [slaveips] [slavenames]",file=sys.stderr)
    exit(-1)

slaveips=sys.argv[1].split('\n')
slavenames=sys.argv[2].split('\n')
out=[]
for i, v in enumerate(slaveips):
    out.append(f'  -\n    name: {slavenames[i]}\n    ip: {v}')
print('\n'.join(out))