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
        sh '''
          set -euxo pipefail
          docker run --rm -v "$PWD":/workspace -w /workspace python:3.11-slim bash -lc "
            pip install --no-cache-dir -r app/requirements.txt -r app/requirements-dev.txt &&
            pytest -q
          "
        '''
      }
    }

    stage('Package Image') {
      steps {
        sh '''
          set -euxo pipefail
          docker build -t $IMAGE_NAME:${BUILD_NUMBER} -t $IMAGE_NAME:latest .
          docker image ls $IMAGE_NAME
        '''
      }
    }

    stage('Deploy with Compose') {
      steps {
        sh '''
          set -euxo pipefail
          APP_VERSION=${BUILD_NUMBER} docker compose up -d --build --remove-orphans
          docker compose ps
        '''
      }
    }

    stage('Health Check') {
      steps {
        sh '''
          set -euxo pipefail
          ./healthcheck.sh http://localhost:5000/health app
        '''
      }
    }
  }

  post {
    always {
      sh '''
        set +e
        docker compose logs --no-color > compose.log || true
      '''
      archiveArtifacts artifacts: 'compose.log', fingerprint: true
    }
    success { echo '✅ Build → Deploy → Health OK' }
    failure {
      echo '❌ Pipeline failed'
      sh 'docker compose ps || true'
    }
  }
}
 
