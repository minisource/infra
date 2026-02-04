# Minisource Infrastructure

This repository contains Docker Compose configurations for running the infrastructure services required by Minisource microservices.

## Services Included

| Service | Port | Description |
|---------|------|-------------|
| **PostgreSQL** | 5432 | Primary database |
| **Redis** | 6379 | Caching and session storage |
| **Jaeger** | 16686 | Distributed tracing UI |
| **Prometheus** | 9090 | Metrics collection |
| **Grafana** | 3000 | Visualization dashboards |
| **Loki** | 3100 | Log aggregation |
| **OpenTelemetry Collector** | 4317 (gRPC), 4318 (HTTP) | Telemetry collection |

## Quick Start

```bash
# Copy environment file
cp .env.example .env

# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

## Accessing Services

- **Jaeger UI**: http://localhost:16686
- **Grafana**: http://localhost:3000 (admin/admin123)
- **Prometheus**: http://localhost:9090

## Connecting Microservices

### OpenTelemetry Configuration

Add these environment variables to your services:

```env
OTEL_EXPORTER_OTLP_ENDPOINT=localhost:4317
OTEL_SERVICE_NAME=your-service-name
```

### Database Connection

```env
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=your_db_name
```

### Redis Connection

```env
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=redis123
```

## Directory Structure

```
infra/
├── docker-compose.yml           # Main compose file
├── .env.example                  # Environment template
├── config/
│   ├── otel-collector-config.yaml
│   ├── prometheus.yml
│   ├── loki-config.yaml
│   ├── promtail-config.yaml
│   └── grafana/
│       ├── provisioning/
│       │   ├── datasources/
│       │   └── dashboards/
│       └── dashboards/
└── scripts/
    └── init-multiple-dbs.sh     # PostgreSQL init script
```

## Development Profiles

### Minimal Setup (Database + Cache only)

```bash
docker-compose up -d postgres redis
```

### Full Observability Stack

```bash
docker-compose up -d
```

### Without Log Collection

```bash
docker-compose up -d postgres redis jaeger prometheus grafana otel-collector
```

## Volumes

Data is persisted in named volumes:
- `minisource-postgres-data`
- `minisource-redis-data`
- `minisource-jaeger-data`
- `minisource-prometheus-data`
- `minisource-grafana-data`
- `minisource-loki-data`

To reset all data:

```bash
docker-compose down -v
```

## Network

All services are connected to `minisource-network` bridge network. This allows services to communicate using container names as hostnames.

## Grafana Dashboards

Pre-configured dashboards are available:
- **Minisource Overview**: Request rates, response times, error rates

## Troubleshooting

### Check service health
```bash
docker-compose ps
docker-compose logs <service-name>
```

### Restart a specific service
```bash
docker-compose restart <service-name>
```

### View OpenTelemetry Collector status
```bash
curl http://localhost:13133/  # Health check
curl http://localhost:8888/metrics  # Collector metrics
```

### Access PostgreSQL
```bash
docker exec -it minisource-postgres psql -U postgres
```

### Access Redis
```bash
docker exec -it minisource-redis redis-cli -a redis123
```