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

        stage('Test') {
            steps {
                sh 'node --test index.test.js'
            }
        }
        stage('Deploy') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'key-jenkins', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                    sh """
                        mkdir -p ~/.ssh
                        ssh-keyscan -H 172.16.0.3 >> ~/.ssh/known_hosts
        
                        scp -i \$SSH_KEY -r Jenkinsfile index.js index.test.js node_modules package-lock.json package.json \$SSH_USER@172.16.0.3:/home/\$SSH_USER
                        
                        ssh -i \$SSH_KEY \$SSH_USER@172.16.0.3 cd /home/\$SSH_USER
                        ssh -i \$SSH_KEY \$SSH_USER@172.16.0.3 node index.js
                    """
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
