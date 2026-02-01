# MongoDB

**URL:** https://mongo.ashlasky.com (Mongo Express UI)
**Path:** `/srv/db/mongodb/`
**Port:** 27017 (MongoDB), 8081 (Mongo Express)

---

## Purpose

NoSQL database for applications requiring document storage with web-based management UI (Mongo Express).

---

## Quick Info

- **Docker Compose:** `/srv/db/mongodb/docker-compose.yaml`
- **Data:** `/srv/db/mongodb/data/`
- **Config:** `/srv/db/mongodb/config/`
- **Networks:** `mongodb` (internal), `traefik_admin` (Mongo Express only)

---

## Notes

### Gotchas
- MongoDB port 27017 is **exposed to host** (not just Docker network)
- Mongo Express has **basic auth** (separate from MongoDB auth)
- Health check runs every 10s with 5s timeout, 5 retries
- Resource limits: 4GB RAM max, 2 CPU cores, 512MB reserved
- Runs with `--auth` flag (authentication required)
- Prometheus exporter available on port 9216

### Dependencies
- None (core infrastructure)

### Important Config
- **Authentication:**
  - MongoDB: `MONGO_ROOT_USER`, `MONGO_ROOT_PASSWORD`
  - Mongo Express: `MONGO_EXPRESS_USER`, `MONGO_EXPRESS_PASSWORD`
- **Three containers:**
  1. `mongodb` - Main database
  2. `mongo-express` - Web UI (admin network only)
  3. `mongo-exporter` - Prometheus metrics exporter

---

## Usage

### Connect to MongoDB
```bash
# From host
mongosh mongodb://localhost:27017 -u <user> -p <password>

# From container
docker exec -it mongodb mongosh -u ${MONGO_ROOT_USER} -p ${MONGO_ROOT_PASSWORD}
```

### Access Mongo Express
- Web UI at https://mongo.ashlasky.com
- Use `MONGO_EXPRESS_USER` and `MONGO_EXPRESS_PASSWORD` for login

### Metrics
- Prometheus metrics endpoint: `http://<server-ip>:9216/metrics`
- Exporter runs in `--compatible-mode` with `--collect-all` flags

---
