pipeline {
    agent any
    environment {
        ACR_NAME = 'benchmarkacrkel8'
        APP_NAME = 'light-app'
        IMAGE_TAG = "${env.BUILD_ID}"
    }
    stages {
        stage('Build & Push App') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'ACR_CREDENTIALS', passwordVariable: 'ACR_PASSWORD', usernameVariable: 'ACR_USER')]) {
                    // Log into the registry
                    sh 'docker login ${ACR_NAME}.azurecr.io -u $ACR_USER -p $ACR_PASSWORD'
                    
                    // Build the single Dockerfile in the root directory (.)
                    sh 'docker build -t ${ACR_NAME}.azurecr.io/${APP_NAME}:${IMAGE_TAG} -t ${ACR_NAME}.azurecr.io/${APP_NAME}:latest .'
                    
                    // Push both tags to Azure
                    sh 'docker push ${ACR_NAME}.azurecr.io/${APP_NAME}:${IMAGE_TAG}'
                    sh 'docker push ${ACR_NAME}.azurecr.io/${APP_NAME}:latest'
                }
            }
        }
        stage('Deploy to Server') {
            steps {
                // Use plain Docker commands to replace the running container
                sh '''
                # 1. Pull the fresh image we just built
                docker pull ${ACR_NAME}.azurecr.io/${APP_NAME}:latest
                
                # 2. Stop and remove the old container (the '|| true' prevents errors on the very first run)
                docker stop ${APP_NAME}-container || true
                docker rm ${APP_NAME}-container || true
                
                # 3. Start the new container directly on port 80
                # NOTE: Change '8080' below to whatever port your app actually uses internally
                docker run -d \
                  --restart always \
                  --name ${APP_NAME}-container \
                  -p 80:4000 \
                  ${ACR_NAME}.azurecr.io/${APP_NAME}:latest
                '''
            }
        }
    }
}