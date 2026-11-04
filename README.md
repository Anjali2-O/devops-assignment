# DevOps Assessment – Background Task Processing Application

## 1. Project Overview

This project containerizes and prepares a background task processing application for cloud deployment.

The application uses FastAPI for HTTP APIs, Celery for asynchronous background processing, Redis as the message broker and result backend, and an NGINX frontend.

The solution includes:
- Dockerfiles for backend/worker and frontend.
- Docker Compose for local development.
- Environment-based configuration.
- Terraform infrastructure as code for Google Cloud.
- GitHub Actions CI workflow.
- GitHub Actions CD workflow using Workload Identity Federation.
- Developer instructions and architecture documentation.

## 2. Application Architecture

### Application components

| Component | Technology | Responsibility |
|---|---|---|
| Frontend | HTML, JavaScript, NGINX | Submits tasks and polls task status |
| Backend | Python, FastAPI | Exposes notification and task-status APIs |
| Worker | Python, Celery | Executes asynchronous background tasks |
| Message broker | Redis | Stores queued tasks and task results |
| Reverse proxy | NGINX | Serves frontend and forwards `/api` requests |

### Request flow

1. User enters an email address in the frontend.
2. Frontend sends `POST /api/notify/`.
3. NGINX forwards the request to FastAPI.
4. FastAPI submits a Celery task to Redis.
5. Celery worker retrieves and executes the task.
6. Frontend polls `GET /api/task_status/{task_id}`.
7. Backend returns the task status and result.

Note: This sample application simulates a notification task and writes a log. It does not implement actual email delivery.

## 3. Repository Structure

```text
devops-assignment/
├── backend/
│   ├── Dockerfile
│   ├── main.py
│   └── worker.py
├── frontend/
│   ├── Dockerfile
│   ├── index.html
│   ├── nginx.conf
│   └── nginx.conf.template
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── providers.tf
│   └── .terraform.lock.hcl
├── .github/
│   └── workflows/
│       ├── ci.yml
│       ├── cd.yml
│       └── gcp-auth-test.yml
├── docker-compose.yml
├── .env.example
├── .dockerignore
├── .gitignore
├── README.md
├── instructions.md
├── journey.md
└── architecture/
    └── architecture.md
```

## 4. Local Development

Prerequisites:
- Docker Engine
- Docker Compose v2
- Git

Clone the repository:

```bash
git clone https://github.com/Anjali2-O/devops-assignment.git
cd devops-assignment
```

Create the environment file:

```bash
cp .env.example .env
```

Build and start the complete application:

```bash
docker compose up --build -d
```

Open:

http://localhost:8080

The backend API is also available at:

http://localhost:8000

## 5. API Endpoints

| Method | Endpoint | Purpose |
|---|---|---|
| POST | `/notify/?email=test@example.com` | Enqueues a background task |
| GET | `/task_status/{task_id}` | Returns task status and result |
| POST | `/health/` | Backend health check |

When accessing through the frontend NGINX proxy, prefix the API paths with `/api`.

Example:

```bash
curl -X POST "http://localhost:8080/api/notify/?email=test@example.com"
```

Check task status using the returned task ID:

```bash
curl "http://localhost:8080/api/task_status/<TASK_ID>"
```

Health check:

```bash
curl -X POST "http://localhost:8080/api/health/"
```

## 6. CI/CD

### Continuous Integration

GitHub Actions workflow: `.github/workflows/ci.yml`

Triggered on pushes and pull requests targeting `main`.

It:
- Checks out the source code.
- Prepares the environment file.
- Validates Docker Compose configuration.
- Builds the backend/worker image.
- Builds the frontend image.

### Google Cloud Authentication

GitHub Actions uses Workload Identity Federation (WIF).

This provides keyless authentication between GitHub Actions and Google Cloud without storing a permanent service-account JSON key.

The dedicated deployment identity is:

`github-actions-deployer@testing-508709.iam.gserviceaccount.com`

The provider is restricted to the repository and main branch.

### Continuous Deployment

Workflow: `.github/workflows/cd.yml`

Manually triggered through GitHub Actions.

The intended stages are:
1. Authenticate to Google Cloud using WIF.
2. Build backend and frontend Docker images.
3. Push images to Artifact Registry.
4. Update the backend Cloud Run service.
5. Update the Celery Cloud Run Worker Pool.
6. Update the frontend Cloud Run service.

CD execution requires the Artifact Registry repository and Cloud Run resources to exist first.

The CD workflow has been prepared but has not been executed against deployed cloud infrastructure.

## 7. Infrastructure as Code

Terraform configuration is located in `terraform/`.

The planned Google Cloud architecture includes:

- Artifact Registry for Docker images.
- Cloud Run service for FastAPI.
- Cloud Run Worker Pool for Celery.
- Cloud Run service for the NGINX frontend.
- Memorystore for Redis.
- VPC and subnet.
- Private Service Access.
- Secret Manager for Redis authentication and TLS CA certificate.
- Separate runtime service accounts.

Region: `asia-south1`

Project: `testing-508709`

Terraform validation and planning have been completed. Full infrastructure provisioning has not been executed.

## 8. Logging and Monitoring

Local application logs:

```bash
docker compose logs -f
docker compose logs -f backend
docker compose logs -f worker
docker compose logs -f frontend
docker compose logs -f redis
```

Cloud deployment is designed to use Cloud Run and Cloud Run Worker Pool logs through Google Cloud Logging.

Cloud Monitoring can be used to monitor request activity, service availability, CPU and memory utilization, and worker operation after deployment.

Cloud logging and monitoring have not yet been verified against deployed application resources.

## 9. Cost and Deployment Considerations

The cloud configuration is designed for a GCP deployment.

Important cost considerations:
- Artifact Registry storage and applicable network usage.
- Memorystore Redis provisioned capacity.
- Cloud Run service resource consumption.
- Cloud Run Worker Pool instance runtime.
- Networking and other applicable cloud services.

Memorystore Redis does not have a free tier. Do not assume that all services are covered by trial credits.

This assessment environment uses GCP trial credits. Before provisioning, verify each service's eligibility and estimated usage in the Google Cloud pricing calculator.

No billing-account upgrade or personal payment is assumed by this project.

## 10. Infrastructure Cleanup

After a cloud deployment, review resources and Terraform state before destruction.

From the Terraform directory:

```bash
cd terraform
terraform plan -destroy
```

After reviewing the destruction plan:

```bash
terraform destroy
```

Also verify that no manually created resources, images, secrets, networking resources or other billable services remain.

Do not delete resources managed by other projects or users.

## 11. Current Implementation Status

| Area | Status |
|---|---|
| Backend and worker containerization | Completed |
| Frontend containerization | Completed |
| Docker Compose | Locally tested |
| End-to-end task execution | Tested successfully |
| GitHub CI | Successful |
| GCP WIF authentication | Successful |
| Terraform configuration | Written and validated |
| CD workflow | Implemented, not executed |
| Cloud infrastructure provisioning | Pending |
| Cloud logging verification | Pending |
| Video walkthrough | Pending |

## 12. Repository

Source code:

https://github.com/Anjali2-O/devops-assignment
