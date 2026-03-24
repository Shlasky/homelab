# Monitoring Stack

**URL:** https://monitor.ashlasky.com (Grafana), https://prometheus.ashlasky.com (Prometheus)
**Path:** `/srv/infra/monitoring/`
**Ports:** 9090 (Prometheus), 3000 (Grafana, internal), 3100 (Loki, internal), 3200 (Tempo, internal), 9093 (Alertmanager, internal)

---

## Purpose

Full observability stack: metrics (Prometheus + exporters), log aggregation (Loki + Promtail), distributed tracing (Tempo), dashboards (Grafana), and alerting (Alertmanager). Covers system resources, Docker containers, Traefik, PostgreSQL, and hardware health.

---

## Quick Info

- **Docker Compose:** `/srv/infra/monitoring/docker-compose.yaml`
- **Prometheus config:** `/srv/infra/monitoring/prometheus/prometheus.yml`
- **Alert rules:** `/srv/infra/monitoring/prometheus/alerts/`
- **Grafana provisioning:** `/srv/infra/monitoring/grafana/provisioning/`
- **Grafana data:** `/srv/infra/monitoring/grafana/data/`
- **Networks:** `monitoring` (internal), `traefik_admin` (Grafana, Prometheus, Loki, Alertmanager, Tempo)

---

## Stack Components

| Container | Image | Role |
|-----------|-------|------|
| `prometheus` | `prom/prometheus` | Metrics collection and alert evaluation |
| `grafana` | `grafana/grafana` | Dashboards and visualization |
| `loki` | `grafana/loki` | Log aggregation |
| `promtail` | `grafana/promtail` | Log collector (reads Docker socket + Traefik logs) |
| `tempo` | `grafana/tempo` | Distributed tracing backend |
| `alertmanager` | `prom/alertmanager` | Alert routing and deduplication |
| `node-exporter` | `prom/node-exporter` | Host system metrics (CPU, memory, disk, network) |
| `cadvisor` | `gcr.io/cadvisor/cadvisor` | Docker container resource metrics |
| `smartctl-exporter` | `prometheuscommunity/smartctl-exporter` | Drive SMART health metrics |

PostgreSQL exporter lives in the postgres stack (`/srv/infra/db/postgres/`), not here — it joins the `monitoring` network so Prometheus can scrape it.

---

## Scrape Targets

| Job | Target | What it covers |
|-----|--------|----------------|
| `prometheus` | `localhost:9090` | Prometheus self-metrics |
| `node-exporter-mothership` | `node-exporter:9100` | Host CPU, memory, disk, network |
| `cadvisor-mothership` | `cadvisor:8080` | Container resource usage |
| `node-exporter-pi` | `10.0.0.49:9100` | Raspberry Pi host metrics |
| `cadvisor-pi` | `10.0.0.49:8081` | Raspberry Pi container metrics |
| `traefik` | `traefik:8082` | Traefik request/error/latency metrics |
| `traefik-pi` | `10.0.0.49:8082` | Pi Traefik metrics |
| `mongodb` | `mongo-exporter.monitoring:9216` | MongoDB connections, ops, replication |
| `postgres` | `postgres-exporter:9187` | PostgreSQL connections, queries, cache |
| `smartctl` | `smartctl-exporter:9633` | Drive SMART attributes and health |

---

## Grafana Datasources (auto-provisioned)

Datasources are provisioned from file on startup — no manual configuration needed after a fresh deploy.

**File:** `grafana/provisioning/datasources/datasources.yml`

| Name | UID | URL | Default |
|------|-----|-----|---------|
| Prometheus | `prometheus` | `http://prometheus:9090` | Yes |
| Loki | `loki` | `http://loki:3100` | No |
| Tempo | `tempo` | `http://tempo:3200` | No |

**Why this matters:** Before provisioning was added, datasources had to be manually wired up through the UI after every fresh deploy. Now they appear automatically.

**Cross-datasource links configured:**
- Loki → Tempo: log lines containing `traceID=<id>` get a clickable link to the trace
- Tempo → Loki: trace spans link back to the corresponding log lines
- Tempo → Prometheus: service map uses Prometheus as the metrics source

---

## Grafana Dashboards (auto-provisioned)

Dashboards are loaded from `grafana/provisioning/dashboards/` on startup.

**File:** `grafana/provisioning/dashboards/dashboards.yml`

