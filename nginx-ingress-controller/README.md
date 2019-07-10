### Nginx-Ingress Controller Deployment with customized values helm chart

Amazon EKS supports the Network Load Balancer and the Classic Load Balancer through the Kubernetes service of type LoadBalancer. The configuration of your load balancer is controlled by annotations that are added to the manifest ([values.yaml](https://gitlab.com/aung.naing/infrastructure/blob/master/helm/nginx-ingress-values.yaml)) for your service. By default, Classic Load Balancers are used for LoadBalancer type services. To use the Network Load Balancer instead, apply the following annotation to your service:

```shell
service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
```

In AWS we use a Network Load Balancer (NLB) to expose the NGINX Ingress controller behind a Service of Type=LoadBalancer. Since Kubernetes v1.9.0 it is possible to use a classic load balancer (ELB) or network load balancer (NLB) Please check the elastic load balancing [AWS details page](https://aws.amazon.com/elasticloadbalancing/details/)

In our case, there have two loadbalancers for each cluster (`Staging` & `Production`)
```shell
helm install stable/nginx-ingress --name public-lb --namespace kube-system --set controller.stats.enabled=true  --set controller.metrics.enabled=true --values public-lb-values.yaml
```
```shell
helm install stable/nginx-ingress --name private-lb --namespace kube-system --set controller.stats.enabled=true  --set controller.metrics.enabled=true --values private-lb-values.yaml
```
The difference between private and public LB configuration would be as follow. 

## Internal NLB (Private LB)
```
## Name of the ingress class to route through this controller
  ingressClass: private-lb
```
```
service:
    annotations: 
      service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
      service.beta.kubernetes.io/aws-load-balancer-internal: "0.0.0.0/0"
```
## Internet facing NLB (Public LB)
```
## Name of the ingress class to route through this controller
  ingressClass: public-lb
```
```
 service:
    annotations: 
      service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
```
NOTE: You need to define the `ingressClass` & `annotations` in your ingress rule yaml file to set which LB do you use for your application routing URL.
