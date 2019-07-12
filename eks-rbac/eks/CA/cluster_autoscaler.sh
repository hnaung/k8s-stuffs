#!/bin/bash



# Minimum and Maximum size of autoscaling group
MIN=2
MAX=8

# Get configuration from current autoscaling group
EKS_NAME=$(aws eks list-clusters --query "clusters[]" --output text)
ASG_JSON=$(aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[?Tags[?Value=='$EKS_NAME' && ends_with(Key,'cluster-name')]]")
ASG_NAME=`echo $ASG_JSON | jq -r .[].AutoScalingGroupName`
ASG_MIN=`echo $ASG_JSON | jq -r .[].MinSize`
ASG_MAX=`echo $ASG_JSON | jq -r .[].MaxSize`
ASG_DESIRED=`echo $ASG_JSON | jq -r .[].DesiredCapacity`

# Set auto-discovery
ASG_ENABLED=''
ASG_ENABLED=`echo $ASG_JSON | jq -r '.[].Tags[]|select(.Key=="k8s.io/cluster-autoscaler/enabled")|.Key'`
ASG_AUTODISCOVERY=''
ASG_AUTODISCOVERY=`echo $ASG_JSON | jq -r '.[].Tags[]|select(.Key=="k8s.io/cluster-autoscaler/'"$EKS_NAME"'")|.Key'`

if [ $ASG_ENABLED == '' ] || [ $ASG_AUTODISCOVERY == '' ]; then
    aws autoscaling create-or-update-tags --tags ResourceId=${ASG_NAME},ResourceType=auto-scaling-group,Key="k8s.io/cluster-autoscaler/enabled",Value="true",PropagateAtLaunch=true ResourceId=${ASG_NAME},ResourceType=auto-scaling-group,Key="kubernetes.io/cluster/${EKS_NAME}",Value="owned",PropagateAtLaunch=true
fi

# Set IAM policy for autoscaling
INSTANCE_ID=$(aws autoscaling describe-auto-scaling-instances --query "AutoScalingInstances[?AutoScalingGroupName=='$ASG_NAME']|[].InstanceId|[0]" --output text)
INSTANCE_PROFILE=$(aws ec2 describe-iam-instance-profile-associations --query "IamInstanceProfileAssociations[?InstanceId=='$INSTANCE_ID']|[].IamInstanceProfile.Arn" --output text | awk -F'/' '{print $2}')
INSTANCE_ROLE=$(aws iam get-instance-profile --instance-profile-name $INSTANCE_PROFILE --query "InstanceProfile.Roles[].RoleName" --output text) 
POLICY_INLINE='{"Version":"2012-10-17","Statement":[{"Action":["autoscaling:DescribeAutoScalingGroups","autoscaling:DescribeAutoScalingInstances","autoscaling:DescribeLaunchConfigurations","autoscaling:DescribeTags","autoscaling:SetDesiredCapacity","autoscaling:TerminateInstanceInAutoScalingGroup"],"Resource":"*","Effect":"Allow"}]}'
POLICY_NAME="`echo $INSTANCE_PROFILE | awk -F'-NodeInstanceProfile-' '{print $1}'`-PolicyAutoScaling"
aws iam put-role-policy --role-name $INSTANCE_ROLE --policy-name $POLICY_NAME --policy-document file://<(echo $POLICY_INLINE)

# Set new minimum and maximum numbers for autoscaling group
if [ $MIN -gt $ASG_MIN ]; then
    ASG_MIN=$MIN
fi
if [ $MAX -gt $ASG_MAX ]; then
    ASG_MAX=$MAX
fi

if [ $ASG_DESIRED -lt $ASG_MIN ]; then
    ASG_DESIRED=$ASG_MIN
fi
if [ $ASG_DESIRED -gt $ASG_MAX ]; then
    ASG_DESIRED=ASG_MAX
fi
aws autoscaling update-auto-scaling-group --auto-scaling-group-name $ASG_NAME --min-size $ASG_MIN --max-size $ASG_MAX --desired-capacity $ASG_DESIRED

# helm install
helm install stable/cluster-autoscaler --namespace kube-system --name aws-cluster-autoscaler --set autoDiscovery.clusterName=$EKS_NAME,sslCertPath=/etc/ssl/certs/ca-bundle.crt,cloudProvider=aws,awsRegion=$AWS_DEFAULT_REGION,rbac.create=true,autoscalingGroups[0].maxSize=$MAX,autoscalingGroups[0].minSize=$MIN

kubectl -n kube-system rollout status deployment aws-cluster-autoscaler
kubectl logs -f deployment/aws-cluster-autoscaler -n kube-system

