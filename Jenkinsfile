pipeline {
    agent any

    environment {
        // These MUST match the exact folder names in your GitHub repository
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

                    # 🔄 LOOP THROUGH EACH MICROSERVICE FOLDER
                    for SERVICE in \$SERVICES; do
                        echo "========================================="
                        echo "🏗️  STARTING DEPLOYMENT FOR: \$SERVICE"
                        echo "========================================="
                        
                        # Navigate into the microservice directory
                        cd \$SERVICE

                        # 🎯 THE TRANSLATOR: Map folders to exact AWS Resource Names
                        if [ "\$SERVICE" = "frontend" ]; then
                            ECR_REPO="resmetkelompok8lightapp-frontend"
                            ECS_SVC="resmetkelompok8lightapp-frontend" # Update this if your ECS Service has a different name!
                            
                        elif [ "\$SERVICE" = "backend" ]; then
                            ECR_REPO="resmetkelompok8lightapp"
                            ECS_SVC="resmetkelompok8lightapp" # Update this if your ECS Service has a different name!
                            
                        else
                            echo "❌ Unknown service folder: \$SERVICE"
                            exit 1
                        fi

                        IMAGE_URI="\${REGISTRY_URL}/\${ECR_REPO}:\${GIT_COMMIT}"

                        echo "🔨 Packaging and Pushing Docker Image for \$SERVICE..."
                        docker build -t \${IMAGE_URI} .
                        docker push \${IMAGE_URI}

                        echo "📋 Injecting new Image URI into \$SERVICE task-definition.json..."
                        jq "(.containerDefinitions[0]).image = \\"\${IMAGE_URI}\\"" ./task-definition.json > updated-task-def.json

                        echo "🚀 Registering Task Revision & Updating Fargate Service..."
                        NEW_TASK_ARN=\$(aws ecs register-task-definition --cli-input-json file://updated-task-def.json --region \${AWS_REGION} --query 'taskDefinition.taskDefinitionArn' --output text)
                        
                        aws ecs update-service --cluster \${ECS_CLUSTER} --service \${ECS_SVC} --task-definition \${NEW_TASK_ARN} --region \${AWS_REGION}
                        
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