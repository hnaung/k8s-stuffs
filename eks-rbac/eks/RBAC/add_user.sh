#!/bin/bash

# This script is ran on the admin machine

if ! aws --version > /dev/null 2>&1; then 
    echo "Please install AWS command line first ";
    exit
fi

#if [[ -z "${AWS_SECRET_ACCESS_KEY}" ]] && [[ "${AWS_SECRET_ACCESS_KEY}" == '' ]] ; then
#    echo "Please export/set AWS credentials first"
#    exit
#fi


if [ -z "$1" ]; then
    read -p 'Which userlist file do you want to import: ' FILENAME
else
    FILENAME=$1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
ASSUME_POL="{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::${ACCOUNT_ID}:root\"},\"Action\":\"sts:AssumeRole\"}]}"

# Set IAM groups and roles
cat $FILENAME  | grep -Ev '^#|^$' | while read LINE; do
    echo $LINE
    ARR=(${LINE//:/ })  
    GROUP=${ARR[0]}
    USER=${ARR[1]}

    FOUND=''
    FOUND=$(aws iam list-users --query "Users[?UserName=='$USER']" --output text)
    if [[ -z $FOUND ]] || [[ $FOUND == '' ]]; then
        echo "creating user..."
        aws iam create-user --user-name $USER
    fi

    FOUND=''
    FOUND=$(aws iam list-roles --query "Roles[?RoleName=='${GROUP}_role']" --output text)
    if [[ -z $FOUND ]] || [[ $FOUND == '' ]]; then
        echo "creating role..."
        aws iam create-role --role-name ${GROUP}_role --assume-role-policy-document file://<(echo $ASSUME_POL)
    fi   

    FOUND=''
    FOUND=$(aws iam list-groups --query "Groups[?GroupName=='$GROUP']" --output text)
    if [[ -z $FOUND ]] || [[ $FOUND == '' ]]; then
        echo "creating group..."
        aws iam create-group --group-name $GROUP
    fi

    ASSUME_GRP_POL="{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Resource\":\"arn:aws:iam::${ACCOUNT_ID}:role/${GROUP}_role\"}]}"
    aws iam put-group-policy --group-name $GROUP --policy-name "Assume_${GROUP}_Role" --policy-document file://<(echo $ASSUME_GRP_POL)


    EKS_POL='{"Version":"2012-10-17","Statement":[{"Sid":"VisualEditor0","Effect":"Allow","Action":["eks:DescribeCluster","eks:ListClusters"],"Resource":"*"}]}'
    aws iam put-group-policy --group-name $GROUP --policy-name "EKS_READONLY" --policy-document file://<(echo $EKS_POL)


    FOUND=''
    FOUND=$(aws iam list-groups-for-user --user-name $USER --query "Groups[?GroupName=='$GROUP']" --output text)
    if [[ -z $FOUND ]] || [[ $FOUND == '' ]]; then
        echo "joining group..."
        aws iam add-user-to-group --group-name $GROUP --user-name $USER
    fi
done

#Get EKS cluster name
EKS_ARRAY=($(aws eks list-clusters --query "clusters[]" --output text))
EKS_NAME=''
if [[ "${#EKS_ARRAY[@]}" -gt 1 ]]; then
    REPLY=''
    select opt in "${EKS_ARRAY[@]}"; do
        if [[ $REPLY != '' ]] && [[ $opt != '' ]]; then
            echo $REPLY "|" $opt
            EKS_NAME=$opt
            break;
        fi
    done
elif [[ "${#EKS_ARRAY[@]}" -eq 0 ]]; then
    echo "Can't find EKS cluster name, did you specify the correct AWS region?"
    exit
else
    EKS_NAME="${EKS_ARRAY[0]}"
fi

echo "EKS_NAME=$EKS_NAME"
aws eks update-kubeconfig --name $EKS_NAME

ROLE_ARN=$(aws eks describe-cluster --name $EKS_NAME --query "cluster.roleArn" --output text)
#kubectl get configmap aws-auth -n kube-system > /dev/null
#if [ $? -gt 0 ]; then
    curl -O https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/2019-01-09/aws-auth-cm.yaml
    sed -i.bak -e 's|<ARN of instance role (not instance profile)>|'"${ROLE_ARN}"'|g' aws-auth-cm.yaml
    kubectl apply -f aws-auth-cm.yaml
    #rm -f aws-auth-cm.*
#fi

# Add IAM roles to K8S RBAC
NL=$'\n'
PREFIX="- groups:${NL}  - system:bootstrappers${NL}  - system:nodes${NL}  rolearn: ${ROLE_ARN}${NL}  username: system:node:{{EC2PrivateDNSName}}${NL}"
while read LINE; do
    echo $LINE
    ARR=(${LINE//:/ })  
    GROUP=${ARR[0]}
    ENVIRONMENT=${ARR[2]}
    PERMISSION=${ARR[3]}
    ATTACH="- groups:${NL}  - ${GROUP}-${PERMISSION}${NL}  rolearn: arn:aws:iam::${ACCOUNT_ID}:role/${GROUP}_role${NL}  username: ${USER}:{{SessionName}}${NL}"
    PREFIX=`echo "${PREFIX}${NL}${NL}${ATTACH}${NL}"`
done <<< `cat $FILENAME | grep -Ev '^#|^$'` 
#printf '%s\n' "$PREFIX"
kubectl create configmap aws-auth -n kube-system --from-literal="mapRoles=`printf '%s\n' "${PREFIX}"`" --dry-run -o yaml | kubectl replace -f -

#kubectl get configmap aws-auth -n kube-system -o json > aws-auth.json
#cat aws-auth.json | jq ".data.mapRoles = \"${PREFIX}\"" | kubectl replace -f -
#kubectl create configmap aws-auth -n kube-system --from-literal="mapRoles=data" --dry-run -o json | jq ".data.mapRoles = \"${PREFIX}\"" | kubectl replace -f 


# Rolebinding with K8S permissions
IAM_GROUPS=(`awk -F":" '{print $1"|"$3"|"$4}' $FILENAME | grep -Ev '^#|^$|^\|' | sort -u`)
for IAM_GRP in "${IAM_GROUPS[@]}"; do
    echo $IAM_GRP
    ARR=(${IAM_GRP//|/ })  
    GROUP=${ARR[0]}
    ENVIRONMENT=${ARR[1]}
    PERMISSION=${ARR[2]}
    if [[ $ENVIRONMENT == 'default' ]]; then
        kubectl create clusterrolebinding ${GROUP}-${PERMISSION}-cluster-rolebinding --group=${GROUP}-${PERMISSION} --clusterrole=${PERMISSION}
    else
	    kubectl delete rolebinding ${GROUP}-${PERMISSION}-rolebinding --namespace=${ENVIRONMENT}
        kubectl delete rolebinding ${GROUP}-staging-${PERMISSION}-rolebinding --namespace=${ENVIRONMENT}
        kubectl delete rolebinding ${GROUP}-production-${PERMISSION}-rolebinding --namespace=${ENVIRONMENT} 
         kubectl create clusterrolebinding gplus-eks-admin --clusterrole=admin --group gplus-eks-admin
        kubectl create rolebinding ${GROUP}-dev-${PERMISSION}-rolebinding --namespace=${ENVIRONMENT} --group=${GROUP}-${PERMISSION} --clusterrole=${PERMISSION}
        kubectl create rolebinding ${GROUP}-staging-${PERMISSION}-rolebinding --namespace=${ENVIRONMENT}-staging --group=${GROUP}-${PERMISSION} --clusterrole=${PERMISSION}
        kubectl create rolebinding ${GROUP}-production-${PERMISSION}-rolebinding --namespace=${ENVIRONMENT}-production --group=${GROUP}-${PERMISSION} --clusterrole=${PERMISSION}
    fi
done


