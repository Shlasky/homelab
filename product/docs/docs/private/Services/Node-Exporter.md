# Node Exporter

**URL:** http://<server-ip>:9100/metrics
**Path:** `/srv/monitor/`
**Port:** 9100

---

## Purpose

Prometheus exporter for hardware and OS-level metrics (CPU, memory, disk, network).

---

## Quick Info

- **Docker Compose:** `/srv/monitor/docker-compose.yaml`
- **Network:** Host network (direct port exposure)

---

## Notes

### Gotchas
- Runs in **privileged mode** to access host metrics
- Mounts host `/proc`, `/sys`, `/` as read-only for metric collection
- Container name: `node-exporter-mothership`
- No Traefik routing (accessed directly via port 9100)

### Dependencies
- Prometheus (consumes metrics)

### Important Config
- **Command flags:**
  - `--path.procfs=/host/proc`
  - `--path.sysfs=/host/sys`
  - `--path.rootfs=/host`
  - `--collector.filesystem.mount-points-exclude` - Excludes system mounts

---

## Usage

### View Metrics
```bash
curl http://localhost:9100/metrics
```

### Check Status
```bash
docker logs node-exporter-mothership
```

---
