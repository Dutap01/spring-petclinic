pipeline {
    agent any

    tools {
        jdk 'JDK21'
        maven 'M3'
    }

    stages {
        stage('Git Clone') {
            steps {
                git branch: 'main', url: 'https://github.com/Dutap01/spring-petclinic.git'
            }
        }

        stage('Maven Build') {
            steps {
                echo 'Maven Build'
                sh 'mvn -Dmaven.test.failure.ignore=true clean package'
            }
        }

        stage('SSH Publish') {
            steps {
                echo 'SSH Publish'
                sshPublisher(
                    publishers: [
                        sshPublisherDesc(
                            configName: 'target',
                            transfers: [
                                sshTransfer(
                                    cleanRemote: false,
                                    excludes: '',
                                    execCommand: '''
                                        fuser -k 8080/tcp || true
                                        export BUILD_ID=Spring-PetClinic

                                        nohup java -jar /home/ubuntu/spring-petclinic-4.0.0-SNAPSHOT.jar > /home/ubuntu/nohup.out 2>&1 &
                                    ''',
                                    execTimeout: 120000,
                                    flatten: false,
                                    makeEmptyDirs: false,
                                    noDefaultExcludes: false,
                                    patternSeparator: '[, ]+',
                                    remoteDirectory: '',
                                    remoteDirectorySDF: false,
                                    removePrefix: 'target',
                                    sourceFiles: 'target/*.jar'
                                )
                            ],
                            usePromotionTimestamp: false,
                            useWorkspaceInPromotion: false,
                            verbose: false
                        )
                    ]
                )
            }
        }
    }
}
