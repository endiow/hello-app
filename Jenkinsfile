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
    image: gcr.m.daocloud.io/kaniko-project/executor:v1.23.2-debug
    imagePullPolicy: IfNotPresent
    command: ['cat']
    tty: true
    env:
    - name: DOCKER_CONFIG
      value: /kaniko/.docker
'''
    }
  }
  environment {
    IMAGE_REPO = "crpi-9jpxgs9322doqt3f.cn-shenzhen.personal.cr.aliyuncs.com/endiow/hello-app"
    IMAGE_TAG = "${env.GIT_COMMIT.substring(0,8)}"
    ACR_CREDS = credentials('acr-cred')
  }
  stages {
    stage('Checkout') {
      steps {
        // 关闭Lightweight checkout后，agent pod内完整拉取代码
        checkout scm
        sh '''
          ls -la
        '''
      }
    }

    stage('Kaniko Build & Push') {
      steps {
        container('kaniko') {
          sh '''
            # 动态生成 kaniko 需要的 config.json
            mkdir -p /kaniko/.docker
            cat > /kaniko/.docker/config.json <<EOF
{
  "auths": {
    "crpi-9jpxgs9322doqt3f.cn-shenzhen.personal.cr.aliyuncs.com": {
      "auth": "$(echo -n "${ACR_CREDS_USR}:${ACR_CREDS_PSW}" | base64)"
    }
  }
}
EOF

            kaniko \
            --dockerfile=Dockerfile \
            --context=. \
            --destination=${IMAGE_REPO}:${IMAGE_TAG} \
            --registry-mirror=https://docker.m.daocloud.io
          '''
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
