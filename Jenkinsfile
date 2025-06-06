pipeline {
    agent any

    environment {
        IMAGE_NAME = 'ttl.sh/myapp:2h'
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
                sshagent (credentials: ['key-jenkins']) {
                    sh """
                        scp -o StrictHostKeyChecking=no index.js laborant@172.16.0.3:/home/laborant/
                        ssh -o StrictHostKeyChecking=no laborant@172.16.0.3 '
                            pkill -f "node index.js" || true
                            nohup node /home/laborant/index.js > output.log 2>&1 &
                        '
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
