#!/usr/bin/env python3
import sys
if len(sys.argv) < 5:
    print("Missing input parameters. ./script [mastername] [masterip] [slaveips] [slavenames] [cpus-count]",file=sys.stderr)
    exit(-1)

slaveips=sys.argv[3].split('\n')
slavenames=sys.argv[4].split('\n')
cpusC=sys.argv[5]
mastername=sys.argv[1]
masterip=sys.argv[2]
out=[]
out.append('\n#Auto generated nodes configurations')
out.append(f'ControlAddr={masterip}')
out.append(f'ControlMachine={mastername}')
for i, v in enumerate(slaveips):
    out.append(f'NodeName={slavenames[i]} CPUs={cpusC} NodeAddr={v} State=UNKNOWN')
print('\n'.join(out))