| Dashboard | Source | What it shows |
|-----------|--------|---------------|
| Node Exporter Full | Grafana ID 1860 | CPU, memory, disk I/O, network per host |
| cAdvisor / Docker | Grafana ID 14282 | CPU, memory, network per container |
| Traefik 2 & 3 | Grafana ID 17346 | Request rate, error rate, latency by service/router |
| PostgreSQL | Grafana ID 9628 | Connections, query throughput, cache hit ratio, locks |
| SMARTctl Exporter | Grafana ID 22604 | Drive health status, temperature, wear indicators |
| Loki / Docker Logs | Custom | Docker container log streams |

**How provisioning works:** Each `.json` file in the dashboards directory is loaded automatically. The `${DS_PROMETHEUS}` input placeholders in downloaded community dashboards were patched to the literal UID `prometheus` so they resolve against the provisioned datasource without manual import steps.

To update a dashboard to a newer version from Grafana:
```bash
curl -s "https://grafana.com/api/dashboards/<ID>/revisions/latest/download" \
  -o /srv/infra/monitoring/grafana/provisioning/dashboards/<file>.json

# Patch datasource UIDs
sed -i 's/\${DS_PROMETHEUS}/prometheus/g' /srv/infra/monitoring/grafana/provisioning/dashboards/<file>.json
```

---

## PostgreSQL Exporter

**Where it lives:** `/srv/infra/db/postgres/docker-compose.yaml` (alongside the postgres service)

**Why it's in the postgres stack and not monitoring:** The exporter needs to reach the `postgres` container by name, which requires being on the `postgres` network. It joins both `postgres` (to query the DB) and `monitoring` (to be scraped by Prometheus). This follows the same pattern as `mongo-exporter` in the MongoDB stack.

**Configuration:**

`.env` in `/srv/infra/db/postgres/`:
```
DATA_SOURCE_NAME=postgresql://postgres:<password>@postgres:5432/postgres?sslmode=disable
```

The exporter reads this env var directly — no other configuration needed.

**Metrics exposed on port 9187.** Prometheus scrapes it via the `monitoring` network as `postgres-exporter:9187`.

---

## SMART / Hardware Monitoring

**Container:** `smartctl-exporter` in `/srv/infra/monitoring/docker-compose.yaml`

**Why it needs `privileged: true`:** The exporter calls `smartctl` directly against block devices, which requires raw ATA/SCSI access. This cannot be done without elevated privileges. The `/dev:/dev:ro` mount exposes all block devices read-only.

**Why this exists:** A 16TB HDD failed without any warning. SMART monitoring provides early-warning signals — reallocated sectors, pending sectors, and uncorrectable errors all precede physical failure by days to weeks in most cases.

**Metrics exposed on port 9633.** Check that data is flowing after deploy:
```bash
curl -s http://localhost:9633/metrics | grep smartctl_device_smart_healthy
```

---

## Alert Rules

Alert rules live in `/srv/infra/monitoring/prometheus/alerts/`. Prometheus hot-reloads these when the file changes (requires the `--web.enable-lifecycle` flag, which is set).

### `server-alerts.yml`

| Alert | Condition | Severity | Fires after |
|-------|-----------|----------|-------------|
| `InstanceDown` | `up == 0` | critical | 1m |
| `DiskSpaceCritical` | < 10% free on `/` or `/mnt/*` | critical | 5m |
| `DiskSpaceWarning` | < 15% free on `/` or `/mnt/*` | warning | 10m |
| `MemoryCritical` | > 95% used | critical | 5m |
| `MemoryWarning` | > 85% used | warning | 10m |
| `HighCPUUsage` | > 80% for 15 minutes | warning | 15m |
| `ContainerRestarted` | `container_restart_count` increased in last 5m | warning | 1m |
| `ContainerRestartLoop` | restart rate > 0.5/min over 15m | critical | 5m |
| `ContainerHighMemory` | > 90% of memory limit | warning | 5m |
| `TraefikHighErrorRate` | > 0.05 req/s returning 5xx | critical | 5m |
| `TraefikBackendDown` | `traefik_service_server_up == 0` | warning | 1m |
| `MongoDBDown` | `mongodb_up == 0` | critical | 1m |
| `MongoDBHighConnections` | > 80% of available connections | warning | 5m |
| `PrometheusStorageAlmostFull` | root disk > 85% used | warning | 10m |

### `hardware-alerts.yml`

All hardware alerts use `for: 0m` — they fire immediately because hardware errors are not transient.

| Alert | Condition | Severity |
|-------|-----------|----------|
| `SmartDiskUnhealthy` | SMART overall health == failed | critical |
| `SmartDiskReallocatedSectors` | Reallocated sectors > 0 | critical |
| `SmartDiskPendingSectors` | Current pending sectors > 0 | warning |
| `SmartDiskUncorrectable` | Offline uncorrectable errors > 0 | critical |
| `SmartDiskHighTemp` | Drive temperature > 55°C | warning |
| `SmartDiskCriticalTemp` | Drive temperature > 65°C | critical |

