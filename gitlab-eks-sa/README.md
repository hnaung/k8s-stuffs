### Create Gitlab Service Account and Clusterrolebinding for the CI/CD pipeline in EKS Cluster

```shell
kubectl create -f eks-admin-sa.yaml -f eks-admin-clusterrolebinding.yaml
```