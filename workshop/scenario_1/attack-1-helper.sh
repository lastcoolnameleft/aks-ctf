#! /bin/sh

THE_IP=`kubectl get svc -n dev dashboard -o json | jq -r '.status.loadBalancer.ingress[0].ip'`

echo "${THE_IP}" | grep '^[0-9][0-9.]*[0-9]$' >> /dev/null
if [ $? -ne 0 ]; then
	echo "Unable to determine cluster NodeIP. Please ask for help."
	exit 1
fi

cat <<EOF
Gr8 n3ws, Ha><0r,

You've got shellz!

0ur syst3m p0pped anoth3r box 4 joo. t3h fundz hav b33n deduct3d fr0m ur accoun7.

Ur n3w comput3r kan B @ccess3d @ http://${THE_IP}:8080/webshell us1ng Ur r3gurlar cr3ds. h@ve fUn!

4eva ur pal,
Natoshi Sakamoto
EOF
