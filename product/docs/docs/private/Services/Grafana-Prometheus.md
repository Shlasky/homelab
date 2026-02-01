# Grafana + Prometheus

**URL:** https://monitor.ashlasky.com (Grafana), https://prometheus.ashlasky.com (Prometheus)
**Path:** [TODO: Confirm location - possibly on Raspberry Pi backup?]
**Port:** [TODO: Confirm ports]

---

## Purpose

Monitoring stack - Prometheus collects metrics, Grafana visualizes them with dashboards.

---

## Quick Info

- **Docker Compose:** [TODO: Location not found in /srv/monitor/]
- **Data:** [TODO: Confirm data locations]
- **Network:** [TODO: Confirm network - likely traefik_admin]

---

## Notes

### Gotchas
- [TODO: Running on Raspberry Pi as backup/secondary?]
- Grafana accessible at https://monitor.ashlasky.com
- Prometheus at https://prometheus.ashlasky.com
- [TODO: Document retention policies]
- [TODO: Document scrape configs]

### Dependencies
- Node Exporter (host metrics)
- cAdvisor (container metrics)
- MongoDB Exporter (database metrics)
- Traefik metrics endpoint (port 8082)

### Important Config
- [TODO: Prometheus scrape targets]
- [TODO: Grafana datasource configuration]
- [TODO: Dashboard imports/backups]

---

## Usage

[TODO: Add common tasks]
- Adding new scrape targets
- Importing dashboards
- Creating alerts
- Backup/restore procedures

---
