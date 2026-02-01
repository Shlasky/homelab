# cAdvisor

**URL:** http://<server-ip>:8081
**Path:** `/srv/monitor/`
**Port:** 8081 (mapped from container 8080)

---

## Purpose

Container metrics exporter - provides resource usage and performance data for Docker containers to Prometheus.

---

## Quick Info

- **Docker Compose:** `/srv/monitor/docker-compose.yaml`
- **Network:** Host network (direct port exposure)

---

## Notes

### Gotchas
- Runs in **privileged mode** for full container visibility
- Requires `/dev/kmsg` device access
- Container name: `cadvisor-mothership`
- Port 8081 on host maps to 8080 in container
- No Traefik routing (accessed directly)

### Dependencies
- Prometheus (consumes metrics)

### Important Config
- **Volume mounts:**
  - `/:/rootfs:ro` - Host filesystem (read-only)
  - `/var/run:/var/run:rw` - Docker socket access
  - `/sys:/sys:ro` - System info
  - `/var/lib/docker/:/var/lib/docker:ro` - Docker data
  - `/dev/disk/:/dev/disk:ro` - Disk info

---

## Usage

### View Metrics
```bash
curl http://localhost:8081/metrics
```

### Web UI
Navigate to `http://<server-ip>:8081` for web interface

---
