# Securing AKS

## Intro
Company X is looking to join the future and containerize their business. To this end they have asked their ITOps team to deploy their first Kubernetes cluster.

Bob has run VM fleets for years and is great at it, but he has no idea what kubernetes is. After some bing searching he learns about AKS and goes to the azure portal to deploy his first cluster.

Once deployed he emails the kubernetes context to the development team so that they can log in and deploy their app.

Red team intercepted that email and now has the access to the cluster.

### Attack 1 - Network security (private API)

Red team uses the intercepted context to deploy a bitcoin minter to the cluster.
Unknown (at this point to blue) they also:
  * install a trojan on the cluster (attack 2)
  * replace one of the application images on the ACR with a compromised image (attack 3)
  * gain access to the app source code (attack 4)

User Activity (Red):
  * download context
  * connect to cluster
  * deploy miner workloads
  * deploy Attack 2 workload (ssh masquerading as a 'metrics-server' deployment and service running on a unsuspicious port)

Blue team investigates slow behavior of the app and discovers the bitcoin miner. They remove the workload, realize their mistake having a public API and make cluster private. Because Blue is ready to get back to bed, they fail to notice that there is another new workload running on the cluster....

User Activity (Blue):
  * find the pod
  * delete the pod
  * secure cluster api

### Attack 2 - Principle of least privilege

Thankfully Red team also leveraged their access to the system to install a backdoor on the cluster. Now that it is private they can still access through the publicly exposed workload.
Red Team reinstall miner on cluster.

User Activity (Red):
  * connect to cluster through public endpoint exposed in A1
  * deploy bitcoin miner using SA token
  * use the cluster principal to push a containmenated image to the ACR (webshell)

Blue team is sad to rediscover that a miner is back on the cluster. They remove the miner and further secure cluster with policy.

User Activity (Blue):
  * delete all the red stuff running on the cluster
  * enable azure policy with secure cluster baseline enabled
  * enable AAD auth and disable local admin
  * Nuke it from orbit! Blue starts over with a fresh nodepool


### Attack 3 - Trusted images (signing)

Red team left behind a suprise in the form of a compromised image on the container repository.

User Activity (Red):
  * do nothing, miner is running in app now

Blue team finds another miner. They clean up the miner and enable image signing

User Activity (Blue):
  * app is running hot, figure out why?
    * k exec -it --rm -- /bin/sh ps -a
  * there is a miner running in the app!
  * turn on image signing
  * enable policy to require signed images on cluster
  * redeploy app with trusted image

### Attack 4 - Application layer protection

Red team has lost persistent access to the cluster and is looking to regain a foothold. They start attacking the app. They execute a known process injection exploit against the app (SSRF).

TODO: maybe we can use this one? https://github.com/latiotech/insecure-kubernetes-deployments/blob/main/insecure-js/server.js

Blue team enables WAF and Defender for containers

