INSERT INTO service_bootstrap_log (service_name)
VALUES ('medflow-local')
ON CONFLICT DO NOTHING;

