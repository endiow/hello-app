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
          #替换yaml模板镜像tag为git哈希，生成本地临时yaml配置文件
          sed "s/{{GIT_SHORT_HASH}}/${GIT_SHORT_HASH}/g" kaniko-build.tpl.yaml > kaniko-build.yaml
          sed "s/{{GIT_SHORT_HASH}}/${GIT_SHORT_HASH}/g" deploy.tpl.yaml > deploy.yaml
          
          cat kaniko-build.yaml
          kubectl apply -f kaniko-build.yaml

          echo "等待kaniko Job构建，开启实时日志..."
          # 循环尝试拉取流式日志，遇到“ContainerCreating”类报错就sleep重试，其他错误才退出
          timeout 480 bash -c '
          while true;do
            kubectl logs -f job/kaniko-build 2>/dev/null
            ret=$?

            # 0正常结束；1代表容器还没起来，重试；其他错误直接退出循环
            if [[ $ret -ne 1 ]];then
              break
            fi

            sleep 2
          done
          ' || true
          echo "==================== kaniko日志输出结束 ===================="

          kubectl wait job kaniko-build --for=condition=Complete --timeout=600s
          kubectl delete job kaniko-build --ignore-not-found=true
          '''
        }
      }
    }

    stage('部署应用（git hash版本）') {
      steps {
        container('jnlp') {
          sh '''
          set -e
          cat deploy.yaml
          # 使用替换完成的临时部署文件
          kubectl apply -f deploy.yaml
          echo "等待Deployment滚动更新就绪"
          kubectl wait deployment hello-app --for=condition=Available --timeout=120s
          kubectl get deployment,pod,svc -l app=hello-app
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
