#!/bin/bash


cluster_name=${CLUSTER_NAME-gitlab-cluster}
nodes=${NUM_NODES-2}
kubernetes_version=${CLUSTER_VERSION-1.1}
region="${REGION-ap-southeast-2}"
instance_type="${MACHINE_TYPE-t2.micro}"
kubeconfig="${KUBECONFIG:-$HOME/.kube/config}"
gitlab_access_token="${MY_ACCESS_TOKEN-''}"

usage ()
{
  printf 'Usage   : setup-aws\n'
  printf 'Options : \n\t -c cluster-name\n\t -i instance-type\n\t -r region\n\t -t Gitlab Personal Access Token \n\t -n number-of-nodes\n'
  printf 'Default : \n name: gitlab-cluster type: t2.micro region: ap-southeast-2\n\n'
  exit
}

 post_variable(){
      local key="${1}"
      local value="${2}"
      curl -s --request POST --header "PRIVATE-TOKEN: ${MY_ACCESS_TOKEN}" "https://gitlab.com/api/v4/projects/26316511/variables" --form "key=${key}" --form "value=${value}" --form "masked=true" --form "protected=true"
}

 update_variable(){
      local key="${1}"
      local value="${2}"
      curl -s --request PUT --header "PRIVATE-TOKEN: ${MY_ACCESS_TOKEN}" "https://gitlab.com/api/v4/projects/26316511/variables/${key}" --form "value=${value}" --form "masked=true" --form "protected=true"
}

# https://docs.gitlab.com/ee/api/project_level_variables.html
 set_variable(){
      local key="${1}"
      local value="${2}"
      local test
      test=$(curl -f --request GET --header "PRIVATE-TOKEN: ${MY_ACCESS_TOKEN}" "https://gitlab.com/api/v4/projects/26316511/variables/${key}")
      if [ -z "$test" ]
      then
        post_variable "${key}" "${value}"
      else
        update_variable "${key}" "${value}"
      fi

}

while getopts c:n:k:r:i:t:s:h:K opt
do
  case "${opt}" in
    c)
      cluster_name="${OPTARG}"
      ;;
    n)
      nodes="${OPTARG}"
      ;;
    k)
      kubernetes_version="${OPTARG}"
      ;;
    i)
      instance_type="${OPTARG}"
      ;;
    r)
      region="${OPTARG}"
      ;;
    t)
      gitlab_access_token="${OPTARG}"
      ;;
    s)
      service_account="${OPTARG}"
      ;;
   h)
      usage
      ;;
  [?])
      usage
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

if [ -z "${gitlab_access_token}" ]
then
    >&2 echo "Please pass Gitlab Access Token to environment variable MY_ACCESS_TOKEN or include the token in program arguments with -t token"
fi

if ! eksctl get cluster -v 0 > /dev/null
then
  >&2 echo "Cannot connect to AWS. Ensure credentials are configured"
  exit 1
fi
    echo "Creating cluster..."
    #eksctl create cluster --name="${cluster_name}" --nodes="${nodes}" --node-type "${instance_type}" --region="${region}" --asg-access
    echo "Updating cluster config..."
    #aws eks update-kubeconfig --name "${cluster_name}"

    echo "Updating cluster service account for gitlab..."
    #kubectl apply -f gitlab-service-account.yaml

    echo "Updating gitlab environment variables..."

    AWS_ID=$(aws iam get-user | grep Id | awk -F \" '{ print $4 }' )

    set_variable "AWS_ID" "${AWS_ID}"

    if [ -z "${AWS_SECRET_ACCESS_KEY}" ]
    then
        KEY_JSON=$(aws iam create-access-key)

        AWS_SECRET_ACCESS_KEY=$(echo "$KEY_JSON" | grep -i secret | awk -F \" '{ print $4 }')

        AWS_ACCESS_KEY_ID=$(echo "$KEY_JSON" | grep -i keyid | awk -F \" '{ print $4 }')

    fi

    set_variable "AWS_SECRET_ACCESS_KEY" "${AWS_SECRET_ACCESS_KEY}"

    set_variable "AWS_ACCESS_KEY_ID" "${AWS_ACCESS_KEY_ID}"

    set_variable "AWS_DEFAULT_REGION" "${region}"

    set_variable "CLUSTER_NAME" "${cluster_name}"
