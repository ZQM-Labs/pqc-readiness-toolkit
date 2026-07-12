#!/usr/bin/env python3
"""PQC Readiness Toolkit validation tests for pytest."""
import re, json
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]

def _read(*parts):
    return (REPO.joinpath(*parts)).read_text(encoding='utf-8', errors='ignore')

def test_readme_offer_skus():
    offer = _read('README-offer.md')
    for sku in ['PQC-ASSESS','PQC-PILOT','PQC-RETAINER']:
        assert sku in offer, f'README-offer missing {sku}'

def test_manifests_valid_json():
    for rel in ['dist/pqc_readiness_manifest.json','evidence/pqc_summary.json']:
        p = REPO/rel
        assert p.exists(), f'{rel} missing'
        json.loads(p.read_text(encoding='utf-8'))
    assert (REPO/'dist/package_manifest.json').exists(), 'dist/package_manifest.json missing'

def test_license_present():
    # Accept LICENSE or either permissive license file surface
    found = any((REPO/f).exists() for f in ['LICENSE','LICENSE-OS.md','LICENSE-COMMERCIAL.md'])
    assert found, 'LICENSE missing'

def test_no_secret_patterns_in_ps1():
    patterns = [re.compile(r'(?i)(xpriv|mnemonic|seed phrase|private[_ ]key.*[:=]|[^/\\][\\/]alex[\\/].*\.(?:pem|pfx|p12|pvk|key))')]
    for ps in (REPO/'scripts').glob('**/*.ps1'):
        txt = ps.read_text(encoding='utf-8', errors='ignore')
        assert not any(p.search(txt) for p in patterns), f'secret pattern in {ps}'
