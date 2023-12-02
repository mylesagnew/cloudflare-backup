#!/bin/bash

# Bash script to Backup DNS records
CLOUDFLARE_ENDPOINT="https://api.cloudflare.com/client/v4/"

# Array to store domain names
declare -a domainList

# Function to check environment variables
checkEnvironment() {
    if [ -f ".env" ]; then
        echo "Using .env file"
        source .env
    else
        echo "No .env file found. Exiting"
        exit 1
    fi
}

# Function to fetch domains from Cloudflare
getDomains() {
    page=${1:-1}
    response=$(curl -s -X GET "${CLOUDFLARE_ENDPOINT}zones?page=${page}" \
        -H "X-Auth-Email: $CLOUDFLARE_USER_EMAIL" \
        -H "X-Auth-Key: $CLOUDFLARE_API_KEY" \
        -H "Content-Type: application/json")

    if [ $? -eq 0 ]; then
        count=$(echo "$response" | jq -r '.result_info.count')
        total_pages=$(echo "$response" | jq -r '.result_info.total_pages')
        total_count=$(echo "$response" | jq -r '.result_info.total_count')

        echo "Fetching batch of $count DNS records ..."
        addDomainsToList "$response"

        if [ $page -lt $total_pages ]; then
            getDomains $((page + 1))
        else
            echo "Fetched $total_count domains."
        fi
    else
        echo "Error: Failed to fetch domains. Exiting."
        exit 1
    fi
}

# Function to add domains to the list
addDomainsToList() {
    result=$(echo "$1" | jq -c '.result[] | {id: .id, name: .name}')
    while read -r line; do
        domainList+=("$line")
    done <<< "$result"
}

# Function to export DNS records for a domain
exportDNS() {
    if [ ! -d "./domains" ]; then
        mkdir "./domains"
    fi

    domain_id=$(echo "$1" | jq -r '.id')
    domain_name=$(echo "$1" | jq -r '.name')

    response=$(curl -s -X GET "${CLOUDFLARE_ENDPOINT}zones/${domain_id}/dns_records/export" \
        -H "X-Auth-Email: $CLOUDFLARE_USER_EMAIL" \
        -H "X-Auth-Key: $CLOUDFLARE_API_KEY" \
        -H "Content-Type: application/json")

if [ $? -eq 0 ]; then
    timestamp=$(date +"%Y%m%d_%H%M%S")
    echo "$response" > "./domains/${domain_name}_${timestamp}.txt"
    echo "Exported DNS records for domain: ${domain_name}"
else
    echo "Error exporting DNS records for domain $domain_name. Exiting."
    exit 1
fi

}

# Main Script

# Check environment
checkEnvironment

# Fetch data from Cloudflare
echo "Getting List of domains from Cloudflare"
echo "======================================="

# Get domain names from Cloudflare
getDomains

# Export Domain Records
echo "Writing domain DNS files"
for domain in "${domainList[@]}"; do
    exportDNS "$domain"
done

echo "Domain DNS records complete. Please check the /domains directory for your files"
