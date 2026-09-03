pipeline {
  agent {
    kubernetes {
      cloud 'Ubuntu-5.12'
      inheritFrom 'jenkins-agent'
      yamlMergeStrategy merge()
      yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: kaniko
    image: gcr.m.daocloud.io/kaniko-project/executor:v1.23.2
    imagePullPolicy: IfNotPresent
    command: ['cat']
    tty: true
    env:
    - name: DOCKER_CONFIG
      value: /kaniko/.docker
'''
    }
  }
  options {
    skipDefaultCheckout(true)
  }
  environment {
    IMAGE_REPO = "crpi-9jpxgs9322doqt3f.cn-shenzhen.personal.cr.aliyuncs.com/endiow/hello-app"
    // acr-cred 为用户名密码类型凭证，自动注入 *_USR / *_PSW
    ACR_CREDS = credentials('acr-cred')
  }
  stages {
    stage('Checkout') {
      steps {
        sshagent(credentials: ['git-ssh-key']) {
          sh '''
            rm -rf ./*
            export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no"
            git clone git@github.com:endiow/hello-app.git .
            ls -la
          '''
        }
        script {
          // def 局部变量，消除jenkins警告
          def shortCommit = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
          env.IMAGE_TAG = shortCommit
        }
      }
    }

    stage('Kaniko Build & Push') {
      steps {
        container('kaniko') {
          // 使用 """ 三双引号，pipeline变量会被展开
          sh """
            mkdir -p /kaniko/.docker
            cat > /kaniko/.docker/config.json <<EOF
{
  "auths": {
    "${IMAGE_REPO.split('/')[0]}": {
      "auth": "\$(echo -n "${ACR_CREDS_USR}:${ACR_CREDS_PSW}" | base64)"
    }
  }
}
EOF
            kaniko \\
            --dockerfile=Dockerfile \\
            --context=. \\
            --destination=${IMAGE_REPO}:${IMAGE_TAG} \\
            --registry-mirror=https://docker.m.daocloud.io
          """
        }
      }
    }
  }
  post {
    success {
      echo "构建成功：${IMAGE_REPO}:${IMAGE_TAG}"
    }
    failure {
      echo "构建失败"
    }
  }
}
