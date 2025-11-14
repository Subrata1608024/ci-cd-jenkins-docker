pipeline {
  agent any

  environment {
    COMPOSE_PROJECT_NAME = "demoapp"
    IMAGE_NAME          = "demoapp"
    DOCKER_BUILDKIT     = "1"    // Faster Docker builds
  }

  options {
    timestamps()
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Unit Tests') {
      steps {
        sh '''
/bin/bash <<'BASH'
set -euo pipefail
# Run tests in a disposable Python container; no Python needed on the agent.
docker run --rm \
  -v "$PWD":/workspace \
  -w /workspace \
  -e PYTHONPATH=/workspace \
  python:3.11-slim bash -lc "
    pip install --no-cache-dir -r app/requirements.txt -r app/requirements-dev.txt &&
    pytest -q
  "
BASH
        '''
      }
    }

    stage('Package Image') {
      steps {
        sh '''
/bin/bash <<'BASH'
set -euo pipefail
docker build -t "$IMAGE_NAME:${BUILD_NUMBER}" -t "$IMAGE_NAME:latest" .
docker image ls "$IMAGE_NAME"
BASH
        '''
      }
    }

    stage('Deploy with Compose') {
      steps {
        sh '''
/bin/bash <<'BASH'
set -euo pipefail
# Bring up (or update) the app locally on the agent
APP_VERSION="${BUILD_NUMBER}" docker compose up -d --build --remove-orphans
docker compose ps
BASH
        '''
      }
    }

    stage('Health Check') {
      steps {
        sh '''
/bin/bash <<'BASH'
set -euo pipefail
# Verify HTTP endpoint and Docker health status
./healthcheck.sh http://localhost:5000/health app
BASH
        '''
      }
    }
  }

  post {
    always {
      sh '''
/bin/bash <<'BASH'
set +e
docker compose logs --no-color > compose.log || true
BASH
      '''
      archiveArtifacts artifacts: 'compose.log', fingerprint: true
    }
    success {
      echo '✅ Build → Deploy → Health OK'
    }
    failure {
      echo '❌ Pipeline failed'
      sh '''
/bin/bash <<'BASH'
docker compose ps || true
BASH
      '''
    }
  }
}
 
