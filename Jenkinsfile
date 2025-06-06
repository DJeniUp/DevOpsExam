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
        stage('Deploy to Target') {
            steps {
                sh "scp -i ${SSH_KEY} -o StrictHostKeyChecking=no -r . ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}"
                
                sh "ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no ${TARGET_USER}@${TARGET_HOST} 'cd ${TARGET_PATH} && ./deploy-script.sh'"
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
