# PQC Readiness — 11-Standard Enterprise Methodology
Version: 1.0.0-draft
Standard-basis: NIST + CNSA 2.0 + ETSI + IETF
License: Apache-2.0 (methodology); deliverables sell separately

## The 11 Standards

| Slot | Standard ID | Title | Role in this methodology |
|------|------------|-------|--------------------------|
| 1 | FIPS 203 | CRYSTALS-Kyber KEM | Primary key-establishment for hybrid TLS/IPsec/PKI |
| 2 | FIPS 204 | CRYSTALS-Dilithium | Primary digital-signature for code-signing + document signing |
| 3 | FIPS 205 | SPHINCS+ | Backup stateless hash signature; long-lived root trust anchor |
| 4 | FIPS 206 | FN-DSA/Falcon | Compact signature for smart-card + embedded TPM profiles |
| 5 | SP 800-131A Rev.3 | Transitioning Cryptographic Algorithms | Defines the "acceptable to disallowed" path for RSA≤3072/ECDSA≤P-384 by 2030/2035 |
| 6 | SP 800-57 Part 1 | Key Management Recommendations | Cryptographic key-lifecycle mapping to migration stages |
| 7 | SP 800-52 Rev.2 | TLS Guidelines | TLS 1.2 → 1.3 hybrid PQ cipher-suite validation matrix |
| 8 | SP 800-204 | IoT/End Device Security | Endpoint inventory + firmware trust-zone attestation profile |
| 9 | SP 800-161 | Supply Chain Risk Management | Vendor PQ-readiness scoring; provider attestation checklist |
| 10 | NSA CNSA 2.0 | Commercial National Security Algorithm Suite (cv143v1) | Federal buyer baseline; optional commercial customer overlay |
| 11 | ETSI TS 103 712 | Migration to Quantum-Safe Cryptography | European-aligned migration roadmap template + control mapping |

## Methodology Shape

Stage 1 — Asset Discovery (standards 5, 6, 8)
  - Inventory asymmetric keys across domain, code-signing, VPN, Wi-Fi/EAP-TLS, BitLocker recovery, smart-card, CAs.
  - Classify by standard 800-57 strength and 800-131A algorithm class.

Stage 2 — Risk Scoring (standards 5, 9, 10)
  - Map each key to harvest-now (TLS handshakes), harvest-store-break (long-lived PKI), live-signature (code-signing).
  - Apply CNSA 2.0 and ETSI 103 712 priority tiers to schedule migration order.

Stage 3 — Hybrid Transition Design (standards 1, 2, 3, 4, 7)
  - Hybrid key exchange: X25519 + Kyber768.
  - Hybrid signatures: ECDSA P-384 + Dilithium3 for initial transition; Dilithium3/FN-DSA standalone for post-2035.
  - SPHINCS+ reserved for high-assurance roots with 50+ year archival requirements.
  - TLS config aligned to SP 800-52 Rev.2 with PQ cipher suites.

Stage 4 — Attestation + Reporting (all 11)
  - Deliverable: CMS-signed PQC Readiness Report with per-endpoint hash evidence.
  - Controls mapped to NIST CSF / ISO 27001 Annex A / ETSI 103 712.

## Control Mapping (Summary)

| Control ID | Standard | Test | Evidence |
|---|---|---|---|
| PQC-01 | 800-131A | RSA-2048/ECDSA-P256 inventory | Registry/CNG key hash list |
| PQC-02 | 800-57 | Key-type classification | Attestation report section |
| PQC-03 | FIPS 203/204 | Hybrid cipher-suite validation | Wireshark + Schannel trace hash |
| PQC-04 | CNSA 2.0 | Federal-baseline gap review | Gap matrix + remediation plan |
| PQC-05 | 800-161 | Vendor PQ questionnaire | CSV of vendor attestations |
| PQC-06 | ETSI 103 712 | Migration stage per endpoint | Stage table + owner sign-off |

## Success Criteria
- Every discovered asymmetric key mapped to exactly one slot above.
- Hybrid and standalone configurations validated in staging before production push.
- Deliverable is verifiable: SHA-256 per evidence file + CMS signature chain.
