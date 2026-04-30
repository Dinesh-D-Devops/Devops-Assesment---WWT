# Devops-Assesment---WWT - -1

Hey there! This repository contains my submission for the Mindmeld DevOps exercise. 

The goal was to take the provided React/Rust stack and get it running on AWS in a way that actually makes sense for a production environment. Instead of just spinning up a few EC2 instances, I opted for a modern, containerized approach using EKS, Terraform, and Jenkins.

## The Architecture TL;DR

*   **Frontend:** The React app is built as a static site and hosted on S3. It's served globally via CloudFront.
*   **Backend:** The Rust API is containerized (using a multi-stage Docker build to keep the image tiny) and runs on an Amazon EKS cluster. Traffic gets routed to the pods via an Application Load Balancer (ALB).
*   **Database:** A managed ElastiCache Redis instance handles the key-value storage.
*   **Infrastructure:** Everything from the VPC to the CloudFront distribution is codified using Terraform.

## Key Design Decisions

When putting this together, I focused on a few core principles:

### 1. Security First (Private by Default)
Nothing touches the public internet unless it absolutely has to. The EKS worker nodes and the Redis database are tucked away in private subnets and use a NAT Gateway for outbound traffic. 

I also locked down the S3 bucket completely. The frontend files are only accessible through CloudFront using Origin Access Control (OAC). For the database, the Redis Security Group only accepts ingress traffic on port 6379 if it originates from the EKS node Security Group.

### 2. Ready to Scale
Because the Rust API relies entirely on Redis for state, the backend pods are completely stateless. This means we can easily throw a Horizontal Pod Autoscaler (HPA) at the Kubernetes deployment to handle traffic spikes without worrying about data consistency. 

### 3. CI/CD Automation
Nobody likes manual deployments. I included a `Jenkinsfile` at the root of the repo that handles the entire pipeline: building the React app, dockerizing the API, pushing to ECR, applying the Terraform state, and deploying the Kubernetes manifests. 

## What's in this repo?

*   `api/` - The Rust backend and its multi-stage `Dockerfile`.
*   `app/` - The React frontend.
*   `terraform/` - The AWS infrastructure code (VPC, EKS, Redis, ECR, S3, CloudFront).
*   `kubernetes/` - The k8s manifests to deploy the API and wire up the ALB Ingress.
*   `Jenkinsfile` - The CI/CD pipeline.

## How to deploy this yourself

If you want to spin this up in your own AWS account, you'll need the AWS CLI, Terraform, `kubectl`, and Docker installed.

### 1. Stand up the Infrastructure
First, we need the AWS resources.
1. `cd terraform`
2. `terraform init`
3. `terraform plan`
4. `terraform apply`

*Make sure to grab the CloudFront URL and the ECR repo URL from the Terraform outputs when this finishes.*

### 2. Build and Deploy (The Manual Route)
If you aren't running this through Jenkins, here is how to deploy the apps manually:

**The Backend:**
1. Log in to ECR: `aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <YOUR_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com`
2. Build the image: `docker build -t mindmeld-api ./api`
3. Tag and push it to the ECR repo Terraform just created.
4. Update your local kubeconfig: `aws eks update-kubeconfig --region us-east-1 --name mindmeld-eks-cluster`
5. In `kubernetes/deployment.yaml`, swap out the placeholder strings with your actual ECR Image URI and the Redis endpoint from the Terraform outputs.
6. Apply the manifests: `kubectl apply -f kubernetes/`

**The Frontend:**
1. In `app/src/config.json`, change the API URL to the address of the ALB that Kubernetes just spun up.
2. Run `npm install` and `npm run build` inside the `app/` directory.
3. Sync the build folder to the new S3 bucket: `aws s3 sync build/ s3://<YOUR_TERRAFORM_BUCKET_NAME> --delete`
4. You're good to go! Hit the CloudFront URL in your browser.
