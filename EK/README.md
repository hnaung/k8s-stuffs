## Elasticsearch Deployment 

Elasticsearch is deployed as a [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/), which is like
a Deployment, but allows for maintaining state on storage volumes.

```
kubectl create -f es-sevice.yaml -f es-deployment.yaml -f es-ingress.yaml
```
You can update your environment variables in the [deployment config](./es-deployment.yaml) if you got more requirements.  
```
        env:
          - name: node.name
            value: es
          - name: cluster.name
            value: escluster
          - name: cluster.initial_master_nodes
            value: es
          - name: ES_JAVA_OPTS
            value: "-Xms1g -Xmx1g"
```
Current ElasticSearch Pod used 20GB (EBS) Persistent Volume.
```
  volumeClaimTemplates:
  - metadata:
      name: elastic-data
      labels:
        app: elasticsearch
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 20Gi
```
### Kibana Deployment 

Kibana Deployment is very simple.
```
kubectl create -f kibana-deloyment.yaml -f kibana-svc.yaml -f kibana-ingress.yaml
```
To connect the Elastic Search Cluster, you'll need to update the environment in the deployment config.
```
    env:
      - name: ELASTICSEARCH_URL
        value: http://elasticsearch:9200
```

