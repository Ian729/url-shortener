# URL Shortener

A simple, fast, and clean URL shortener application built with FastAPI and Redis. This project provides a web interface to create short, shareable links and a 1-click deployment script using Docker.

## Features

*   **Fast and Efficient**: Built with FastAPI for high performance.
*   **Simple Web Interface**: A clean and minimal UI for shortening URLs.
*   **Dockerized**: Comes with a `Dockerfile` and a 1-click deployment script for easy setup.
*   **Scalable**: Uses Redis as a backend for efficient storage and retrieval of URLs.

## Architecture

The application consists of the following components:

*   **FastAPI Application (`main.py`)**: A Python web server that handles the following:
    *   Serves the frontend application (`static/index.html`).
    *   Provides an API endpoint (`/shorten`) to create short URLs.
    *   Redirects short URLs to their original destination.
*   **Redis**: An in-memory data store used to store the mapping between short codes and original URLs.
*   **Docker**: The application is containerized using Docker for portability and ease of deployment.
*   **Deployment Script (`deploy.sh`)**: A shell script that automates the entire deployment process, including building the Docker image, setting up a Docker network, and starting the application and Redis containers.

## Usage

### Prerequisites

*   [Docker](https://docs.docker.com/get-docker/) installed on your system.

### 1-Click Deployment

The included `deploy.sh` script automates the entire deployment process. To deploy the application, simply run the following command in your terminal:

```bash
./deploy.sh
```

This script will:

1.  Build the Docker image for the application.
2.  Create a Docker network for the application and Redis containers to communicate.
3.  Stop and remove any old containers to ensure a clean start.
4.  Start the Redis container.
5.  Start the URL shortener application container.

Once the script has finished, the application will be accessible at [http://localhost:8000](http://localhost:8000).

### Manual Deployment

If you prefer to deploy the application manually, you can follow these steps:

1.  **Build the Docker image**:
    ```bash
    docker build -t url-shortener .
    ```

2.  **Create a Docker network**:
    ```bash
    docker network create url-net
    ```

3.  **Start the Redis container**:
    ```bash
    docker run -d --name redis-server --network url-net redis
    ```

4.  **Start the application container**:
    ```bash
    docker run -d -p 8000:8000 --network url-net -e REDIS_URL=redis://redis-server:6379/0 --name url-shortener-app url-shortener
    ```

The application will then be available at [http://localhost:8000](http://localhost:8000).
