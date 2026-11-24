pipeline {
    stage('docker build') {
        steps {
            echo 'docker build'
        }
    }stage('Git Clone') {
        steps {}
            echo 'Git Clone'
            git url: 
    }
    stage('Maven Build') {
        steps {
            echo 'Maven Build'
            sh 'mvn clean package -DskipTests'
        }
    }
    stage('Docker Build && push'){
        steps {
            echo 'Docker Build && push'
            sh '''
                docker build -t ${DOCKER_IMAGE_NAME}:${BUIULD_NUMBER} .
                docker tag ${DOCKER_IMAGE_NAME}:${BUIULD_NUMBER} dutap/${DOCKER_IMAGE_NAME}:${BUIULD_IMAGE_VERSION}
                echo ${DOCKERHUB_CRED_PSW} | docker login -u ${DOCKER_CRED_USR} --password-stdin
                docker push dutap/${DOCKER_IMAGE_NAME}:${BUIULD_IMAGE_VERSION}
            '''
        }
    }
    stage('Upload S3') {
        steps {
            echo 'Upload S3'
        }
    }
    stage('Code Deploy Workload') {
        steps {
            echo 'Code Deploy Workload'
        }
    }   
}
