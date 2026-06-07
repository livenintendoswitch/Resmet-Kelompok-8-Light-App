pipeline {
    agent any
    environment {
        ACR_NAME = 'benchmarkacrkel8'
        IMAGE_TAG = "${env.BUILD_ID}"
    }
    stages {
        stage('Build & Push Backend') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'ACR_CREDENTIALS', passwordVariable: 'ACR_PASSWORD', usernameVariable: 'ACR_USER')]) {
                    sh 'docker login ${ACR_NAME}.azurecr.io -u $ACR_USER -p $ACR_PASSWORD'
                    
                    // Build and tag with BOTH the specific Build ID and 'latest'
                    sh 'docker build -t ${ACR_NAME}.azurecr.io/light-app-service:${IMAGE_TAG} -t ${ACR_NAME}.azurecr.io/light-app-service:latest ./backend'
                    
                    // Push both tags
                    sh 'docker push ${ACR_NAME}.azurecr.io/light-app-service:${IMAGE_TAG}'
                    sh 'docker push ${ACR_NAME}.azurecr.io/light-app-service:latest'
                }
            }
        }
        stage('Build & Push Frontend') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'ACR_CREDENTIALS', passwordVariable: 'ACR_PASSWORD', usernameVariable: 'ACR_USER')]) {
                    sh 'docker build -t ${ACR_NAME}.azurecr.io/light-app-frontend:${IMAGE_TAG} -t ${ACR_NAME}.azurecr.io/light-app-frontend:latest ./frontend'
                    
                    sh 'docker push ${ACR_NAME}.azurecr.io/light-app-frontend:${IMAGE_TAG}'
                    sh 'docker push ${ACR_NAME}.azurecr.io/light-app-frontend:latest'
                }
            }
        }
        stage('Deploy to Server') {
            steps {
                // Navigate to the deployment folder on the VM, pull the fresh 'latest' images, and restart
                sh '''
                cd /home/azureuser/light-app-deployment
                docker compose pull
                docker compose up -d
                '''
            }
        }
    }
}