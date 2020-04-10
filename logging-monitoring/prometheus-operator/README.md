## Prometheus-Operator
prometheus-operator
Installs prometheus-operator to create/configure/manage Prometheus clusters atop Kubernetes. 

The default installation is intended to suit monitoring a kubernetes cluster the chart is deployed onto. It closely matches the kube-prometheus project. This chart includes multiple components:

* prometheus-operator
* prometheus
* alertmanager
* node-exporter
* kube-state-metrics
* grafana
* service monitors to scrape internal kubernetes components
   - kube-dns/coredns 

`NOTE:  Other kubernetes Control Plane Default components such as (kube-{apiserver,schedular,controller-manager,etcd} won't be able to add in this monitoring box. Because Control Plane was managed by AWS.`

## Work-Arounds for Known Issues 

### `Helm fails to create CRDs`

Due to a bug in helm, it is possible for the 4 CRDs that are created by this chart to fail to get fully deployed before Helm attempts to create resources that require them. This affects all versions of Helm with a [potential fix pending](https://github.com/helm/helm/pull/5112). In order to work around this issue when installing the chart you will need to make sure all 4 CRDs exist in the cluster first and disable their previsioning by the chart:

#### 1. Create CRDs
```
kubectl apply -f ./crds/prometheus-operator-crd/alertmanager.crd.yaml
kubectl apply -f ./crds/prometheus.crd.yaml
kubectl apply -f ./crds/prometheusrule.crd.yaml
kubectl apply -f ./crds/servicemonitor.crd.yaml
```
#### 2. Wait for CRDs to be created, which should only take a few seconds.
```
kubectl get crds |grep -i monitoring
alertmanagers.monitoring.coreos.com     2019-06-26T02:13:56Z
prometheuses.monitoring.coreos.com      2019-06-26T02:13:58Z
prometheusrules.monitoring.coreos.com   2019-06-26T02:13:59Z
servicemonitors.monitoring.coreos.com   2019-06-26T02:14:00Z
```

#### 3. Install the chart by using custom values. This custom values will use persistent volumes dynamic provision method for `prometheus`,`grafana` & `alertmanager` pods. 
```
helm install --name prometheus -f ./custom-values.yaml stable/prometheus-operator --namespace logging-monitoring
```
```
 kubectl get pods -l release=prometheus --namespace logging-monitoring
NAME                                                  READY   STATUS    RESTARTS   AGE
prometheus-grafana-7594bd876-2b45n                    2/2     Running   0          10m
prometheus-kube-state-metrics-7b5fd6b8cd-gnrfs        1/1     Running   0          10m
prometheus-prometheus-node-exporter-56s42             1/1     Running   0          10m
prometheus-prometheus-node-exporter-l6brt             1/1     Running   0          12m
prometheus-prometheus-node-exporter-ntfnj             1/1     Running   0          11m
prometheus-prometheus-oper-operator-87979649c-h58z9   1/1     Running   0          12m
prometheus-prometheus-prometheus-oper-prometheus-0    3/3     Running   1          17m

```
#### 4. Creating Ingress rules
```
kubectl create -f ./ingress
ingress.extensions/alertmanager-ingress created
ingress.extensions/grafana-ingress created
ingress.extensions/prometheus-ingress created
```
```
kubectl get ing --namespace logging-monitoring                       
NAME                   HOSTS                                     ADDRESS         PORTS   AGE
alertmanager-ingress   alertmanager.staging.example.net   xx.xx.xx.xx   80,443      48m
grafana-ingress        grafana.staging.example.net        xx.xx.xx.xx   80,443      66m
prometheus-ingress     prometheus.staging.example.net     xx.xx.xx.xx   80,443      64m
```
