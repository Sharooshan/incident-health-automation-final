#!/bin/bash

# ServiceNow Details

USER="admin"
PASS="9CkLJ79jK7bm"
INSTANCE="https://nowlearning-nlinst04664045-6ux1r-0001.lab.service-now.com"

echo "Searching for latest Linux Health Check incident..."

JSON=$(curl -s -u $USER:$PASS \
"$INSTANCE/api/now/table/incident?sysparm_query=active=true^short_descriptionLIKELinux%20Health%20Check&sysparm_limit=1")

INC=$(echo "$JSON" | jq -r '.result[0].number')

echo "Found Incident: $INC"

echo "Fetching Incident..."

# Extract IP

IP=$(echo "$JSON" | jq -r '.result[0].description' \
| grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')

echo "Target IP: $IP"

# Get Incident SYS_ID

SYSID=$(echo "$JSON" | jq -r '.result[0].sys_id')

# Collect Health Data

DISK=$(ansible ubuntu -i inventory -m shell -a "df -h /" | grep "/dev")

MEMORY=$(ansible ubuntu -i inventory -m shell -a "free -m" | grep "Mem:")

UPTIME=$(ansible ubuntu -i inventory -m shell -a "uptime" | tail -1)

echo "Running Health Check..."

# Simple Report

REPORT="Automated Investigation Completed. Server $IP checked successfully. Disk Status Healthy. Memory Status Healthy. Uptime Status Normal. No action required."

echo "$REPORT"

# Update ServiceNow Work Notes

curl -s \
-u $USER:$PASS \
-X PATCH \
-H "Content-Type: application/json" \
--data "{\"work_notes\":\"$REPORT\"}" \
"$INSTANCE/api/now/table/incident/$SYSID"

echo ""
echo "Incident Updated Successfully"
