# ZQM Attestation Sample

Minimal, verifiable attestation artifact demonstrating ZQM's detached CMS (PKCS#7) signing model.

## Files
- `sample.json` — the attestation claim (plaintext payload)
- `sample.json.p7s` — detached CMS signature (DER), signed by `sample_cert.pem`
- `sample_cert.pem` — self-signed sample test certificate (CN=ZQM-Sample-Test-Only)

## Verify the seal
```bash
openssl cms -verify -in sample.json.p7s -inform DER -content sample.json -CAfile sample_cert.pem -out recovered.json
```
On success: `CMS Verification successful` and `recovered.json` matches `sample.json`.

## Why detached CMS
The signed deliverable is separated from the payload, so the original evidence stays human-readable while the seal proves integrity and origin. Production releases use CN=Alex Zelenski code-signing certificates, not this sample test cert.
