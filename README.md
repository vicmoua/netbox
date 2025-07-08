# NetBox Warranty Notification Script

This script monitors device warranties in NetBox and sends Slack alerts for upcoming expirations. It uses encrypted secrets for security via `eyaml`. Note that when defining the warranty fields they must be using the following format: <customfield>_<customfield> as the API does not support spaces (eg. warranty_expiration, end_of_life, warranty_type, etc.).

---
Requirements:
- Ruby v3.0
- Python3
- Netbox API Token
- Slack Webhooks

---
1. Create Slack Integration (Slack Admin)
2. Get NetBox API Token
3. Install and Configure eyaml
sudo yum install ruby
gem install hiera-eyaml

4. Generate Encryption Keys
eyaml createkeys

output:
{pwd}/keys/private_key.pkcs7.pem
{pwd}/keys/public_key.pkcs7.pem

5. Encrypt Secrets
eyaml encrypt -s "<netboxtoken>" --label netbox_token
eyaml encrypt -s "<slackwebhookurl>" --label slack_webhook_url

6. Import and Set Up the Warranty Script
chmod +x netboxwarranty.py

7. Create Virtual Environment & Install Modules
python3 -m venv venv
source venv/bin/activate
python3 -m ensurepip --upgrade
pip install --upgrade pip
pip install requests pyyaml

8. Optionally freeze:
pip freeze > requirements.txt
# To re-install later:
pip install -r requirements.txt

9. Create Encrypted Config File
OUTPUT_FILE="{pwd}/secrets.eyaml"
PUB_KEY="{pwd}/keys/public_key.pkcs7.pem"
echo "---" > "$OUTPUT_FILE"

# Encrypt NetBox token
NETBOX_TOKEN="<netboxapitoken>"
echo "$NETBOX_TOKEN" | eyaml encrypt --pkcs7-public-key "$PUB_KEY" --label "netbox_token" --stdin --output block >> "$OUTPUT_FILE"

# Encrypt Slack webhook
SLACK_WEBHOOK_URL="<slackwebhookurl"
echo "$SLACK_WEBHOOK_URL" | eyaml encrypt --pkcs7-public-key "$PUB_KEY" --label "slack_webhook_url" --stdin --output block >> "$OUTPUT_FILE"
```

10. Test the Script
python netbox-warranty.py

11. Automate with Cron. Run every Monday at 12:00AM UTC:
sudo crontab -e

Add the following:
0 0 * * 1 /usr/bin/python3 {pwd}/netbox-warranty.py >> /var/log/netbox_warranty.log 2>&1

Check jobs:
crontab -l


# Required Python Imports

```python
import subprocess
import yaml
import secrets
```
