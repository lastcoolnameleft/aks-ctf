# AKS CTF

Welcome to the Attacking and Defending Azure Kubernetes Service Clusters.  This is inspired by [Secure Kubernetes](https://securekubernetes.com/), as [presented at KubeCon NA 2019](https://www.youtube.com/watch?v=UdMFTdeAL1s). We'll help you create your own AKS so you can follow along as we take on the role of two attacking personas looking to make some money and one defending persona working hard to keep the cluster safe and healthy.

## Getting Started

Click on [Getting Started](azure/) in the table of contents and follow the directions.

When a `kubectl get pods --all-namespaces` gives output like the following, you're ready to begin the tutorial.

```
$ kubectl get pods --all-namespaces
NAMESPACE     NAME                                         READY   STATUS    RESTARTS   AGE
dev           app-6ffb94966d-9nqnk                         1/1     Running   0          70s
dev           dashboard-5889b89d4-dj7kq                    2/2     Running   0          70s
dev           db-649646fdfc-kzp6g                          1/1     Running   0          70s
...
prd           app-6ffb94966d-nfhn7                         1/1     Running   0          70s
prd           dashboard-7b5fbbc459-sm2zk                   2/2     Running   0          70s
prd           db-649646fdfc-vdwj6                          1/1     Running   0          70s

```


## About the Creators

* [@lastcoolname](https://lastcoolnameleft.com) is a Partner Solution Architect as Microsoft and has supported the Azure partner ecosystem enable and secure their Docker and Kubernetes deployments since joining Microsoft in 2007.
* [@tabbysable](https://twitter.com/tabbysable) has been a hacker and cross-platform sysadmin since the turn of the century. She can often be found teaching network offense and defense to sysadmins, system administration to security folks, bicycling, and asking questions that start with "I wonder what happens if we..."
* [@petermbenjamin](https://twitter.com/petermbenjamin) is a Senior Software Engineer with a background in Information Security and a co-organizer for the San Diego Kubernetes and Go meet-ups. He has a passion for enabling engineers to build secure and scalable applications, services, and platforms on modern distributed systems.
* [@jimmesta](https://twitter.com/jimmesta) is a security leader that has been working in AppSec and Infrastructure Security for over 10 years. He founded and led the OWASP Santa Barbara chapter and co-organized the AppSec California security conference. Jimmy has taught at private corporate events and security conferences worldwide including AppSec USA, LocoMocoSec, SecAppDev, RSA, and B-Sides. He has spent significant time on both the offense and defense side of the industry and is constantly working towards building modern, developer-friendly security solutions.
* [@BradGeesaman](https://twitter.com/bradgeesaman) is an Independent Security Consultant helping clients improve the security of their Kubernetes clusters and supporting cloud environments. He has recently spoken at KubeCon NA 2017 on Kubernetes security and has over 5 years of experience building, designing, and delivering ethical hacking educational training scenarios.
