#!/usr/bin/env python3
# mask all ip addresses
import regex as re
import os
rx=re.compile('((?<=[^0-9])|(?<=^))[0-9]{1,3}\.[0-9]{1,3}\.([0-9]{1,3})\.([0-9]{1,3})(?=[^0-9]|$)')
dir_files=os.walk('.')
filtered_dir_files=[]
for dir in dir_files:
    l = list(filter(lambda s:s.endswith(('.py', '.yml', '.json', '.txt', '.conf', '.sh', '.js')),
    dir[2]))
    if len(l) > 0:
        filtered_dir_files.append((dir[0],l))

for fdir in filtered_dir_files:
    for fname in fdir[1]:
        path=f'{fdir[0]}/{fname}'
        content=""
        with os.fdopen(os.open(path, os.O_RDWR), 'r') as fd:
            content=fd.read()
        content=rx.sub(r'000.000.\g<2>.\g<3>',content)
        with os.fdopen(os.open(path, os.O_RDWR), 'w') as fd:
            fd.write(content)
print("All IP addresses masked as 000.000.xxx.xxx. (x stays as it is)")