#!/bin/bash

# Set environment variables
export PATH=/usr/local/bin:/usr/bin:/bin
export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-bundle.crt

# Run the script
/usr/bin/python3 /opt/netbox-webhooks.py >> /var/log/netbox-webhooks.log 2>&1
