# My DevOps Implementation Journey

## 1. Understanding the Application

I started by understanding how the existing application works.

It has four main components:
- FastAPI handles API requests.
- Celery processes background tasks.
- Redis stores queued tasks and their results.
- The frontend allows users to submit tasks and view their status.

The main challenge was understanding how these components communicate and how to run them together.

## 2. Containerizing the Application

I created separate Dockerfiles for the backend and frontend.

The backend Docker image is shared by FastAPI and the Celery worker. They use different startup commands but the same application dependencies.

I also used a non-root user in the backend container to avoid running the application with unnecessary root privileges.

**Challenge:** The backend and worker both depend on Redis. Starting everything at the same time could cause connection failures.

**Solution:** I configured a Redis health check in Docker Compose and made the backend and worker wait until Redis was healthy.

## 3. Configuring Frontend and Backend Communication

The frontend runs through NGINX, while FastAPI runs separately.

Initially, the browser needed a reliable way to communicate with the backend without depending on container-specific addresses.

**Solution:** I configured NGINX as a reverse proxy. Requests starting with `/api/` are forwarded to the backend container.

I also used an NGINX configuration template so the backend URL can be supplied through an environment variable.

## 4. Local Testing

I used Docker Compose to start the complete application:

```bash
docker compose up --build -d
```

I tested the application by:
- Opening the frontend.
- Submitting a notification request.
- Receiving a task ID.
- Checking the task status.
- Confirming that the Celery worker completed the task.

The frontend, backend, worker and Redis containers all ran successfully.

The worker logs confirmed that the background task was received and executed.

## 5. GitHub Actions – Continuous Integration

I created a GitHub Actions workflow to automate the build process.

Whenever code is pushed to the main branch or a pull request is created, the workflow:
- Checks out the source code.
- Validates the Docker Compose configuration.
- Builds the backend/worker image.
- Builds the frontend image.

The workflow completed successfully on GitHub Actions.

## 6. Google Cloud Authentication

For cloud deployment, I configured Workload Identity Federation between GitHub Actions and Google Cloud.

My initial authentication test failed because the Cloud Resource Manager API was disabled.

I enabled the required API and ran the workflow again.

The next authentication test succeeded.

I used Workload Identity Federation instead of storing a permanent service-account JSON key in GitHub Secrets.

## 7. Infrastructure as Code

I prepared Terraform configuration for the Google Cloud environment.

The planned infrastructure includes:
- Artifact Registry.
- Cloud Run services for the backend and frontend.
- Cloud Run Worker Pool for Celery.
- Memorystore Redis.
- VPC and private networking.
- Secret Manager.
- Separate service accounts for application components.

Terraform formatting and validation passed, and I generated an infrastructure plan.

## 8. Continuous Deployment

I created a separate GitHub Actions CD workflow.

The planned process is to:
1. Authenticate to Google Cloud using WIF.
2. Build the Docker images.
3. Push images to Artifact Registry.
4. Update the backend service.
5. Update the Celery worker.
6. Update the frontend service.

The workflow passed YAML validation.

Actual cloud deployment has not yet been executed because the required infrastructure has not been provisioned.

## 9. Challenges and Lessons Learned

Some important things I learned during this work:

- Containers need proper networking to communicate with each other.
- Redis must be ready before dependent services start.
- NGINX can act as a reverse proxy between a frontend and backend.
- Environment variables make configurations easier to manage across environments.
- GitHub Actions can authenticate to Google Cloud without permanent service-account keys.
- Terraform state must be stored persistently when infrastructure is managed from temporary CI runners.
- Managed cloud services simplify operations but require careful cost planning.

I also learned to separate infrastructure provisioning from application deployment rather than trying to manage everything in one pipeline.

## 10. Final Status

**Completed and tested:**
- Backend and worker containerization.
- Frontend containerization.
- Docker Compose local environment.
- End-to-end background task execution.
- GitHub CI workflow.
- Google Cloud WIF authentication.

**Implemented but not deployed:**
- Terraform cloud infrastructure.
- Redis cloud configuration.
- GitHub CD workflow.

Full cloud deployment and cloud logging verification remain pending infrastructure provisioning and cost eligibility checks.

## Conclusion

This assignment helped me understand how an application moves from a local development environment towards a cloud deployment.

I worked on containerization, service communication, CI automation, cloud authentication and infrastructure as code.

The local application and CI pipeline were successfully tested. The cloud deployment configuration is prepared for the next stage.
