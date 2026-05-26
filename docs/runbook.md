# MedFlow Runbook

## Local Startup

```bash
make dev
```

## Local Shutdown

```bash
make down
```

## Run Tests

```bash
make test
```

## Health Checks

```bash
curl http://localhost:8001/health
```

Expected response:

```json
{"status":"ok","service":"medflow-auth-service","environment":"local"}
```

## Common Issues

### Docker port already in use

Change the host port in `docker-compose.yml` or stop the process using the port.

### Auth service cannot connect to PostgreSQL

Check container health:

```bash
docker compose ps
```

Check logs:

```bash
docker compose logs postgres auth-service
```

### Tests cannot import app package

Run tests from the service directory:

```bash
cd src/services/auth-service
python3 -m pytest
```

