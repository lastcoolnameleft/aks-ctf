# Getting Started

1. Create a new Azure account or choose an existing one, as you prefer.

1.  Open a new tab to [Azure Cloud Shell](https://learn.microsoft.com/en-us/azure/cloud-shell/get-started/classic?tabs=azurecli).  You can [click here](https://shell.azure.com/).

1. Clone the repo: `git clone https://github.com/lastcoolnameleft/aks-ctf.git && cd aks-ctf/workshop`

1. Enable the AKS Resource Provider: `az provider register --namespace Microsoft.ContainerService`
1. Once inside the Cloud Shell terminal, run setup.sh. This should create a new Project with a single-node Kubernetes cluster that contains the prerequisites for the workshop:
    ```console
    ./setup.sh
    ```

The script will prompt you for a project name (just hit enter to accept the default) and a password for your webshell instances.

1. When the script is finished, verify it worked correctly.

```console
kubectl get pods --all-namespaces
```

The output should look similar to this:
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

If it looks good, move on to Scenario 1 Attack.
