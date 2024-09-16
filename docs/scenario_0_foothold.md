# Gain Foothold: Scenario 0 Attack

## Warning

In these Attack scenarios, we're going to be doing a lot of things that can be crimes if done without permission. Today, you have permission to perform these kinds of attacks against your assigned training environment.

In the real world, use good judgment. Don't hurt people, don't get yourself in trouble. Only perform security assessments against your own systems, or with written permission from the owners.

## Backstory

### Name: __Red__

* Opportunist
* Easy money via crypto-mining
* Uses automated scans of web IP space for specific issues
* Leverages off-the-shelf attacks
* Basic Kubernetes knowledge

## Initial Access

A development team has deployed a new application onto a managed Kubernetes cluster. During development the team encountered several hurdles while developing their application in a container. To resolve these issues they installed numerous packages into the container. They also granted far more privileges to the service account than necessary and are running their application in privileged mode. Finally they mapped the ```docker.sock``` socket into the container "for reasons". This application is now exposed publicly on the production AKS cluster and includes an administrative UI that can only be accessed by users who know a *super secret* url path. 

Red has discovered the insecure application exposed to the public internet and suspects that they may be able to use it to gain a foothold on the underlying cluster. They start by scanning the domain for backdoors using a dictionary attack. They quickly discover the admin UI and and use it to setup an SSH tunnel that grants them persistent access to the cluster. 

Find the public endpoint for the app:
```bash
cd ./workshop/scenario_0
./scan-website.sh
```

Start a SSH server on the cluster by running this command through the web interface:
```bash
docker run -d -p 10022:22 --network host --name metrics-server testcontainers/sshd
//TODO: figure out how to expose the ssh server publicly
// IDEA1: use SA from app to create an LB service in front of the SSH port
```

Now you can connect to the node directly as root:
```bash
```