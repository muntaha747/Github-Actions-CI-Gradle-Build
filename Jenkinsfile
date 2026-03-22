pipeline {
    agent any

    environment {
        JAVA_HOME = "/usr/lib/jvm/java-17-amazon-corretto"
        PATH = "$JAVA_HOME/bin:$PATH"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main',
                url: 'https://github.com/muntaha747/Github-Actions-CI-Gradle-Build.git'
            }
        }

        stage('Grant Execute Permission') {
            steps {
                sh 'chmod +x gradlew'
            }
        }

        stage('Gradle Build') {
            steps {
                sh './gradlew clean build'
            } 
        }

        stage('Run Application') {
            steps {
                sh './gradlew run'
            }
        }
    }

    post {
        success {
            echo 'Build and execution successful!'
        }
        failure {
            echo 'Build failed!'
        }
    }
}

