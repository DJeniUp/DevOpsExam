pipeline {
    agent any

    environment {
        IMAGE_NAME = 'ttl.sh/myapp:2h'
        SSH_KEY = '/var/lib/jenkins/.ssh/key-jenkins'
        TARGET_USER = 'laborant'
        TARGET_HOST = '172.16.0.3'
        TARGET_PATH = '/home/laborant'
    }

    stages {
        stage('Install dependencies') {
            steps {
                sh 'npm install'
            }
        }
        stage('Free Port 4444') {
            steps {
                sh 'lsof -ti tcp:4444 | xargs -r kill -9 || true'
                sh 'sleep 3'  // дати час на звільнення порту
            }
        }

        stage('Test') {
            steps {
                sh 'node --test index.test.js'
            }
        }
        stage('Deploy') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'key-jenkins', keyFileVariable: 'KEY')]) {
                    sh '''
                        mkdir -p /var/lib/jenkins/.ssh
                        ssh-keyscan -H 172.16.0.3 >> /var/lib/jenkins/.ssh/known_hosts
                        scp -i $KEY -r Jenkinsfile index.js index.test.js node_modules package-lock.json package.json laborant@172.16.0.3:/home/laborant
                        ssh -i $KEY laborant@172.16.0.3 "pkill -f index.js || true && cd /home/laborant && nohup node index.js > app.log 2>&1 &"
                    '''
                }
            }
        }





        stage('Build Docker Image') {
            steps {
                sh """
                docker build -t ${IMAGE_NAME} .
                docker push ${IMAGE_NAME}
                """
            }
        }
        stage('Deploy to Docker VM') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'key_jenkins', keyFileVariable: 'SSH_KEY')]) {
                    sh '''
                        echo "Connecting to VM using SSH key..."
                        ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no laborant@${VM_IP} 'echo OK'

                        echo "Deploying Docker image..."
                        ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no laborant@${VM_IP} "
                            docker pull ${IMAGE_NAME} &&
                            docker stop myapp || true &&
                            docker rm myapp || true &&
                            docker run -d --name myapp -p 4444:4444 ${IMAGE_NAME}
                        "
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([string(credentialsId: 'k8s-token', variable: 'KUBE_TOKEN')]) {
                    sh '''
                    export KUBECONFIG=kubeconfig.yaml
                    kubectl config set-cluster my-cluster --server=https://k8s:6443 --insecure-skip-tls-verify=true
                    kubectl config set-credentials jenkins-user --token=$KUBE_TOKEN
                    kubectl config set-context default --cluster=my-cluster --user=jenkins-user
                    kubectl config use-context default

                    kubectl delete pod myapp || true
                    kubectl run myapp --image=${IMAGE_NAME} --port=4444 --restart=Never
                    '''
                }
            }
        }
    }
}
