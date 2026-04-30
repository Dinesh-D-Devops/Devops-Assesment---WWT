pipeline {
    agent any

    environment {
        AWS_REGION     = 'us-east-1'
        ECR_REPO       = 'mindmeld-api'
        IMAGE_TAG      = "${env.BUILD_ID}"
        CLUSTER_NAME   = 'mindmeld-eks-cluster'
    }

    stages {
        stage('Build Frontend (React)') {
            steps {
                dir('app') {
                    sh 'npm install'
                    sh 'npm run build'
                    // In a full implementation, you would sync this build folder to your S3 bucket here
                    // sh 'aws s3 sync build/ s3://your-frontend-bucket-name --delete'
                }
            }
        }

        stage('Build & Push Backend (Rust API)') {
            steps {
                dir('api') {
                    // Authenticate Docker to AWS ECR
                    sh 'aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com'
                    
                    // Build the multi-stage Docker image
                    sh 'docker build -t $ECR_REPO:$IMAGE_TAG .'
                    
                    // Tag and push to ECR
                    sh 'docker tag $ECR_REPO:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG'
                    sh 'docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG'
                }
            }
        }

        stage('Provision Infrastructure (Terraform)') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                    sh 'terraform apply -auto-approve'
                    
                    // Extract the Redis endpoint to pass to Kubernetes
                    script {
                        env.REDIS_ENDPOINT = sh(script: 'terraform output -raw redis_endpoint', returnStdout: true).trim()
                    }
                }
            }
        }

        stage('Deploy to Kubernetes (EKS)') {
            steps {
                dir('kubernetes') {
                    // Update kubeconfig to interact with the EKS cluster
                    sh 'aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME'

                    // Inject the dynamic variables into the deployment file
                    sh "sed -i 's|REPLACE_ME_ECR_URI|'$AWS_ACCOUNT_ID'.dkr.ecr.'$AWS_REGION'.amazonaws.com/'$ECR_REPO'|g' deployment.yaml"
                    sh "sed -i 's|REPLACE_ME_REDIS_ENDPOINT|'$REDIS_ENDPOINT'|g' deployment.yaml"

                    // Apply the manifests
                    sh 'kubectl apply -f deployment.yaml'
                    sh 'kubectl apply -f service.yaml'
                    sh 'kubectl apply -f ingress.yaml'
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline execution complete.'
        }
        success {
            echo 'Deployment successful! The Mindmeld app is live.'
        }
        failure {
            echo 'Pipeline failed. Check the logs for errors.'
        }
    }
}
