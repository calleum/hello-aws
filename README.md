# Java spring-boot hello-world

## CI/CD with gitlab and deployment with helm kubernetes on eks.

### To Run:

Dependencies:
- awscli: ``` curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install ```
- eksctl: ``` curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin ```
- kubectl: ``` curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" ```

Run ``` aws configure ``` and input your aws credentials.

Create a personal access token with api access to programmatically add variables to your project: [Personal Access Tokens Doc](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html)

The default region is ap-southeast-2 and instance t2.micro.

```
# Fork then clone to run within your own project.
# e.g.
git clone git@gitlab.com:calleum/hello-aws.git

cd hello-aws

# Ensure that awscli and personal access token are configured!

./setup-aws.sh

# You can now interact with your kubernetes cluster with kubectl e.g.

kubectl get pods --all-namespaces -o wide

# To tear down the cluster and nodes:

eksctl delete cluster --name my-cluster --region us-west-2

```
