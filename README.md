# AWS - Infrastructure

## 1. How to Create VPC (Virtual Private Cloud) in AWS

This repo contains all Infrastructure resources that GourmetPlus needs to deploy it's system.

* [Create your VPC in AWS ](./tf_infra/aws-vpc/README.md)

## 2. How to Create Kubernetes Cluster (EKS) in AWS

* [Create your EKS Cluster in AWS ](./cluster-manifest/README.md)

* [Enable cluster auto scaler](./cluster-manifest/README.md)

## 3. How to create Nginx-Ingress Controller in EKS cluster

* Installing Helm



You may follow [Using Helm with Amazon EKS](https://docs.aws.amazon.com/eks/latest/userguide/helm.html) from the Amazon EKS official document or just follow the steps below:


```bash
# install helm cli 
$ curl -LO https://git.io/get_helm.sh
$ chmod +x get_helm.sh
$ ./get_helm.sh
$ helm init
$ helm repo update
```
# helm known issue #
```
$ helm ls
Error: configmaps is forbidden: User "system:serviceaccount:kube-system:default" cannot list resource "configmaps" in API group "" in the namespace "kube-system"
```
## Role-based Access Control

In Kubernetes, granting a role to an application-specific service account is a best practice to ensure that your application is operating in the scope that you have specified. Read more about service account permissions [in the official Kubernetes docs](https://kubernetes.io/docs/admin/authorization/rbac/#service-account-permissions).

Bitnami also has a fantastic guide for [configuring RBAC in your cluster](https://docs.bitnami.com/kubernetes/how-to/configure-rbac-in-your-kubernetes-cluster/) that takes you through RBAC basics.

This guide is for users who want to restrict Tiller's capabilities to install resources to certain namespaces, or to grant a Helm client running access to a Tiller instance.

## Tiller and Role-based Access Control

You can add a service account to Tiller using the `--service-account <NAME>` flag while you're configuring Helm. As a prerequisite, you'll have to create a role binding which specifies a [role](https://kubernetes.io/docs/admin/authorization/rbac/#role-and-clusterrole) and a [service account](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) name that have been set up in advance.
```
$kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default
clusterrolebinding.rbac.authorization.k8s.io/add-on-cluster-admin created
```


That's all!



* [Installing nlb-ingress-controllers with helm ](./nginx-ingress-controller/README.md)

## 4. How to create Gitlab RBAC for the CI/CD pipeline in EKS Cluster

* [Create your Gitlab Service Account in EKS cluster](./gitlab-eks-sa/README.md)


## 5. How to Create MySQL RDS Instance using Terraform
* [Create your MySQL RDS Instance with terraform](./tf_infra/aws-rds/README.md)

## 6. Deploy logging on EKS clusters using Fluentd and AWS CloudWatch Logs 
* [Fluentd Deployment and CloudWatch Logs Integration](./logging-monitoring/fluentd-cloudwatch/README.md)

## 7. Deploy Prometheus Monitoring 
* [Prometheus Operator Deployment with Persistent Volume](./logging-monitoring/prometheus-operator/README.md)

## 8. Deploy ElasticSearch & Kibana 
* [Elastic Search & Kibana Deployment](./EK/README.md)
