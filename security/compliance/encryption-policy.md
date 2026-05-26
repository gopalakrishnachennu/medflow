# Encryption Policy

MedFlow should use encryption in transit and at rest:

- TLS for external traffic
- Istio mTLS for internal service traffic
- KMS encryption for RDS, S3, EBS, and Secrets Manager
- Password hashing with adaptive algorithms
- No plaintext secrets in Git

