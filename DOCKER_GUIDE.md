# Minisource Docker Development Guide

## Overview

This guide explains the Docker setup for Minisource microservices. Each service follows a consistent pattern with separate configurations for development and production.

## Port Allocation

To avoid conflicts when running multiple services locally, each service uses unique database ports:

| Service   | App Port | PostgreSQL Port | Redis Port |
|-----------|----------|-----------------|------------|
| Infra     | -        | 5432            | 6379       |
| Auth      | 9001     | 5433            | 6380       |
| Notifier  | 9002     | 5434            | 6381       |
| Template  | 8080     | 5435            | 6382       |

## Quick Start

### Option 1: Shared Infrastructure (Recommended)

Use the shared infrastructure for all services:

```bash
# Start shared PostgreSQL and Redis
cd infra
cp .env.dev .env
docker compose -f docker-compose.dev.yml up -d

# Optional: Include dev tools (Adminer, Redis Commander, MailHog, MinIO)
docker compose -f docker-compose.dev.yml --profile tools up -d
# Or only email + object storage:
docker compose -f docker-compose.dev.yml --profile tools up -d mailhog minio minio-setup
```

Then run each service locally:

```bash
# In auth directory
cd auth
go run ./cmd/main.go

# In notifier directory  
cd notifier
go run ./cmd/server
```

### Option 2: Per-Service Infrastructure

Each service can run its own database containers:

```bash
# Auth service with its own databases
cd auth
cp .env.dev .env
docker compose -f docker-compose.dev.yml up -d
go run ./cmd/main.go

# Notifier service with its own databases
cd notifier
cp .env.dev .env
docker compose -f docker-compose.dev.yml up -d
go run ./cmd/server
```

## Directory Structure

```
service/
├── .env.dev              # Development environment template
├── .env.prod             # Production environment template
├── .env                  # Active environment (git-ignored)
├── .dockerignore         # Files to exclude from Docker build
├── docker-compose.yml    # Default (points to prod)
├── docker-compose.dev.yml    # Development infrastructure
├── docker-compose.prod.yml   # Production with full security
├── Dockerfile            # Multi-stage production build
└── scripts/
    └── init-db.sql       # Database initialization
```

## Environment Files

### Development (.env.dev)
- Weak passwords for local development
- Exposed ports for debugging
- Debug logging enabled
- No SSL/TLS required

### Production (.env.prod)
- Strong, unique passwords (MUST CHANGE!)
- No exposed database ports
- Info-level logging
- SSL/TLS required

## Docker Compose Variants

### Development (docker-compose.dev.yml)
- **Infrastructure only** - no app container
- Exposed ports for local debugging
- Optional dev tools (Adminer, Redis Commander)
- Less resource constraints
- Shared network for all services

### Production (docker-compose.prod.yml)
- Full application stack
- Pre-built images from [Docker Hub (`minisource`)](https://hub.docker.com/orgs/minisource/repositories)
- **No exposed database ports** (security)
- Internal network for database isolation
- Resource limits configured
- Security options enabled
- JSON file logging with rotation

```bash
# Pull the latest image and start production stack
export TAG=latest
docker compose -f docker-compose.prod.yml up -d
```

## CI/CD (GitHub Actions → Docker Hub)

Each service repository builds a Docker image on push/PR and pushes to Docker Hub after a successful build on the default branch (`main` or `master`).

Configure these secrets in **Settings → Secrets and variables → Actions**:

| Secret | Description |
|--------|-------------|
| `DOCKERHUB_USERNAME` | Docker Hub username or organization |
| `DOCKERHUB_TOKEN` | Docker Hub access token |

Published image format: `minisource/<service>:latest` and `minisource/<service>:<short-sha>`.

## Security Best Practices

### Production Checklist

1. **Change all default passwords** in `.env`:
   ```bash
   # Generate secure passwords
   openssl rand -base64 32
   ```

2. **Database ports are NOT exposed**:
   - Uses `expose` instead of `ports`
   - Only accessible within Docker network

3. **Read-only filesystem** for app containers:
   ```yaml
   read_only: true
   tmpfs:
     - /tmp
   ```

4. **No new privileges**:
   ```yaml
   security_opt:
     - no-new-privileges:true
   ```

5. **Resource limits**:
   ```yaml
   deploy:
     resources:
       limits:
         cpus: '1'
         memory: 512M
   ```

## Common Commands

```bash
# Start development infrastructure
docker compose -f docker-compose.dev.yml up -d

# Start with dev tools
docker compose -f docker-compose.dev.yml --profile tools up -d

# View logs
docker compose -f docker-compose.dev.yml logs -f

# Stop all containers
docker compose -f docker-compose.dev.yml down

# Remove volumes (CAUTION: deletes data)
docker compose -f docker-compose.dev.yml down -v

# Production deployment
cp .env.prod .env
# Edit .env with secure values!
docker compose -f docker-compose.prod.yml up -d
```

## Network Architecture

### Development
```
┌─────────────────────────────────────────────────────┐
│                 minisource-dev network               │
│                                                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│  │ postgres │  │  redis   │  │ mailhog  │          │
│  │  :5432   │  │  :6379   │  │  :8025   │          │
│  └────┬─────┘  └────┬─────┘  └──────────┘          │
│       │             │                               │
│       └──────┬──────┘                               │
│              │                                       │
│     Local services connect via localhost             │
└─────────────────────────────────────────────────────┘
```

### Production
```
┌───────────────────────────────────────────────────────┐
│              minisource-network (external)            │
│                                                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │
│  │    auth     │  │  notifier   │  │   gateway   │  │
│  │   :9001     │  │    :9002    │  │    :8080    │  │
│  └──────┬──────┘  └──────┬──────┘  └─────────────┘  │
└─────────┼────────────────┼───────────────────────────┘
          │                │
    ┌─────┴─────┐    ┌─────┴─────┐
    │auth-internal│  │notifier-internal│ (internal networks)
    │           │    │             │
    │┌─────────┐│    │┌───────────┐│
    ││postgres ││    ││ postgres  ││
    ││ (no port)│    ││ (no port) ││
    │└─────────┘│    │└───────────┘│
    └───────────┘    └─────────────┘
```

## Troubleshooting

### Port already in use
```bash
# Find process using port
netstat -ano | findstr :5432
# or on Linux/Mac
lsof -i :5432
```

### Container won't start
```bash
# Check logs
docker compose -f docker-compose.dev.yml logs postgres

# Check container status
docker ps -a
```

### Database connection issues
```bash
# Test PostgreSQL connection
docker exec -it minisource-dev-postgres psql -U postgres -l

# Test Redis connection  
docker exec -it minisource-dev-redis redis-cli ping
```

### Reset everything
```bash
# Stop and remove all containers, networks, volumes
docker compose -f docker-compose.dev.yml down -v
docker system prune -f
```
