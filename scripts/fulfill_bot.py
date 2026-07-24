#!/usr/bin/env python3
"""ZQM Toolkit fulfillment bot (generic, repo-agnostic)."""
import os, re, json, secrets, smtplib
from email.message import EmailMessage

issue_body = os.environ.get('ISSUE_BODY', '')
issue_url = os.environ.get('ISSUE_URL', '')
release_url = os.environ.get('RELEASE_URL',
    'https://github.com/ZQM-Labs/zqm-attestation-toolkit/releases/latest/download/zqm_package.zip')
expected_hash = os.environ.get('EXPECTED_HASH', '')

smtp_host = os.environ.get('SMTP_HOST', 'smtp.gmail.com')
smtp_port = int(os.environ.get('SMTP_PORT', '587'))
smtp_user = os.environ.get('SMTP_USER')
smtp_pass = os.environ.get('SMTP_PASS')
sender = os.environ.get('EMAIL_FROM', smtp_user)

if not smtp_user or not smtp_pass:
    raise SystemExit('SMTP_USER/SMTP_PASS not set')

LICENSE_PFX = 'ZQM-LIC-2026-'
TICKET_PFX = 'ZQM-TKT-2026-'

def first(pattern, text, flags=0):
    m = re.search(pattern, text, flags)
    return m.group(1).strip() if m else None

sku = first(r'SKU[:\s]+([A-Za-z0-9\-]+)', issue_body)
if not sku:
    sku = first(r'\b(ZQM-[A-Za-z0-9\-]+|PQC-(?:ASSESS|PILOT|RETAINER))\b', issue_body)
if not sku:
    raise SystemExit('No valid ZQM SKU found in issue body.')

txid = (first(r'(?i)txid[:\s]+([A-Za-z0-9]{40,})', issue_body)
        or first(r'\b([A-Za-z0-9]{40,})\b', issue_body))
if not txid:
    raise SystemExit('No txid found in issue body.')

buyer_email = first(r'(?i)email[:\s]+([A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,})', issue_body)
if not buyer_email:
    buyer_email = smtp_user

license_id = f'{LICENSE_PFX}{secrets.token_hex(4).upper()}'
ticket_id = f'{TICKET_PFX}{secrets.token_hex(4).upper()}'

license_payload = {
    'ticket': ticket_id,
    'license_id': license_id,
    'sku': sku,
    'txid': txid,
    'buyer_email': buyer_email,
    'release_url': release_url,
    'expected_sha256': expected_hash,
}

receipt = f"""Hello,

ZQM Toolkit license confirmed.

Ticket: {ticket_id}
License ID: {license_id}
SKU: {sku}
Payment txid: {txid}
Licensed contact: {buyer_email}

Download:
 {release_url}

Verify the release before extracting (PowerShell):
 (Get-FileHash zqm_package.zip -Algorithm SHA256).Hash

Expected SHA256: {expected_hash}

Support: zqmcomputing@gmail.com
Reference: {issue_url}

Do not share your license ID publicly. This email is your receipt.
"""

msg = EmailMessage()
msg['Subject'] = f'Your ZQM Toolkit receipt — {license_id}'
msg['From'] = sender
msg['To'] = buyer_email
msg.set_content(receipt)

with smtplib.SMTP(smtp_host, smtp_port) as s:
    s.ehlo()
    s.starttls()
    s.login(smtp_user, smtp_pass)
    s.send_message(msg)

out = {
    'ticket': ticket_id,
    'license_id': license_id,
    'sku': sku,
    'txid': txid,
    'buyer_email': buyer_email,
}
print(json.dumps(out))
