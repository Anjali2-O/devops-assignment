import os
from celery import Celery
import time

# Read Redis configuration from the environment.
# The default supports running the application directly on Windows.
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")

# Configure Celery to use Redis as the message broker
celery = Celery(
    "worker",  # This is the name of your Celery application
    broker=REDIS_URL,  # This is the Redis connection string
    backend=REDIS_URL,  # for storing task results
)


@celery.task
def write_log_celery(message: str):
    time.sleep(10)
    with open("log_celery.txt", "a") as f:
        f.write(f"{message}\n")
    return f"Task completed: {message}"

