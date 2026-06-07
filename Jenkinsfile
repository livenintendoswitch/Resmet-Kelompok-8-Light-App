pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        // Your Azure Environment Variables
        ACR_NAME              = 'benchmarkacrkel8'
        RG_NAME               = 'benchmark-apps-rg'
        
        // Azure handles microservices best as two linked Container Apps
        FRONTEND_APP_NAME     = 'light-app-frontend'
        BACKEND_APP_NAME      = 'light-app-service'
        
        // Azure Service Principal Details
        AZURE_SUBSCRIPTION_ID = 'your-subscription-id' 
        AZURE_TENANT_ID       = 'your-tenant-id'       
        AZURE_CLIENT_ID       = 'your-sp-app-id'       
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
                    cd .. # Go back to root

                    # =========================================
                    # 2️⃣ BUILD AND PUSH BACKEND
                    # =========================================
                    echo "🏗️ Building Backend..."
                    cd backend
                    BACKEND_IMAGE="\${ACR_NAME}.azurecr.io/\${BACKEND_APP_NAME}:\${GIT_COMMIT}"
                    
                    docker build -t \${BACKEND_IMAGE} .
                    docker push \${BACKEND_IMAGE}
                    cd .. # Go back to root
                    """
                }
            }
        }

        stage('Deploy Microservices to Azure Container Apps') {
            steps {
                // This replaces the complex jq JSON injection you had to do in AWS.
                // Azure lets us update the services directly via the CLI.
                withCredentials([string(credentialsId: 'AZURE_SP_PASSWORD', variable: 'SP_PASSWORD')]) {
                    sh """
                    echo "🔐 Authenticating Jenkins with Azure..."
                    az login --service-principal -u \${AZURE_CLIENT_ID} -p \${SP_PASSWORD} --tenant \${AZURE_TENANT_ID}
                    az account set --subscription \${AZURE_SUBSCRIPTION_ID}

                    FRONTEND_IMAGE="\${ACR_NAME}.azurecr.io/\${FRONTEND_APP_NAME}:\${GIT_COMMIT}"
                    BACKEND_IMAGE="\${ACR_NAME}.azurecr.io/\${BACKEND_APP_NAME}:\${GIT_COMMIT}"

                    echo "🚀 Updating Backend Container App..."
                    az containerapp update \\
                        --name \${BACKEND_APP_NAME} \\
                        --resource-group \${RG_NAME} \\
                        --image \${BACKEND_IMAGE}

                    echo "🚀 Updating Frontend Container App..."
                    az containerapp update \\
                        --name \${FRONTEND_APP_NAME} \\
                        --resource-group \${RG_NAME} \\
                        --image \${FRONTEND_IMAGE}

                    echo "✅ Multi-Container Deployment successful!"
                    """
                }
            }
        }
    }
}