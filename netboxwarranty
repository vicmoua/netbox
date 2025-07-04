#!/opt/homebrew/bin/python3
# Netbox warranty script

#--------------------------
# Import required libraries
#--------------------------
import subprocess
import yaml
import secrets
import requests
from datetime import datetime, timedelta

#------------------------------------------------
# Define netbox webhooks config and custom fields
#------------------------------------------------
NETBOX_URL = "https://<URL>/api/dcim/devices/?limit=1000"
CUSTOM_WARRANTY_FIELD = "Warranty_Expiration"
CUSTOM_PROVIDER_FIELD = "Warranty_Provider"

# Manually map choices as netbox does not support returning display values
PROVIDER_DISPLAY_MAP = {
    "choice1": "Dell",
    "choice2": "HP",
    "choice3": "Cisco",
    "choice4": "Juniper"
}

# Set days for checking warranty
TIMEFRAMES = [30, 60, 90, 180, 360]

#-----------------------------------------------------------------
# Define functions in order to test each module and organize logic
#-----------------------------------------------------------------

# Function to load secrets
def load_secrets(path='/opt/secrets.eyaml', private_key=None, public_key=None):
    cmd = [
        "eyaml", "decrypt", "-f", path,
        "--quiet"
    ]
    if private_key:
        cmd += ["--pkcs7-private-key", private_key]
    if public_key:
        cmd += ["--pkcs7-public-key", public_key]

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise Exception(f"eyaml decryption failed: {result.stderr}")
    return yaml.safe_load(result.stdout)

# Load secrets. Strip any extra whitespace.
secrets = load_secrets(
    path='/opt/secrets.eyaml',
    private_key='/root/keys/private_key.pkcs7.pem',
    public_key='/root/keys/public_key.pkcs7.pem'
)
NETBOX_TOKEN = secrets["netbox_token"].strip()
SLACK_WEBHOOK_URL = secrets["slack_webhook_url"].strip()


headers = {
    "Authorization": f"Token {NETBOX_TOKEN}",
    "Accept": "application/json",
    "Content-Type": "application/json"
}

# Fetch devices from NetBox
def fetch_devices():
    """Fetch all devices from NetBox"""
    resp = requests.get(NETBOX_URL, headers=headers)
    devices = resp.json().get("results", [])
    print(f"DEBUG: Fetched {len(devices)} devices from NetBox")
    return devices

# Fetch warranty providers from netbox
def get_provider_label(raw):
    """Map internal provider key to display label"""
    key = raw.get("value") if isinstance(raw, dict) else raw
    return PROVIDER_DISPLAY_MAP.get(key, key or "Unknown provider")

# Fetch expiry dates for each device in netbox
def group_by_expiry(devices):
    """Group devices by exclusive warranty expiration timeframe"""
    from datetime import timezone
    today = datetime.now(timezone.utc).date()
    buckets = {days: [] for days in TIMEFRAMES}

    for device in devices:
        cf = device.get("custom_fields", {})
        expiry_str = cf.get(CUSTOM_WARRANTY_FIELD)
        if not expiry_str:
            continue

        try:
            expiry = datetime.strptime(expiry_str, "%Y-%m-%d").date()
            days_until = (expiry - today).days
            if days_until < 0:
                continue

            provider = get_provider_label(cf.get(CUSTOM_PROVIDER_FIELD))
            info = f"- {device.get('name', 'Unnamed')} | Site: {device.get('site', {}).get('name', 'No site')} | Serial: {device.get('serial', 'No serial')} | Provider: {provider} | Expires: {expiry}"

            for days in TIMEFRAMES:
                if days_until <= days:
                    buckets[days].append(info)
                    break

        except ValueError:
            continue

    return buckets

# Format message being sent to slack: hostname, site, serial number, warranty provider, and expiry date
def format_message(buckets):
    """Create Slack-friendly message"""
    lines = []
    for days in TIMEFRAMES:
        if buckets[days]:
            lines.append(f"*⚠️ Devices with warranties expiring in {days} days:*")
            lines.extend(buckets[days])

    return "\n".join(lines) if lines else "✅ All devices are within warranty."

# Post message to slack
def send_to_slack(message):
    """Send message to Slack webhook"""
    resp = requests.post(SLACK_WEBHOOK_URL, json={"text": message})
    if resp.status_code != 200:
        print(f"Slack Error: {resp.text}")
    else:
        print("Slack notification sent.")

#-----------------------------
# Call functions for execution
#-----------------------------
if __name__ == "__main__":
    devices = fetch_devices()
    buckets = group_by_expiry(devices)
    message = format_message(buckets)
    send_to_slack(message)
