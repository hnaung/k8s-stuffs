### CloudWatch Log Group

A CloudWatch log group combines log streams that share the same retention, monitoring, and access control settings.

Create a CloudWatch log group:
```
aws logs create-log-group --log-group-name gplus-staging-eks
```
### Deploy Fluentd

* Configure Log group name and log stream name

Fluentd log group name and stream name are configured in the file `fluentd-configmap.yaml`. An excerpt from the file is shown:
```
    output.conf: |
      <match **>
        # Plugin specific settings
        type cloudwatch_logs
        log_group_name kubernetes-logs
        log_stream_name fluentd-cloudwatch
        auto_create_stream true
        # Buffer settings
        buffer_chunk_limit 2M
        buffer_queue_limit 32
        flush_interval 10s
        max_retry_wait 30
        disable_retry_limit
        num_threads 8
      </match>
```
It uses the default log group name of `gplus-staging-eks` and the log stream name of `k8s-pods`.

If you've followed the instructions in this chapter as is, then no change is required in this configuration file. However if a different log group name is used in the previous command or a different log stream name is needed, then that needs to be configured in this configuration file.

### IAM configuration

You will need to create an IAM user and set the `AWS_ACCESS_KEY`, `AWS_SECRET_KEY` and `AWS_REGION` in the `fluentd-ds.yaml` file. 

```
  env:
  - name: FLUENTD_CONFIG
    value: fluentd-standalone.conf
  - name: AWS_REGION
    value: ap-southeast-2
  - name: AWS_ACCESS_KEY
    valueFrom:
      secretKeyRef:
        name: aws-secret
        key: aws_access_key
  - name: AWS_SECRET_KEY
    valueFrom:
      secretKeyRef:
        name: aws-secret
        key: aws_secret_key
```
### Creating a Secret Manually
For example, to store two strings in a Secret using the data field, convert them to base64 as follows:

```
echo -n '$aws_access_key_id' | base64
xxxxxxxxxxxxxxxxx
echo -n '$aws_secret_access_key' | base64
xxxxxxxxxxxxxxxxx
```

Let's create kubernetes secret for `AWS_ACCESS_KEY` & `AWS_SECRET_KEY`.

```
apiVersion: v1
kind: Secret
metadata:
  name: aws-secret
  namespace: logging-monitoring
type: Opaque
data:
  aws_access_key: xxxxxxxxxxxxxxxxx 
  aws_secret_key: xxxxxxxxxxxxxxxxx
```
```
kubectl create -f ./aws-secret.yaml
secret/aws-secret created
````

Create an IAM policy name with "fluentd-cloudwatch" as follow.
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "logs",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams"
            ],
            "Resource": [
                "arn:aws:logs:*:*:*"
            ]
        }
    ]
}
```
Then attach this policy to the Worker Node IAM Roles (`eksctl-gplus-staging-eks-nodegroup-NodeInstanceRole-XXXXXX`).

## Create Kubernetes resources

First create the logging namespace

    $ kubectl create ns logging-monitoring
    namespace "logging-monitoring" created

Create all of the necessary service accounts and roles for fluentd (logging-agent):

    $ kubectl create -f ./fluentd-service-account.yaml
    serviceaccount "fluentd" created
    $ kubectl create -f ./fluentd-role.yaml
    clusterrole "fluentd-read" created
    $ kubectl create -f ./fluentd-role-binding.yaml
    clusterrolebinding "fluentd-read" created

Then deploy Fluentd:

    $ kubectl create -f ./fluentd-configmap.yaml
    configmap "fluentd-config" created
    $ kubectl create -f ./fluentd-svc.yaml
    service "fluentd" created
    $ kubectl create -f ./fluentd-ds.yaml
    daemonset "fluentd" created

Watch for all of the pods to change to running status:

    $ kubectl get pods -w --namespace=logging-monitoring
    NAME            READY     STATUS    RESTARTS   AGE
    fluentd-rjtq9   1/1       Running   0          44s
    fluentd-s2pzh   1/1       Running   0          44s

Remember, Fluentd is deployed as a DaemonSet, i.e. one pod per worker node, so your output will vary depending on the size of your cluster. In our case, a 2 node cluster is used and so 2 pods are shown in the output.

We can now login to the AWS console -> Management Tools -> CloudWatch -> Logs -> gplus-staging-eks -> k8s-pods

We should start to see logs arrive into the service and can use the search feature to looks for specific logs. 


