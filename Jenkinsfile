pipeline {
    agent any

    environment {
        // 🛠️ DEFINE YOUR MICROSERVICES HERE
        // These names MUST match exactly with your folder names in GitHub
        // They should also match your ECR repository names and ECS service names
        SERVICES = "frontend backend" 
    }

    triggers {
        githubPush()
    }

    stages {
        stage('Checkout Source') {
            steps {
                checkout scm
            }
        }

        stage('Deploy Microservices to Fargate') {
            steps {
                withCredentials([file(credentialsId: 'aws-deployment-config-light', variable: 'INFRA_CONFIG')]) {
                    sh """
                    echo "⚙️ Loading base infrastructure configuration..."
                    set -a
                    . \$INFRA_CONFIG
                    set +a

                    # Extract the AWS Account ID from the Role ARN
                    AWS_ACCOUNT_ID=\$(echo "\${AWS_ROLE_ARN}" | cut -d':' -f5)
                    REGISTRY_URL="\${AWS_ACCOUNT_ID}.dkr.ecr.\${AWS_REGION}.amazonaws.com"

                    echo "🚀 Logging into Amazon ECR..."
                    aws ecr get-login-password --region \${AWS_REGION} | docker login --username AWS --password-stdin \${REGISTRY_URL}

                    # 🔄 LOOP THROUGH EACH MICROSERVICE
                    for SERVICE in \$SERVICES; do
                        echo "========================================="
                        echo "🏗️  STARTING DEPLOYMENT FOR: \$SERVICE"
                        echo "========================================="
                        
                        # Navigate into the microservice directory
                        cd \$SERVICE

                        # Define dynamic names based on the folder name
                        # We assume ECR repo is named 'light-app-[servicename]'
                        ECR_REPO="light-app-\${SERVICE}"
                        IMAGE_URI="\${REGISTRY_URL}/\${ECR_REPO}:\${GIT_COMMIT}"

                        echo "🔨 Packaging and Pushing Docker Image for \$SERVICE..."
                        docker build -t \${IMAGE_URI} .
                        docker push \${IMAGE_URI}

                        echo "📋 Injecting new Image URI into \$SERVICE task-definition.json..."
                        jq "(.containerDefinitions[0]).image = \\"\${IMAGE_URI}\\"" ./task-definition.json > updated-task-def.json

                        echo "🚀 Registering Task Revision & Updating Fargate Service..."
                        NEW_TASK_ARN=\$(aws ecs register-task-definition --cli-input-json file://updated-task-def.json --region \${AWS_REGION} --query 'taskDefinition.taskDefinitionArn' --output text)
                        
                        # We assume your ECS Service is named exactly the same as the folder name
                        aws ecs update-service --cluster \${ECS_CLUSTER} --service \${SERVICE} --task-definition \${NEW_TASK_ARN} --region \${AWS_REGION}
                        
                        echo "✅ \$SERVICE Deployment successful!"
                        
                        # Clean up and step back to the root directory for the next loop iteration
                        rm -f updated-task-def.json
                        cd ..
                    done
                    
                    echo "🎉 All microservices deployed successfully!"
                    """
                }
            }
        }
    }
}