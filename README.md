# pqc-readiness-toolkit

NIST/ETSI/CNSA 2.0 PQC readiness assessment for Windows fleets.

## About

`pqc-readiness-toolkit` evaluates Windows host and fleet readiness for post-quantum cryptography transitions. It covers NIST PQC standards, ETSI quantum-safe migration guidance, and CNSA 2.0 Suite B alignment for Windows environments.

## Installation

```bash
pip install -e .
```

Requires Python 3.11+.

## Usage

```bash
# Run PQC readiness scan
pqc-readiness scan --endpoint .

# Generate CNSA 2.0 compliance report
pqc-readiness report --template cnsa2 --output ./reports/

# Assess against NIST standards
pqc-readiness assess --standard nist-800-208
```

## Features

- NIST PQC standard compatibility checks (CRYSTALS-Kyber, Dilithium, SPHINCS+)
- ETSI quantum-safe migration pathway assessment
- CNSA 2.0 Suite B alignment validation
- Windows-native crypto stack inventory
- Fleet-wide PQC readiness aggregation via zqm-intel-platforms
- Markdown and JSON report output
- CI-validated with ruff/mypy

## CI

[![CI](https://github.com/ZQM-Labs/pqc-readiness-toolkit/actions/workflows/ci.yml/badge.svg)](https://github.com/ZQM-Labs/pqc-readiness-toolkit/actions)
[![Ruff](https://img.shields.io/badge/lint-ruff-blue)](https://github.com/astral-sh/ruff)
[![Mypy](https://img.shields.io/badge/typecheck-mypy-blue)](https://github.com/python/mypy)

## Integration: zqm-intel-platforms

`pqc-readiness-toolkit` declares `zqm-intel-platforms>=0.1.0` and feeds PQC assessment results into the fleet attestation mesh.

- Hub role: quantum-readiness telemetry aggregation
- Downstream: zqm-attestation-toolkit, ZQM-AI-Council

## License

Apache-2.0 — see LICENSE file.

## Contact

Alex Zelenski — zqmcomputing@gmail.com
Brand: ZQM Computing / ZQM-Labs
