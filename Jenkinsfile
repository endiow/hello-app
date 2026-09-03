pipeline {
  agent {
    kubernetes {
      cloud 'Ubuntu-5.12'
      inheritFrom 'jenkins-agent'
    }
  }

  

  stages {
    stage('测试') {
      steps {
        sh '''
          pwd
          ls -la
        '''
      }
    }
  }
