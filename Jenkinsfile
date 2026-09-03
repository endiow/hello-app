pipeline {
  agent {
    kubernetes {
      cloud 'Ubuntu-5.12'
      inheritFrom 'jenkins-agent'
    }
  }
  options {
    skipDefaultCheckout(true)
  }
  stages {
    stage('测试') {
      steps {
        sh '''
          pwd
          ls -la
          echo "===== 检查git是否存在 ====="
          git --version || echo "❌ pod内没有git命令"
        '''
      }
    }
  }
}
