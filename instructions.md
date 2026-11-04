# Developer Instructions

## 1. Prerequisites

Install:
- Git
- Docker Engine
- Docker Compose v2

Verify:

```bash
git --version
docker --version
docker compose version
```

## 2. Clone the Repository

```bash
git clone https://github.com/Anjali2-O/devops-assignment.git
cd devops-assignment
```

## 3. Configure Environment Variables

Create the local environment file:

```bash
cp .env.example .env
```

The local Redis connection is configured through `REDIS_URL`.

Example:

```env
REDIS_URL=redis://redis:6379/0
```

Do not commit `.env` or real credentials.

## 4. Build and Start the Application

Build images and start all services:

```bash
docker compose up --build -d
```

List running containers:

```bash
docker compose ps
```

Expected services:
- devops-frontend
- devops-backend
- devops-worker
- devops-redis

Open the application:

http://localhost:8080

## 5. Test the Application

Health check:

```bash
curl -X POST http://localhost:8080/api/health/
```

Expected response:

```json
{"message":"OK"}
```

Submit a background task:

```bash
curl -X POST "http://localhost:8080/api/notify/?email=test@example.com"
```

Example response:

```json
{
  "message": "Email will be sent to test@example.com",
  "task_id": "TASK_ID"
}
```

Check the task:

```bash
curl http://localhost:8080/api/task_status/TASK_ID
```

Replace `TASK_ID` with the returned task identifier.

A completed task returns its result.

## 6. View Logs

All services:

```bash
docker compose logs -f
```

Individual services:

```bash
docker compose logs -f backend
docker compose logs -f worker
docker compose logs -f frontend
docker compose logs -f redis
```

## 7. Debugging

List container status:

```bash
docker compose ps
```

Check Redis:

```bash
docker compose exec redis redis-cli ping
```

Expected:

```text
PONG
```

Open a shell inside the backend:

```bash
docker compose exec backend sh
```

Inspect worker output:

```bash
docker compose logs --tail=100 worker
```

Validate Compose configuration:

```bash
docker compose config
```

## 8. Stop and Clean Up

Stop services:

```bash
docker compose down
```

Stop services and remove the Redis data volume:

```bash
docker compose down -v
```

Warning: `docker compose down -v` deletes the local Redis volume and its stored data.

## 9. Rebuild After Code Changes

```bash
docker compose down
docker compose up --build -d
```

## 10. Terraform Validation

From the repository root:

```bash
cd terraform
terraform init
terraform fmt -check
terraform validate
```

Create a plan using the required image variables:

```bash
terraform plan \
  -var="container_image=asia-south1-docker.pkg.dev/PROJECT_ID/REPOSITORY/backend:TAG" \
  -var="frontend_image=asia-south1-docker.pkg.dev/PROJECT_ID/REPOSITORY/frontend:TAG"
```

Review the plan and cost implications before applying.

Do not run `terraform apply` unless all resources and their trial-credit eligibility have been reviewed.

## 11. GitHub Actions

CI:
- Open GitHub repository → Actions → DevOps Assignment CI.
- Pushes and pull requests to `main` trigger validation and image builds.

WIF test:
- Open GCP Workload Identity Test.
- Verify the authentication job.

CD:
- Open DevOps Assignment CD.
- Select Run workflow.
- CD requires existing Artifact Registry and Cloud Run resources.
- Do not run until cloud infrastructure and cost eligibility are confirmed.

## 12. Google Cloud Deployment Prerequisites

The planned deployment uses:
- Artifact Registry.
- Cloud Run services.
- Cloud Run Worker Pools.
- Memorystore Redis.
- VPC and Private Service Access.
- Secret Manager.
- Workload Identity Federation.

The deployment workflow updates existing services. Terraform is responsible for provisioning the infrastructure.

Redis TLS credentials and certificates must be configured before application deployment.

The worker pool uses manual scaling. At least one worker instance is required to process tasks.

## 13. Cost Safety

Before deployment:
1. Verify GCP trial-credit eligibility.
2. Check region-specific pricing.
3. Review Memorystore cost separately.
4. Review Artifact Registry storage charges.
5. Check Cloud Run and worker pool scaling.
6. Confirm that no personal billing upgrade is required.

After testing, review all provisioned resources and execute the reviewed Terraform destruction plan where appropriate.
