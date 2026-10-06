pipeline {
    agent any
    tools{
        jdk 'JDK21'
        maven 'M3'
    }
    stages {
        stage('Git Clone') {
            steps {
                git branch: 'main', url: 'https://github.com/Dutap01/spring-petclinic.git'
            }
        }
        stage('Maven Build'){
            steps {
                echo 'Maven Build'
                sh 'mvn -Dmaven.test.failure.ignore=true clean package'
            }
        }
    }
}
