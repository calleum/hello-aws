#!/bin/sh

#gitlab-service-account=`cat gitlab-service-account.yaml`

set -e

cluster_name=${CLUSTER_NAME-gitlab-cluster}
nodes=${NUM_NODES-2}
kubernetes_version=${CLUSTER_VERSION-1.1}
region="${REGION-ap-southeast-2}"
instance_type="${MACHINE_TYPE-t2.micro}"
kubeconfig="${KUBECONFIG:-$HOME/.kube/config}"
gitlab_access_token="${MY_ACCESS_TOKEN}-""}"
#service_account="${SERVICE_ACCOUNT-tiller}"

usage ()
{
  printf 'Usage   : setup-aws'
  printf 'Options : \n\t -c cluster-name\n\t -i instance-type\n\t -r region\n\t -t Gitlab Personal Access Token \n\t -n number-of-nodes'
  printf 'Default : \n\t name: gitlab-cluster type: t2.micro region: ap-southeast-2\n\n'
  exit
}

while getopts c:n:k:r:i:t:s:K opt
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
    K)
      kubeconfig="${OPTARG}"
      ;;
  [?])
      usage
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

if [ "${gitlab_access_token}" = "" ]
then
    >&2 echo "Please pass Gitlab Access Token to environment variable MY_ACCESS_TOKEN or include the token in program arguments with -t token"
fi

if ! eksctl get cluster -v 0 > /dev/null
then
  >&2 echo "Cannot connect to AWS. Ensure credentials are configured"
  exit 1
fi
    echo "Creating cluster..."
    eksctl create cluster --name="${cluster_name}" --nodes="${nodes}" --node-type "${instance_type}" --region="${region}"
    echo "Updating cluster config..."
    aws eks update-kubeconfig --name "${cluster_name}"

    echo "Updating cluster service account for gitlab..."
    kubectl apply -f gitlab-service-account.yaml


    ## Possibly need to create tiller service account here ##

    helm init --service-account gitlab-service-account

    SECRET="$(kubectl get secrets | grep default-token| awk '{print $1}')"
    CA="$(kubectl get secret "$SECRET" -o jsonpath="{['data']['ca\.crt']}" | base64 -D)"

    echo "Updating gitlab environment variables..."
    curl --request PUT --header "PRIVATE-TOKEN: ${MY_ACCESS_TOKEN}" "https://gitlab.com/api/v4/projects/26316511/variables" --form "key=CERTIFICATE_AUTHORITY_DATA" --form "value=${CA}" --form "masked=true" --form "protected=true" |  awk -F \" '/error/ { print $2 }'

       ENDPOINT="$(aws eks describe-cluster --region "${region}" --name "${cluster-name}" 2> /dev/null | awk '/endpoint/{print $2}' | sed 's/"//g' | sed 's/,//')"


    curl --request PUT --header "PRIVATE-TOKEN: ${MY_ACCESS_TOKEN}" "https://gitlab.com/api/v4/projects/26316511/variables" --form "key=SERVER" --form "value=${ENDPOINT}" --form "masked=true" |  awk -F \" '/error/ { print $2 }'

    GITLAB_SECRET="$(kubectl get secrets | grep gitlab-service-account-token| awk '{print $1}')"

    G_TOKEN="$(kubectl describe secret "$GITLAB_SECRET")"

    curl --request PUT --header "PRIVATE-TOKEN: ${MY_ACCESS_TOKEN}" "https://gitlab.com/api/v4/projects/26316511/variables" --form "key=USER_TOKEN" --form "value=${G_TOKEN}" --form "masked=true" --form "protected=true" |  awk -F \" '/error/ { print $2 }'

    KEY_JSON=$(aws iam create-access-key)

    AWS_SECRET_ACCESS_KEY=$(echo "$KEY_JSON" | grep -i secret | awk -F \" '{ print $4 }')

    AWS_ACCESS_KEY_ID=$(echo "$KEY_JSON" | grep -i keyid | awk -F \" '{ print $4 }')
)
    AWS_DEFAULT_REGION=${region}


    curl --request PUT --header "PRIVATE-TOKEN: ${MY_ACCESS_TOKEN}" "https://gitlab.com/api/v4/projects/26316511/variables" --form "key=AWS_SECRET_ACCESS_KEY" --form "value=${AWS_SECRET_ACCESS_KEY}" --form "masked=true" --form "protected=true" |  awk -F \" '/error/ { print $2 }'

    curl --request PUT --header "PRIVATE-TOKEN: ${MY_ACCESS_TOKEN}" "https://gitlab.com/api/v4/projects/26316511/variables" --form "key=AWS_ACCESS_KEY_ID" --form "value=${AWS_SECRET_ACCESS_KEY}" --form "masked=true" --form "protected=true" |  awk -F \" '/error/ { print $2 }'

    curl --request PUT --header "PRIVATE-TOKEN: ${MY_ACCESS_TOKEN}" "https://gitlab.com/api/v4/projects/26316511/variables" --form "key=AWS_DEFAULT_REGION" --form "value=${AWS_DEFAULT_REGION}" --form "masked=true" --form "protected=true"|  awk -F \" '/error/ { print $2 }'
