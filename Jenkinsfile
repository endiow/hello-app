pipeline {
  agent {
    kubernetes {
      cloud 'Ubuntu-5.12'
      inheritFrom 'jenkins-agent'
    }
  }
  options {
    skipDefaultCheckout(true)
    timeout(time:10, unit:'MINUTES')
  }
  stages {
    stage('测试环境') {
      steps {
        container('jnlp') {
          sh '''
          pwd
          ls -la
          git --version
          kubectl version --client
          '''
        }
      }
    }

    stage('拉取业务代码') {
      steps {
        container('jnlp') {
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
    }

    stage('拷贝代码到PVC /workspace，准备构建上下文') {
      steps {
        container('jnlp') {
          sh '''
          # 把当前jenkins工作目录全部代码复制到PVC挂载点 /workspace
          rm -rf /workspace/*
          cp -r ./* /workspace/
          ls -la /workspace
          '''
        }
      }
    }

    stage('kaniko Job构建镜像：git哈希 + latest标签') {
      steps {
        container('jnlp') {
          sh '''
          set -e
          GIT_SHORT_HASH=$(git rev-parse --short HEAD)
          echo "GIT_SHORT_HASH=${GIT_SHORT_HASH}"

          kubectl apply -f - <<'EOF'
apiVersion: batch/v1
kind: Job
metadata:
  name: kaniko-build
  namespace: default
spec:
  backoffLimit: 0
  ttlSecondsAfterFinished: 300
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: kaniko
        image: gcr.m.daocloud.io/kaniko-project/executor:v1.23.2
        args:
        - --context=/workspace
        - --destination=crpi-9jpxgs9322doqt3f.cn-shenzhen.personal.cr.aliyuncs.com/endiow/hello-app:${GIT_SHORT_HASH}
        - --destination=crpi-9jpxgs9322doqt3f.cn-shenzhen.personal.cr.aliyuncs.com/endiow/hello-app:latest
        volumeMounts:
        - name: source-pvc
          mountPath: /workspace
        - name: docker-config
          mountPath: /kaniko/.docker
      volumes:
      - name: source-pvc
        persistentVolumeClaim:
          claimName: ci-workspace-pvc
      - name: docker-config
        secret:
          secretName: acr-secret
          items:
          - key: .dockerconfigjson
            path: config.json
'EOF'

          kubectl wait job kaniko-build --for=condition=Complete --timeout=600s
          kubectl logs job/kaniko-build
          kubectl delete job kaniko-build --ignore-not-found=true
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
