### Using Config Files

You can create a cluster using a config file instead of using one command line.

For example:
First, create `cluster.yaml` file:
```yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: gplus-cluster
  region: ap-southeast-2

nodeGroups:
  - name: ng-1
    instanceType: t3.medium
    desiredCapacity: 3
    allowSSH: true
    sshPublicKeyPath:  '$ssh-key-name'
  - name: ng-2
    instanceType: t3.large
    desiredCapacity: 2
    allowSSH: true
    sshPublicKeyPath:  '$ssh-key-name'
```

Next, run this command:
```
eksctl create cluster -f cluster.yaml
```

This will create a cluster as described.

If you needed to use an existing VPC, you can use a config file like this:
```yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: cluster-in-existing-vpc
  region: ap-southeast-2

vpc:
  subnets:
    private:
      ap-southeast-2a: {id: subnet-xxxxx}
      ap-southeast-2b: {id: subnet-xxxxx}
      ap-southeast-2c: {id: subnet-xxxxx}

nodeGroups:
  - name: ng-1-workers
    labels: {role: workers}
    instanceType: t3.medium
    desiredCapacity: 3
    privateNetworking: true
  - name: ng-2-builders
    labels: {role: builders}
    instanceType: t3.large
    desiredCapacity: 2
    privateNetworking: true
    iam:
      withAddonPolicies:
        imageBuilder: true
```

To delete this cluster, run:
```
eksctl delete cluster -f cluster.yaml
```
In our case, there have two configurations for staiging and production cluster creation. 

```
eksctl create cluster -f staging-cluster.yaml
```
```
eksctl create cluster -f prod-cluster.yaml
```


See [`examples/`](https://github.com/weaveworks/eksctl/tree/master/examples) directory for more sample config files.
 
### Enable Autoscaling

You can create a cluster (or nodegroup in an existing cluster) with IAM role that will allow use of [cluster autoscaler][]:

```
kubectl apply -f cluster-autoscaler-autodiscover.yaml
```
Just need to update the config in this yaml file as follow.
```
--
--node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/$EKS_CLUSTER_NAME
--
--
--
env:
- name: AWS_REGION
  value: "$AWS_REGION"
--
```
### Usage

$AWS_REGION = your aws region (ap-southeast-2)

$EKS_CLUSTER_NAME = your cluster name (gplus-cluster)

Once cluster is running, you will need to install [cluster autoscaler][] itself. This flag also sets `k8s.io/cluster-autoscaler/enabled`
and `k8s.io/cluster-autoscaler/<clusterName>` tags, so nodegroup discovery should work.

[cluster autoscaler]: https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md



