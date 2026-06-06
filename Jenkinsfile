pipeline {
    agent any

    triggers {
        githubPush()
    }

    stages {
        stage('Checkout Source') {
            steps {
                checkout scm
            }
        }

        stage('Deploy Multi-Container App to Fargate') {
            steps {
                withCredentials([file(credentialsId: 'aws-deployment-config-light', variable: 'INFRA_CONFIG')]) {
                    sh """
                    echo "⚙️ Loading base infrastructure configuration..."
                    set -a
                    . \$INFRA_CONFIG
                    set +a

                    AWS_ACCOUNT_ID=\$(echo "\${AWS_ROLE_ARN}" | cut -d':' -f5)
                    REGISTRY_URL="\${AWS_ACCOUNT_ID}.dkr.ecr.\${AWS_REGION}.amazonaws.com"
                    ECS_SVC="light-app-benchmark-jenkins"

                    echo "🚀 Logging into Amazon ECR..."
                    aws ecr get-login-password --region \${AWS_REGION} | docker login --username AWS --password-stdin \${REGISTRY_URL}

                    # =========================================
                    # 1️⃣ BUILD AND PUSH FRONTEND
                    # =========================================
                    echo "🏗️ Building Frontend..."
                    cd frontend
                    FRONTEND_REPO="resmetkelompok8lightapp-frontend"
                    FRONTEND_IMAGE="\${REGISTRY_URL}/\${FRONTEND_REPO}:\${GIT_COMMIT}"
                    
                    docker build -t \${FRONTEND_IMAGE} .
                    docker push \${FRONTEND_IMAGE}
                    cd .. # Go back to root

                    # =========================================
                    # 2️⃣ BUILD AND PUSH BACKEND
                    # =========================================
                    echo "🏗️ Building Backend..."
                    cd backend
                    BACKEND_REPO="resmetkelompok8lightapp"
                    BACKEND_IMAGE="\${REGISTRY_URL}/\${BACKEND_REPO}:\${GIT_COMMIT}"
                    
                    docker build -t \${BACKEND_IMAGE} .
                    docker push \${BACKEND_IMAGE}
                    cd .. # Go back to root

                    # =========================================
                    # 3️⃣ INJECT BOTH IMAGES & DEPLOY ONCE
                    # =========================================
                    echo "📋 Injecting Image URIs into task-definitions.json..."
                    
                    # ⚠️ MATCHING YOUR JSON: [0] is Backend, [1] is Frontend
                    jq "(.containerDefinitions[0]).image = \\"\${BACKEND_IMAGE}\\" | (.containerDefinitions[1]).image = \\"\${FRONTEND_IMAGE}\\"" ./task-definitions.json > updated-task-def.json

                    echo "🚀 Registering Task Revision & Updating Fargate Service..."
                    NEW_TASK_ARN=\$(aws ecs register-task-definition --cli-input-json file://updated-task-def.json --region \${AWS_REGION} --query 'taskDefinition.taskDefinitionArn' --output text)
                    
                    aws ecs update-service --cluster \${ECS_CLUSTER} --service \${ECS_SVC} --task-definition \${NEW_TASK_ARN} --region \${AWS_REGION}
                    
                    echo "✅ Multi-Container Deployment successful!"
                    
                    # Clean up
                    rm -f updated-task-def.json
                    """
                }
            }
        }
    }
}