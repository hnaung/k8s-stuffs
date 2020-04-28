#!/bin/bash
set -x
# This script is ran on the admin machine
# Maintainer - Htet Naing Aung(unixaung@gmail.com)
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



