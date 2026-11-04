import os
from celery import Celery
import time

# Read Redis configuration from the environment.
# The default supports running the application directly on Windows.
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")

# GCP Memorystore configuration (used when REDIS_HOST is provided).
REDIS_HOST = os.getenv("REDIS_HOST")

if REDIS_HOST:
    import ssl
    from urllib.parse import quote

    REDIS_PORT = os.getenv("REDIS_PORT", "6379")
    REDIS_PASSWORD = os.getenv("REDIS_PASSWORD")
    REDIS_CA_PATH = os.getenv("REDIS_CA_PATH", "/secrets/redis/ca.crt")

    if not REDIS_PASSWORD:
        raise RuntimeError("REDIS_PASSWORD is required for Memorystore")

    REDIS_URL = (
        f"rediss://:{quote(REDIS_PASSWORD, safe='')}"
        f"@{REDIS_HOST}:{REDIS_PORT}/0"
    )

    redis_ssl_options = {
        "ssl_cert_reqs": ssl.CERT_REQUIRED,
        "ssl_ca_certs": REDIS_CA_PATH,
    }
else:
    redis_ssl_options = None


# Configure Celery to use Redis as the message broker
celery = Celery(
    "worker",  # This is the name of your Celery application
    broker=REDIS_URL,  # This is the Redis connection string
    backend=REDIS_URL,  # for storing task results
)

# Enable TLS for GCP Memorystore.
if redis_ssl_options:
    celery.conf.update(
        broker_use_ssl=redis_ssl_options,
        redis_backend_use_ssl=redis_ssl_options,
    )

@celery.task
def write_log_celery(message: str):
    time.sleep(10)
    with open("log_celery.txt", "a") as f:
        f.write(f"{message}\n")
    return f"Task completed: {message}"

