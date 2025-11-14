# CI/CD Demo: Jenkins + Docker + Docker Compose

A small end‑to‑end CI/CD pipeline that:
- builds a tiny Flask “Hello, World” app,
- runs unit tests,
- packages it as a Docker image,
- deploys with Docker Compose,
- verifies health (`/health`),
- (bonus) runs Jenkins inside Docker (with a Docker‑in‑Docker sidecar).

## Repo layout

```
.
├── Jenkinsfile
├── Dockerfile
├── docker-compose.yml
├── healthcheck.sh
├── app/
│   ├── app.py
│   ├── requirements.txt
│   ├── requirements-dev.txt
│   └── tests/
│       └── test_app.py
├── jenkins/
│   ├── Dockerfile
│   └── docker-compose.yml
└── sample-pipeline-output.txt
```

## Prereqs

- Docker Engine + Docker Compose v2 (`docker compose version` works)
- (Optional) For local Jenkins: Docker (privileged) to run DinD

---

## Quick start (without Jenkins)

```bash
# 1) Build & run the app locally
docker compose up -d --build

# 2) Open the app
open http://localhost:5000     # macOS
# or: xdg-open http://localhost:5000  # Linux
# or just paste into your browser

# 3) Check health
curl -fsS http://localhost:5000/health | jq .
# or run the helper:
./healthcheck.sh

# 4) Run unit tests in a throwaway Python container
docker run --rm -v "$PWD":/workspace -w /workspace python:3.11-slim bash -lc \
  "pip install -r app/requirements.txt -r app/requirements-dev.txt && pytest -q"
```

---

## Run Jenkins in Docker (Bonus)

> This spins up **Jenkins LTS** + a **Docker-in-Docker** sidecar. Jenkins drives the DinD
> daemon via `DOCKER_HOST=tcp://dind:2375`.

```bash
cd jenkins
docker compose up -d
# Get the Jenkins initial admin password:
docker exec -it jenkins cat /var/jenkins_home/secrets/initialAdminPassword
# Then browse to http://localhost:8080 and complete setup.
```

**Plugins**: We pre-install core pipeline + git plugins, but during the setup wizard you can also choose “Suggested Plugins”.

**Create the pipeline job:**

- Create a new **Pipeline** job (or Multibranch).
- If you’ve pushed this repo to GitHub/GitLab, set **Pipeline script from SCM** with your repo URL, and **Script Path** = `Jenkinsfile`.
- If you haven’t pushed it anywhere, you can choose **Pipeline script** and paste the `Jenkinsfile` from this repo.

Run the job. The stages should be:
**Checkout → Unit Tests → Package Image → Deploy with Compose → Health Check**

If you need the pipeline to talk to DinD explicitly, ensure this is set in the job’s environment or in the Jenkinsfile:
```
DOCKER_HOST=tcp://dind:2375
```

---

## What the pipeline does (in plain English)

1. **Checkout**: Get this repo.
2. **Unit Tests**: Launches a short‑lived `python:3.11-slim` container, installs deps, and runs `pytest`.
3. **Package Image**: Builds a Docker image tagged `demoapp:<build #>` and `demoapp:latest`.
4. **Deploy with Compose**: `docker compose up -d` the app, exposing port **5000**.
5. **Health Check**: Runs `healthcheck.sh` which checks the HTTP endpoint and the Docker container’s `healthy` status.

---

## Tear down

```bash
docker compose down -v   # from the repo root
cd jenkins && docker compose down -v  # if you started Jenkins
```

## Sample Jenkins console output

See: [`sample-pipeline-output.txt`](sample-pipeline-output.txt)

---

## Notes

- The container defines a Docker **HEALTHCHECK** and Compose also defines its own healthcheck (either one is sufficient; Compose’s overrides the image’s when used together).
- The pipeline archives `compose.log` so you have the container logs attached to the Jenkins run.
- Uses `docker compose` (v2). If you only have the legacy `docker-compose`, replace occurrences accordingly.
