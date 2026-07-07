pipeline {

    agent any

    environment {
        REPO_URL = "https://github.com/deniputraa/Laravel-New-2026.git"
        BRANCH = "main"

        HARBOR = "192.168.1.252"
        PROJECT = "test-cbncloud"
        IMAGE_NAME = "laravel-new-2026"

        IMAGE = "${HARBOR}/${PROJECT}/${IMAGE_NAME}:${BUILD_NUMBER}"

        NAMESPACE = "testing-laravel"

        HOST = "laravel.192.168.1.100.nip.io"
	HOST_DRC = "laravel.10.10.10.100.nip.io"
    }

    stages {

        stage('Clone Repository') {
            steps {
                git branch: BRANCH,
                    credentialsId: 'github_ce',
                    url: REPO_URL
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                docker build -t ${IMAGE} .
                """
            }
        }


	stage('Trivy Scan') {

	    steps {
	        sh """
	        trivy image \
	        --severity HIGH,CRITICAL \
	        ${IMAGE} || true
	        """
	    }

	}

/*	kalau ada yang critical atau high stop build.
        stage('Trivy Scan') {
            steps {
                sh """
                trivy image \
                --exit-code 1 \
                --severity HIGH,CRITICAL \
                ${IMAGE}
                """
            }
        }
*/
        stage('Login Harbor') {

            steps {

                withCredentials([
                    usernamePassword(
                        credentialsId: 'harbor_ce',
                        usernameVariable: 'USERNAME',
                        passwordVariable: 'PASSWORD'
                    )
                ]) {

                    sh '''
                    echo "$PASSWORD" | docker login 192.168.1.252 \
                    -u "$USERNAME" \
                    --password-stdin
                    '''

                }

            }

        }

        stage('Push Image Harbor') {

            steps {

                sh """
                docker push ${IMAGE}
                """

            }

        }

        stage('Update Manifest') {

            steps {

                sh """
                sed -i 's#IMAGE_PLACEHOLDER#${IMAGE}#g' k8s/deployment.yaml
                """

            }

        }

        stage('Deploy DC') {

            steps {

                withCredentials([
                    file(credentialsId: 'kubeconfig-dc', variable: 'KUBECONFIG'),
                    usernamePassword(
                        credentialsId: 'harbor_ce',
                        usernameVariable: 'USERNAME',
                        passwordVariable: 'PASSWORD'
                    )
                ]) {

                    sh '''

                    kubectl create namespace testing-laravel \
                    --dry-run=client -o yaml | kubectl apply -f -

                    kubectl create secret docker-registry harbor-secret \
                    --docker-server=192.168.1.252 \
                    --docker-username=$USERNAME \
                    --docker-password=$PASSWORD \
                    -n testing-laravel \
                    --dry-run=client -o yaml | kubectl apply -f -

                    kubectl apply -f k8s/deployment.yaml
		    kubectl apply -f k8s/service.yaml
		    kubectl apply -f k8s/ingress-dc.yaml

                    kubectl rollout status deployment/laravel \
                    -n testing-laravel \
                    --timeout=300s

                    '''

                }

            }

        }

        stage('Health Check DC') {

            steps {

                sh """
                sleep 20
                curl --fail http://${HOST}
                """

            }

        }

        stage('Deploy DRC') {

            steps {

                withCredentials([
                    file(credentialsId: 'kubeconfig-drc', variable: 'KUBECONFIG'),
                    usernamePassword(
                        credentialsId: 'harbor_ce',
                        usernameVariable: 'USERNAME',
                        passwordVariable: 'PASSWORD'
                    )
                ]) {

                    sh '''

                    kubectl create namespace testing-laravel \
                    --dry-run=client -o yaml | kubectl apply -f -

                    kubectl create secret docker-registry harbor-secret \
                    --docker-server=192.168.1.252 \
                    --docker-username=$USERNAME \
                    --docker-password=$PASSWORD \
                    -n testing-laravel \
                    --dry-run=client -o yaml | kubectl apply -f -

                    kubectl apply -f k8s/deployment.yaml
		    kubectl apply -f k8s/service.yaml
		    kubectl apply -f k8s/ingress-drc.yaml

                    kubectl rollout status deployment/laravel \
                    -n testing-laravel \
                    --timeout=300s

                    '''

                }

            }

        }

        stage('Health Check DRC') {

            steps {

                sh """
                sleep 20
                curl --fail http://${HOST_DRC}
                """

            }

        }

    }

    post {

        always {

            sh """
            docker logout ${HARBOR} || true
            docker image rm ${IMAGE} || true
            """

            cleanWs()

        }

        success {

            echo "===================================="
            echo "Deployment Success"
            echo "Image : ${IMAGE}"
            echo "===================================="

        }

        failure {

            echo "===================================="
            echo "Deployment Failed"
            echo "===================================="

        }

    }

}
