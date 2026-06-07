pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        ACR_NAME              = 'benchmarkacrkel8'
        RG_NAME               = 'benchmark-apps-rg'
        FRONTEND_APP_NAME     = 'light-app-frontend'
        BACKEND_APP_NAME      = 'light-app-service'
    }

    stages {
        stage('Checkout Source') {
            steps {
                checkout scm
            }
        }

        stage('Build & Push Images to ACR') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'ACR_CREDENTIALS', passwordVariable: 'ACR_PASSWORD', usernameVariable: 'ACR_USER')]) {
                    sh """
                    echo "🚀 Logging into Azure Container Registry..."
                    docker login \${ACR_NAME}.azurecr.io -u \${ACR_USER} -p \${ACR_PASSWORD}

                    # =========================================
                    # 1️⃣ BUILD AND PUSH FRONTEND
                    # =========================================
                    echo "🏗️ Building Frontend..."
                    cd frontend
                    FRONTEND_IMAGE="\${ACR_NAME}.azurecr.io/\${FRONTEND_APP_NAME}:\${GIT_COMMIT}"
                    
                    docker build -t \${FRONTEND_IMAGE} .
                    docker push \${FRONTEND_IMAGE}
                    cd .. 

                    # =========================================
                    # 2️⃣ BUILD AND PUSH BACKEND
                    # =========================================
                    echo "🏗️ Building Backend..."
                    cd backend
                    BACKEND_IMAGE="\${ACR_NAME}.azurecr.io/\${BACKEND_APP_NAME}:\${GIT_COMMIT}"
                    
                    docker build -t \${BACKEND_IMAGE} .
                    docker push \${BACKEND_IMAGE}
                    cd .. 
                    """
                }
            }
        }

        stage('Manual Deployment Step') {
            steps {
                // We strip out the failing Service Principal login and instead 
                // output the exact commands you need to run locally.
                echo '========================================================================'
                echo '✅ BUILD & PUSH SUCCESSFUL!'
                echo '⚠️ AUTOMATED DEPLOYMENT BLOCKED BY AZURE DIRECTORY PERMISSIONS'
                echo 'Run these exact commands on your local Mac terminal to deploy the new code:'
                echo '========================================================================'
                
                echo "az containerapp update --name \${BACKEND_APP_NAME} --resource-group \${RG_NAME} --image \${ACR_NAME}.azurecr.io/\${BACKEND_APP_NAME}:\${GIT_COMMIT}"
                
                echo "az containerapp update --name \${FRONTEND_APP_NAME} --resource-group \${RG_NAME} --image \${ACR_NAME}.azurecr.io/\${FRONTEND_APP_NAME}:\${GIT_COMMIT}"
            }
        }
    }
}