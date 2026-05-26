.PHONY: dev down test lint build venv install run-auth-local validate

venv:
	python3 -m venv .venv

install:
	. .venv/bin/activate && pip install --upgrade pip && pip install -r src/services/auth-service/requirements.txt

run-auth-local:
	cd src/services/auth-service && ENVIRONMENT=local DATABASE_URL=sqlite+pysqlite:///:memory: JWT_SECRET_KEY=local-dev-only python3 -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8001

dev:
	docker compose up --build

down:
	docker compose down --remove-orphans

test:
	cd src/services/auth-service && python3 -m pytest

lint:
	cd src/services/auth-service && python3 -m ruff check app tests

build:
	docker compose build

validate:
	cd src/services/auth-service && python3 -m ruff check app tests && python3 -m pytest
	helm lint kubernetes/helm-charts/medflow
	helm template medflow kubernetes/helm-charts/medflow -f kubernetes/helm-charts/medflow/values-dev.yaml >/tmp/medflow-rendered.yaml
	terraform -chdir=infrastructure/environments/dev fmt -recursive -check ../..
	terraform -chdir=infrastructure/environments/dev validate
