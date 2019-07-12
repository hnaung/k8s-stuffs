.
├── CA
│   ├── EKS\ Cluster\ Autoscaling.docx
│   └── cluster_autoscaler.sh
└── RBAC
    ├── K8S_RBAC.docx
    ├── add_user.sh
    ├── set_kube.sh
    └── users_list.txt


1. CA is for Cluster Autoscaling, run the cluster_autoscaler.sh will install the CA to the EKS
2. RBAC is for EKS IAM authencation integration
- 2.1 users_list.txt  	user list file, add users and its group, permission to this file
- 2.2 add_user.sh  	run the script on cluster-admin's machine, this will add user & groups to IAM and set rolebinding to EKS
- 2.3 set_kube.sh 	run this script on team members' machines, this will add the EKS configuration automatically


* All the script needs to use AWS Commandline, please install and make proper configuration before run the script
