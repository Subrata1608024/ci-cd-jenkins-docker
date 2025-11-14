pipeline {
  agent any

  environment {
    COMPOSE_PROJECT_NAME = "demoapp"
    IMAGE_NAME          = "demoapp"
    DOCKER_BUILDKIT     = "1"
  }

  options {
    timestamps()
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Unit Tests') {
      steps {
        sh(script: '''
          set -euo pipefail
          docker run --rm -v "$PWD":/workspace -w /workspace python:3.11-slim bash -lc "
            pip install --no-cache-dir -r app/requirements.txt -r app/requirements-dev.txt &&
            pytest -q
          "
        ''', shell: '/bin/bash')
      }
    }

    stage('Package Image') {
      steps {
        sh(script: '''
          set -euo pipefail
          docker build -t $IMAGE_NAME:${BUILD_NUMBER} -t $IMAGE_NAME:latest .
          docker image ls $IMAGE_NAME
        ''', shell: '/bin/bash')
      }
    }

    stage('Deploy with Compose') {
      steps {
        sh(script: '''
          set -euo pipefail
          APP_VERSION=${BUILD_NUMBER} docker compose up -d --build --remove-orphans
          docker compose ps
        ''', shell: '/bin/bash')
      }
    }

    stage('Health Check') {
      steps {
        sh(script: '''
          set -euo pipefail
          ./healthcheck.sh http://localhost:5000/health app
        ''', shell: '/bin/bash')
      }
    }
  }

  post {
    always {
      sh(script: '''
        set +e
        docker compose logs --no-color > compose.log || true
      ''', shell: '/bin/bash')
      archiveArtifacts artifacts: 'compose.log', fingerprint: true
    }
    success { echo '✅ Build → Deploy → Health OK' }
    failure {
      echo '❌ Pipeline failed'
      sh(script: 'docker compose ps || true', shell: '/bin/bash')
    }
  }
}
 
