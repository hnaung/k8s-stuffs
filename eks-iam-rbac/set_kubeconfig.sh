#!/bin/bash
# Maintainer - Htet Naing Aung (unixaung@gmail.com)
# This is run on the team members' machines, please export/set their AWS credentials first

if ! aws --version > /dev/null 2>&1; then 
    echo "Please install AWS command line first";
    exit
fi

#if [[ -z "${AWS_SECRET_ACCESS_KEY}" ]] && [[ "${AWS_SECRET_ACCESS_KEY}" == '' ]] ; then
#    echo "Please export/set AWS credentials first"
#    exit
#fi

#if [[ -z "${AWS_DEFAULT_REGION}" ]] && [[ "${AWS_DEFAULT_REGION}" == '' ]] ; then
#    echo "You must specify a AWS region"
#    exit
#fi

if [ -z "$1" ]; then
    read -p 'Which IAM group do you belong to: ' GROUP
else
    GROUP=$1
fi


# Download aws-iam-authenticator
if ! aws-iam-authenticator version > /dev/null 2>&1; then 
    mkdir -p $HOME/bin/
    if [ "$(uname)" == "Darwin" ]; then
        curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.11.5/2018-12-06/bin/darwin/amd64/aws-iam-authenticator
        chmod +x ./aws-iam-authenticator
        mv ./aws-iam-authenticator $HOME/bin/aws-iam-authenticator && export PATH=$HOME/bin:$PATH
        echo 'export PATH=$HOME/bin:$PATH' >> ~/.bash_profile
    else
        curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.11.5/2018-12-06/bin/linux/amd64/aws-iam-authenticator
        chmod +x ./aws-iam-authenticator
        mv ./aws-iam-authenticator $HOME/bin/aws-iam-authenticator && export PATH=$HOME/bin:$PATH
        echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
    fi
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${GROUP}_role"

# Get EKS cluster name
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
aws eks update-kubeconfig --name $EKS_NAME --role-arn $ROLE_ARN

