#! /bin/sh

THE_IP=`kubectl get svc -n dev insecure-app -o json | jq -r '.status.loadBalancer.ingress[0].ip'`

echo "${THE_IP}" | grep '^[0-9][0-9.]*[0-9]$' >> /dev/null
if [ $? -ne 0 ]; then
	echo "Unable to determine LB IP. Please ask for help."
	exit 1
fi

cat <<EOF
Gr8 n3ws, Ha><0r,

We c@n 0wn3 th3 d3v 3nvir0nm3nt. 0ur 1337 h@x0r sk1llz w1ll 3n@bl3 us 2 1nfiltr@t3 th3 3nvir0nm3nt @nd 3xpl0it 1t.

Ur n3w comput3r kan B @ccess3d @ http://${THE_IP}:8080/ . h@ve fUn!

4eva ur pal,
Natoshi Sakamoto

p.s. 1f u n33d h3lp, ch3ck out http://${THE_IP}:8080/admin and http://${THE_IP}:8080/crash . 1f u n33d m0r3 h3lp, 1t's @ll 0n u. 1'm 0ut.

EOF
