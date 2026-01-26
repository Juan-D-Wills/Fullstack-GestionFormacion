# Docker Compose Deployment Guide

This guide explains how to use Docker Compose to deploy both the development and production environments for the Fullstack Gestion Formación application.

## Table of Contents

- [Overview](#overview)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Docker Compose Files](#docker-compose-files)
- [Environment Setup](#environment-setup)
- [Development Environment](#development-environment)
- [Production Environment](#production-environment)
- [Docker Override Files](#docker-override-files)
- [Common Commands](#common-commands)
- [Troubleshooting](#troubleshooting)

## Overview

This project uses Docker Compose to manage multi-container applications with:

- **Frontend**: Node.js + Vite application served with Nginx (production) or dev server (development)
- **Backend**: FastAPI Python application with hot-reload capabilities (development)
- **Database**: MySQL database service

The setup supports two docker profiles:

- `dev` - Development environment with hot-reload and debugging tools
- `prod` - Production-ready environment with optimized images and performance configurations

## Project Structure

```markdown
Fullstack-GestionFormacion/
├── docker-compose.yml           # Main compose file with all services
├── GestionFormacion/            # Backend (FastAPI)
│   ├── back.Dockerfile
│   ├── main.py
│   └── pyproject.toml
├── GestionFormacionFrontEnd/    # Frontend (Node.js + Vite)
│   ├── front.Dockerfile
│   ├── package.json
│   └── vite.config.ts
├── DB                           # Data base configurations
|   └── db_shema.sql
└── .env.example                 # Environment variables example
```

## Prerequisites

Before deploying, ensure you have installed:

- **Docker**: v20.10+
- **Docker Compose**: v2.0+
- **Git**: For cloning the repository

### Installation Commands

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install docker.io docker-compose-plugin

# Verify installation
docker --version
docker compose version
```

## Docker Compose Files

### `docker-compose.yml` (Main File)

This is the primary configuration file that defines all services:

- **Services Defined**:
  - `frontend-dev`: Frontend development server (profile: dev)
  - `backend-dev`: Backend development server (profile: dev)
  - `nginx-webserver`: Production frontend with Nginx (profile: prod)
  - `fastapi-services`: Production backend server (profile: prod)
  - `db`: MySQL database (always running, shared between dev and prod)

- **Profiles**: Services are organized using Docker Compose profiles to enable/disable services:
  - `dev`: Includes development services with hot-reload
  - `prod`: Includes production-ready services

### `docker-compose.override.yaml` (Development Overrides)

This file extends the base configuration and is **automatically loaded by Docker Compose** during development.

**Default Behavior**:

- When you run `docker compose up` it deploys all services without a profile, so if you want to deploy either development or production enviroment you must specify the profile which services are linked to with the `--profile` flag.
- If an docker override file is present in the same working directory as the docker compose file, it will automatically merges `docker-compose.yml` + `docker-compose.override.yml` when deploying services, regardless of the profile.
- The override file can be ignored if `docker-compose.yml` is specified before the compose up command; if `docker-compose.override.yml` is missing the docker compose command will as in case 1

**Why Use Overrides?**:

- Keep development-specific configurations separate from production
- Avoid accidentally deploying dev configurations to production
- Allow local customizations without modifying the main file

## Environment Setup

### Create `.env` File

The application requires a `.env` file in the project root with the following variables:

```bash
# Database Configuration
DB_NAME=db_name_here
DB_USER=user_here
DB_PASSWORD=your_secure_password_here
DB_ROOT_PASSWORD=your_secure_password_here
```

**Security Note**: Never commit the `.env` file to version control. Add it to `.gitignore`:

```bash
echo ".env" >> .gitignore
```

## Development Environment

### Deploying Development Environment

The development environment enables hot-reload for both frontend and backend.

#### 1. Start Development Services

```bash
# Navigate to project root
cd /path/to/Fullstack-GestionFormacion

# Start all development services
docker compose --profile dev up -d

# Or to omit the override file use
docker compose -f docker-compose.yml --profile dev up -d
```

**What Happens**:

- Frontend container starts with Vite dev server on `http://localhost:8080`
- Backend container starts with FastAPI on `http://localhost:8000`
- MySQL database starts and initializes from `db_schema.sql`
- Volumes mount source code directories for hot-reload
- All containers are connected via `dev-net` network

#### 2. Access Services

- **Frontend**: `http://localhost:8080`
- **Backend API Docs**: `http://localhost:8000/docs`
- **Database**: `localhost:3306` (user: root)

#### 3. View Logs

```bash
# View logs from all services
docker compose logs

# View logs from specific service
docker compose logs -f backend
docker compose logs -f frontend
docker compose logs -f db

# Follow logs in real-time
docker compose logs -f --tail=50
```

#### 4. Stop Development Services

```bash
# Stop all running containers (preserves data)
docker compose --profile dev down

# Stop and remove volumes (deletes database data)
docker compose --profile dev down -v
```

#### 5. Development Workflow

```bash
# Make code changes
# Changes are reflected immediately in running containers

# If you need to rebuild images (e.g., after changing dependencies)
docker compose --profile dev up -d --build

# View real-time logs of your changes
docker compose logs -f
```

## Production Environment

### Deploying Production Environment

Production deployments use optimized images, remove hot-reload capabilities, and serve the frontend via Nginx.

#### 1. Build Images

```bash
# Navigate to project root
cd /path/to/Fullstack-GestionFormacion

# Build production images (frontend and backend only)
docker compose --profile prod build
```

#### 2. Start Production Services

```bash
# Start production services
docker compose -f docker-compose.yml --profile prod up -d
```

```md
**Important Note**
Do NOT use `docker-compose.override.yaml` in production
```

**What Happens**:

- Nginx serves the optimized frontend (static files) on `http://localhost:80`
- FastAPI backend runs without hot-reload on port 8000 (internal)
- MySQL database starts
- All containers connected via `prod-net` network

#### 3. Access Services

- **Frontend**: `http://localhost:80` (or `http://localhost`)
- **Backend API**: Only accessible internally within containers
- **Database**: Not exposed to host (security)

#### 4. View Logs

```bash
# Production logs
docker compose logs

# Specific service
docker compose logs -f fastapi-services
docker compose logs -f nginx-webserver
```

#### 5. Stop Production Services

```bash
# Stop without removing volumes (preserves data)
docker compose --profile prod down
```

#### 6. Update Production Deployment

```bash
# Pull latest code
git pull origin main

# Rebuild images with latest code
docker compose -f docker-compose.yml --profile prod build

# Start updated services
docker compose -f docker-compose.yml --profile prod up -d
```

## Docker Override Files

### What is an Override File?

A Docker Compose override file is an additional configuration file that automatically merges with the main `docker-compose.yml`. By default, Docker Compose looks for `docker-compose.override.yaml` (or `docker-compose.override.yml`).

### When to Use Override Files

#### Use Overrides For

1. **Development-Only Configurations**
   - Exposing ports that shouldn't be exposed in production
   - Volume mounts for hot-reload
   - Environment variables for local development

2. **Local Customizations**
   - Different database credentials for local testing
   - Custom port mappings on your machine
   - Developer-specific settings

3. **Multiple Developer Workflows**
   - Different `docker-compose.dev.override.yaml` for team members
   - Parallel `docker-compose.custom.override.yaml` for special testing

#### ❌ Don't Use Overrides For

- **Production Deployments**

- **CI/CD Pipelines**

### Creating Custom Override Files

If you need development-specific customizations without affecting the tracked `docker-compose.override.yaml`:

```bash
# Create a local-only override file
# Add to .gitignore
echo "docker-compose.local.override.yaml" >> .gitignore

# Use it explicitly
docker compose -f docker-compose.yml -f docker-compose.local.override.yaml up -d
```

## Common Commands

### Starting Services

```bash
# Development (auto-loads override file)
docker compose --profile dev up -d

# Development with build
docker compose --profile dev up -d --build

# Production (ignores override file)
docker compose -f docker-compose.yml --profile prod up -d

# Production with build
docker compose -f docker-compose.yml --profile prod build
docker compose -f docker-compose.yml --profile prod up -d
```

### Viewing Status and Logs

```bash
# List running containers
docker compose ps

# View all logs
docker compose logs -f

# View specific service logs
docker compose logs -f backend
docker compose logs -f frontend
docker compose logs -f db

# Last 100 lines
docker compose logs --tail=100
```

### Managing Services

```bash
# Stop services (preserves data)
docker compose --profile dev down
docker compose -f docker-compose.yml --profile prod down

# Remove containers and volumes
docker compose --profile dev down -v

# Restart services
docker compose restart

# Rebuild images
docker compose --profile dev build
docker compose -f docker-compose.yml --profile prod build

# Remove unused resources
docker system prune -a
```

### Database Management

```bash
# Access MySQL CLI
docker compose exec db mysql -u root -p gestion_formacion

# Backup database
docker compose exec db mysqldump -u root -p gestion_formacion > backup.sql

# Restore database
docker compose exec -T db mysql -u root -p gestion_formacion < backup.sql
```

### Debugging

```bash
# Execute command in running container
docker compose exec backend bash
docker compose exec frontend sh

# View container resource usage
docker stats

# Inspect container details
docker compose exec backend env
docker inspect $(docker compose ps -q backend)

# Check network connectivity
docker compose exec backend ping frontend
```

## Troubleshooting

### Common Issues

#### 1. "Cannot connect to Docker daemon"

```bash
# Solution: Start Docker service
sudo systemctl start docker
sudo usermod -aG docker $USER
# Log out and back in for group changes to take effect
```

#### 2. "Port already in use"

```bash
# Find what's using the port
lsof -i :8080
# Kill the process or change port in docker-compose file
```

#### 3. "Database connection refused"

```bash
# Ensure db service is healthy
docker compose ps db

# Check db logs
docker compose logs db

# Wait for db initialization
docker compose exec db mysql -u root -p -e "SELECT 1"
```

#### 4. "Volume mount permission denied"

```bash
# Fix ownership
sudo chown $USER:$USER ./GestionFormacion
sudo chown $USER:$USER ./GestionFormacionFrontEnd
```

#### 5. "Out of disk space"

```bash
# Clean up unused Docker resources
docker system prune -a --volumes

# Check disk usage
df -h
docker system df
```

#### 6. "Hot-reload not working"

```bash
# Ensure volumes are correctly mounted
docker compose ps
docker compose exec backend ls /app

# Rebuild without cache
docker compose --profile dev build --no-cache
docker compose --profile dev up -d
```

### Debugging Tips

```bash
# Increase logging verbosity
docker compose -f docker-compose.yml --verbose --profile dev up

# Check network connectivity
docker compose exec backend ping db
docker compose exec frontend ping backend

# Verify environment variables
docker compose exec backend env
docker compose config  # View merged configuration

# Check database schema
docker compose exec db mysql -u root -p -e "SHOW TABLES FROM gestion_formacion;"
```

## Performance Optimization

### Development

- Mount individual directories instead of entire project (if experiencing slowness)
- Use named volumes for database to improve performance
- Disable unnecessary logging in development

### Production

- Use read-only volumes where possible
- Set resource limits:

  ```yaml
  services:
    fastapi-services:
      deploy:
        resources:
          limits:
            cpus: '2'
            memory: 1G
  ```

- Enable health checks:

  ```yaml
  services:
    fastapi-services:
      healthcheck:
        test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
        interval: 30s
        timeout: 10s
        retries: 3
  ```

## Additional Resources

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Docker Network Guide](https://docs.docker.com/network/)
- [MySQL Docker Image Documentation](https://hub.docker.com/_/mysql)

## Support and Questions

For issues or questions about the Docker setup:

1. Check the [Troubleshooting](#troubleshooting) section
2. Review container logs: `docker compose logs`
3. Inspect the docker-compose files for service configurations
4. Consult the application's README files in each service directory
