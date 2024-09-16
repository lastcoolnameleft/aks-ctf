#! /bin/sh
the_ip=`kubectl get svc -n prd dashboard -o json | jq -r '.status.loadBalancer.ingress[0].ip'`

echo "${the_ip}" | grep '^[0-9][0-9.]*[0-9]$' >> /dev/null
if [ $? -ne 0 ]; then
	echo "Unable to determine cluster NodeIP. Please ask for help."
	exit 1
fi

echo
echo
echo "DarkRed's nmap command is:"
echo "nmap -sT -A -T4 -n -v -Pn ${the_ip}"
echo
echo
echo "DarkRed uploaded the webshell to:"
echo "http://${the_ip}:8080/webshell/"
echo
echo
