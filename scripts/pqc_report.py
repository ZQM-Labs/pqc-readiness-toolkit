#!/usr/bin/env python3
import sys,json,hashlib,os
from datetime import datetime, timezone
from pathlib import Path

EVIDENCE=Path(__file__).resolve().parents[1]/'evidence'
DIST=Path(__file__).resolve().parents[1]/'dist'

def sha256(path=None,data=None):
    h=hashlib.sha256()
    if data is not None: h.update(data)
    elif path: h.update(Path(path).read_bytes())
    return h.hexdigest()

def manifest():
    print('Building PQC Readiness report...')
    files=[]
    for p in sorted(EVIDENCE.glob('pqc_*')):
        if p.is_file(): files.append((p.name, sha256(p), p.stat().st_size))
    manifest={
        'sku':'ZQM-PQC-READINESS-001',
        'generated_at': datetime.now(timezone.utc).isoformat(),
        'methodology':'11-standard PQC readiness',
        'evidence_files':[{'name':n,'sha256':h,'bytes':b} for n,h,b in files],
        'verification_note':'Verify all hashes match evidence files; do not regenerate.'
    }
    out=(DIST/'pqc_readiness_manifest.json')
    out.write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    print('Wrote',out)
    print('Evidence files:',len(files))
    for n,h,b in files: print(f'  {b:5d}  {n}  {h}')

if __name__=='__main__': manifest()