### Bugs fixed in this refactor

**`PrometheusStorageAlmostFull`** was always evaluating to exactly 100% because the expression divided the metric by itself:
```promql
# Before (broken — always 100%)
(prometheus_tsdb_storage_blocks_bytes / prometheus_tsdb_storage_blocks_bytes) * 100 > 85

# After — checks actual root disk usage
(1 - node_filesystem_avail_bytes{mountpoint="/",job="node-exporter-mothership"} / node_filesystem_size_bytes{mountpoint="/",job="node-exporter-mothership"}) * 100 > 85
```

**`ContainerRestarted` and `ContainerRestartLoop`** were using `container_last_seen` — a gauge that reports how recently a container was seen. Its rate is always > 0 while the container is running, so these alerts would fire constantly for every running container:
```promql
# Before (broken — fires for every running container)
rate(container_last_seen{name!=""}[5m]) > 0

# After — uses the actual restart counter
increase(container_restart_count{name!=""}[5m]) > 0
rate(container_restart_count{name!=""}[15m]) * 60 > 0.5
```

**`PrometheusScrapeFailure`** was an exact duplicate of `InstanceDown` with the same expression (`up == 0`) and a longer `for` duration. Removed entirely.

---

## Notes

### Gotchas

- **Grafana runs as user 1000:1000** — the `grafana/data/` directory must be owned by uid 1000 on the host, or Grafana will fail to write. If you see permission errors: `chown -R 1000:1000 /srv/infra/monitoring/grafana/data/`
- **Prometheus runs as user 1000:1000** — same applies to `prometheus/data/`
- **`smartctl-exporter` requires `privileged: true`** — this is intentional and necessary for SMART device access
- **Tempo ports 4317/4318/14268 are bound to the host** — for receiving traces from applications outside Docker
- **Alert receivers are not configured** — Alertmanager is running but routes to no destinations yet. Alerts fire and are visible in the Alertmanager UI and Grafana Alerting, but no notifications are sent. Wiring up receivers (n8n webhook, email, etc.) is a separate task.
- **Pi scrape targets** (`node-exporter-pi`, `cadvisor-pi`, `traefik-pi`) point to `10.0.0.49` — if the Pi is offline, these show as `DOWN` in the targets list. This is expected and does not affect mothership monitoring.

### Dependencies

- `traefik_admin` network must exist (created by the Traefik stack)
- `monitoring` network is owned by this stack — other services join it as `external: true`
- `postgres-exporter` (in the postgres stack) must be running for the `postgres` scrape target to be healthy

### Reloading config without restart

Prometheus supports hot-reload — changes to `prometheus.yml` and alert rule files take effect without restarting the container:
```bash
curl -X POST http://localhost:9090/-/reload
```

Grafana picks up provisioning changes (datasources, dashboards) on restart only. Dashboards saved via the UI are live immediately.

---

## Usage

### Deploy / redeploy

```bash
# First time or after adding postgres-exporter
cd /srv/infra/db/postgres && docker compose up -d

# Monitoring stack
cd /srv/infra/monitoring && docker compose up -d --force-recreate
```

### Verify all scrape targets are UP

```bash
curl -s http://localhost:9090/api/v1/targets \
  | python3 -c "import json,sys; [print(t['labels']['job'], t['health']) for t in json.load(sys.stdin)['data']['activeTargets']]"
```

### Check SMART metrics are flowing

```bash
curl -s http://localhost:9633/metrics | grep smartctl_device_smart_healthy
curl -s http://localhost:9633/metrics | grep 'smartctl_device_attribute.*Temperature'
```

### Check Prometheus storage retention

```bash
# Data is kept for 30 days (--storage.tsdb.retention.time=30d)
du -sh /srv/infra/monitoring/prometheus/data/
```

### Adding a new scrape target

1. Add a job to `prometheus/prometheus.yml`:
```yaml
- job_name: 'my-service'
  static_configs:
    - targets: ['container-name:port']
      labels:
        instance: my-service
        server: mothership
```
2. Ensure the target container is on the `monitoring` network
3. Reload Prometheus: `curl -X POST http://localhost:9090/-/reload`

### Adding a new dashboard

Drop any Grafana dashboard JSON into `grafana/provisioning/dashboards/`. If the dashboard uses `${DS_PROMETHEUS}`, patch it first:
```bash
sed -i 's/\${DS_PROMETHEUS}/prometheus/g' my-dashboard.json
```
Then restart Grafana to pick it up:
```bash
cd /srv/infra/monitoring && docker compose restart grafana
```

---
