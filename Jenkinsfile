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
    stage('测试环境') {
      steps {
        sh '''
        pwd
        ls -la
        git --version
        '''
      }
    }
    stage('拉取业务代码') {
      steps {
        sshagent(credentials: ['git-ssh-key']) {
          sh '''
          rm -rf ./*
          export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no"
          git clone git@github.com:endiow/hello-app.git .
          ls -la
          git log -1
          '''
        }
      }
    }

    stage('kaniko构建镜像') {
      steps {
        container('kaniko') {
          sh '''
          echo "======进入kaniko容器======"
          echo "kaniko侧 WORKSPACE=${WORKSPACE}"
          ls -la ${WORKSPACE}
          which /kaniko/executor
          /kaniko/executor --version
          '''
        }
      }
    }

  }
    

  post {
    success { echo "✅全部完成" }
    failure { echo "❌失败" }
  }
}
