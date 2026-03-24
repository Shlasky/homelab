# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Docker-based self-hosted infrastructure repository managed through Traefik reverse proxy. The architecture follows a hierarchical, category-based design where services are grouped into top-level directories (`infra/`, `media/`, `product/`, `game-servers/`), each containing standalone service stacks with their own docker-compose configuration.

### Architecture

**Core Infrastructure (`infra/`):**
- **Traefik** (`infra/traefik/`): Reverse proxy with automatic SSL (Let's Encrypt via Cloudflare DNS challenge), metrics endpoint, and centralized routing
  - Two networks: `traefik_public` (internet-facing) and `traefik_admin` (VPN/Tailscale only)
  - Dynamic configuration via file provider (`dynamic/middlewares.yml`, `dynamic/routers/`)
- **MongoDB** (`infra/db/mongodb/`): Database with mongo-express UI and Prometheus exporter, dedicated `mongodb` network
- **PostgreSQL** (`infra/db/postgres/`): PostgreSQL 16 database with pgAdmin UI, dedicated `postgres` network. Used by Dockhand and n8n.
- **Docker Registry** (`infra/registry/`): Private registry with token-based auth via cesanta/docker_auth
- **GitHub Runners** (`infra/github-runners/`): Self-hosted runners for GitHub Actions (org-level)
- **Monitoring** (`infra/monitoring/`): Grafana, Prometheus, Loki, Tempo, Alertmanager, Promtail, Node-exporter, and cAdvisor
- **Dockhand** (`infra/dockhand/`): Docker stack management with PostgreSQL backend, adopts local stacks via `/srv` mount
- **n8n** (`infra/n8n/`): Workflow automation tool with PostgreSQL backend

**Media Stack (`media/`):**
- **Jellyfin** (`media/jellyfin/`): Media server with dual routing (`tv.${DOMAIN}` and `jellyfin.${DOMAIN}`), includes Jellyseerr request management
- **Arr stack** (`media/arr/`): Sonarr (TV), Radarr (movies), Bazarr (subtitles), Prowlarr (indexer manager)
- **Torrent** (`media/torrent/`): qBittorrent torrent client routing through Gluetun VPN container (`network_mode: service:gluetun`)
- **Media Tools** (`media/media-tools/`): FFsubsync, yt-dlp, MKVToolNix, and a media controller service

**Products (`product/`):**
- **Homepage** (`product/homepage/admin/` and `product/homepage/public/`): Each subdirectory is a standalone stack — admin dashboard and public landing page
- **Docs** (`product/docs/`): MkDocs-based documentation (wiki + docs-admin sites served via nginx)
- **SP** (`product/sp/`): Super Productivity + WebDAV

**Game Servers (`game-servers/`):**
- **Minecraft** (`game-servers/minecraft/`): Minecraft server (direct ports, no Traefik)
- **Satisfactory** (`game-servers/satisfactory/`): Satisfactory dedicated server (direct ports, no Traefik)
- **Playit** (`game-servers/playit/`): Playit.gg tunnel for game server connectivity (host networking)

---

### Routing Architecture

**The standard routing method is the Traefik file provider.** Services are registered in the dynamic router files, not via Docker labels.

**Docker labels are legacy** — the following services still use them and should be migrated:
- `infra/registry/` — registry + registry-auth
- `media/torrent/` — gluetun (exposes qBittorrent)
- `media/media-tools/` — mkvtoolnix
- `product/sp/` — super-productivity + webdav

**Dynamic router files** (`infra/traefik/dynamic/routers/`):
- `infra.yaml` — infrastructure services (traefik dashboard, mongo-express, grafana, prometheus, loki, tempo, alertmanager, dockhand, pgadmin, n8n)
- `media.yaml` — media services (jellyfin, jellyseerr, radarr, sonarr, bazarr, prowlarr)
- `product.yaml` — product services (homepage-admin, homepage-public, wiki, docs-admin)

**File provider routing template:**
```yaml
# In dynamic/routers/<category>.yaml
# Add a router entry:
http:
  routers:
    <service>:
      <<: *admin-base        # or define inline for public services
      rule: "Host(`<service>.{{ env \"DOMAIN\" }}`)"
      service: <service>

  services:
    <service>:
      loadBalancer:
        servers:
          - url: "http://<container-name>:<port>"
```

The `*admin-base` anchor (defined at the top of each router file) sets `entrypoints: [websecure]`, `tls.certResolver: letsencrypt`, and `middlewares: [security-headers@file]`. Override middlewares inline when you need extras (e.g., `compression@file`).

The service's docker-compose must connect the container to `traefik_admin` (or `traefik_public`) so Traefik can reach it by container name — **no labels needed**.

---

### Network Architecture

**Two-Domain Strategy:**
- `${DOMAIN}`: Public domain (internet-facing services)
- `${ADMIN_DOMAIN}`: Admin domain (VPN/Tailscale-only services) — used in some older label-based configs

**Network Segmentation:**
- `traefik_public`: Internet-facing services (Registry, Jellyfin, Jellyseerr, Homepage public, Docs)
- `traefik_admin`: Admin/VPN-only services (arr stack, dashboards, monitoring UIs, dockhand, n8n)
- `mongodb`: Internal — MongoDB, mongo-express, mongo-exporter
- `postgres`: Internal — PostgreSQL, pgAdmin, Dockhand, n8n
- `monitoring`: Internal — Prometheus, Grafana, Loki, Tempo, Alertmanager, Promtail, node-exporter, cAdvisor

Service-specific networks are declared with `name:` and `driver: bridge` in the owning stack, and referenced as `external: true` in all other stacks that join them.

---

### Traefik Configuration

**Static config** (`infra/traefik/traefik.yml`):
- Entry points: web (80→443 redirect), websecure (443), metrics (8082)
- Cloudflare DNS challenge for Let's Encrypt certificates
- Docker provider with `exposedByDefault: false`
- File provider watching `dynamic/` for hot-reload

**Dynamic config** (`infra/traefik/dynamic/middlewares.yml`):
- `security-headers@file`: HSTS, CSP, XSS protection
- `compression@file`: Gzip compression
- `cloudflare-ips@file`: IP whitelist for Cloudflare
- `admin-network@file`: Tailscale/local network IP whitelist
- `rate-limit@file`: 100 req/min with burst of 50
- `registry-auth-transport@file`: Skip TLS verification for registry auth

---

### Environment Variables

All services use environment variables from `.env` files (not committed). Common variables:
- `TZ`: Timezone
- `DOMAIN`: Public domain
- `PUID` / `PGID`: User/group IDs (typically 1000:1000 for linuxserver images)
- Service-specific variables use a service-prefix convention: `N8N_*`, `DOCKHAND_*`, `POSTGRES_*`, `MONGO_*`, `GRAFANA_*`

---

## Service Standards

These conventions apply to all services in this repo.

### Restart Policy
- `restart: always` — Traefik and GitHub Runners (must recover after host reboot without user intervention)
- `restart: unless-stopped` — everything else

### Volumes
- **Bind mounts only** — no Docker named volumes anywhere in this repo
- Relative paths for service-local data: `./data`, `./config`, `./logs`
- Absolute paths for shared/external data: `/mnt/media/`, `/mnt/downloads/`, `/srv/`
- Mount read-only (`ro`) wherever the service only needs to read: config files, `/srv` in dockhand, media library in jellyfin

### Healthchecks
- Database services (MongoDB, PostgreSQL) define healthchecks
- Services that depend on a database use `condition: service_healthy` in `depends_on`
- Application services generally do not define healthchecks (rely on restart policy)

### Resource Limits
- Define `deploy.resources.limits` and `reservations` for databases and game servers
- Other services do not require limits unless there is a known resource concern

### Networks
- A service that needs Traefik routing joins `traefik_admin` or `traefik_public` (external)
- A service that needs a database joins that database's network (external)
- Services that are only accessed internally (e.g. within the monitoring stack) only join their internal network

---

## Common Commands

### Docker Compose Operations

```bash
# Start a service stack
cd /srv/<category>/<service-name>
docker compose up -d

# Rebuild and restart
docker compose up -d --force-recreate

# View logs
docker compose logs -f [service-name]

# Restart a service
docker compose restart [service-name]

# Stop and remove
docker compose down
```

### Service-Specific Commands

**Registry operations:**
```bash
# Create new registry user
REGISTRY_USER=username REGISTRY_PASSWORD=password /srv/scripts/registry_create_user.sh

# Login to registry
docker login registry.${DOMAIN}

# Tag and push image
docker tag local-image:tag registry.${DOMAIN}/image:tag
docker push registry.${DOMAIN}/image:tag
```

**MongoDB operations:**
```bash
cd /srv/infra/db/mongodb

# Access MongoDB shell
docker exec -it mongodb mongosh -u ${MONGO_ROOT_USER} -p ${MONGO_ROOT_PASSWORD}
```

**PostgreSQL operations:**
```bash
cd /srv/infra/db/postgres

# Access PostgreSQL shell
docker exec -it postgres psql -U ${POSTGRES_USER}

# Create database for a new service
docker exec postgres psql -U postgres -c "CREATE DATABASE mydb;"
docker exec postgres psql -U postgres -c "CREATE USER myuser WITH PASSWORD 'mypass'; GRANT ALL PRIVILEGES ON DATABASE mydb TO myuser;"
docker exec postgres psql -U postgres -d mydb -c "GRANT ALL ON SCHEMA public TO myuser; ALTER DATABASE mydb OWNER TO myuser;"
```

### Monitoring & Debugging

**Check Traefik routing:**
- Dashboard: `https://traefik.${DOMAIN}` or `https://proxy.${DOMAIN}`
- Metrics: `http://<server-ip>:8082/metrics`

```bash
# Check container health
docker ps -a

# Inspect networks
docker inspect <container-name> | grep -A 20 Networks

# Traefik access logs
tail -f /srv/infra/traefik/logs/access.log
```

---

## Development Patterns

### Adding a New Service

1. Create directory under `/srv/<category>/<service-name>/`
2. Create `docker-compose.yaml`:
   - Connect to `traefik_admin` or `traefik_public` (external: true) for routing
   - Connect to `postgres` or `mongodb` (external: true) if a database is needed
   - Use `restart: unless-stopped`
   - Use bind mounts with relative paths for local data
3. Add the route to `infra/traefik/dynamic/routers/<category>.yaml` (Traefik hot-reloads on save)
4. Add `.env` with service variables using the `SERVICE_*` prefix convention
5. Start the service: `docker compose up -d`

**Do not use Docker labels for Traefik routing.** Add routes to the dynamic router files instead.

### VPN-Routing Pattern (Gluetun)

For services requiring VPN (like qBittorrent):
```yaml
gluetun:
  # VPN container — Traefik routing and ports go here
  ports:
    - "8090:8090"

service:
  network_mode: "service:gluetun"  # Route all traffic through VPN
  # No ports, no labels, no networks section (inherits from gluetun)
  depends_on:
    - gluetun
```

### Script Template

Use `/srv/scripts/template_script.sh` as a base. It provides:
- Color-coded logging (`log INFO|SUCCESS|WARN|ERROR`)
- Variable validation (`checkvars VAR1 VAR2 ...`)
- Consistent error handling

---

## File Structure

```
/srv/
  ├── infra/
  │   ├── traefik/
  │   │   ├── docker-compose.yml
  │   │   ├── traefik.yml            # Static config
  │   │   ├── dynamic/
  │   │   │   ├── middlewares.yml
  │   │   │   └── routers/           # infra.yaml, media.yaml, product.yaml
  │   │   ├── acme/                  # SSL certificates (gitignored)
  │   │   └── logs/                  # Access logs (gitignored)
  │   ├── db/
  │   │   ├── mongodb/               # MongoDB + mongo-express + exporter
  │   │   └── postgres/              # PostgreSQL + pgAdmin
  │   ├── registry/
  │   ├── github-runners/
  │   ├── monitoring/                # Grafana, Prometheus, Loki, Tempo, etc.
  │   ├── dockhand/
  │   └── n8n/
  ├── media/
  │   ├── jellyfin/                  # Jellyfin + Jellyseerr
  │   ├── arr/                       # Sonarr, Radarr, Bazarr, Prowlarr
  │   ├── torrent/                   # qBittorrent + Gluetun VPN
  │   └── media-tools/               # FFsubsync, yt-dlp, MKVToolNix, controller
  ├── product/
  │   ├── homepage/
  │   │   ├── admin/                 # Admin dashboard (standalone stack)
  │   │   └── public/                # Public landing page (standalone stack)
  │   ├── docs/                      # MkDocs wiki + admin docs
  │   └── sp/                        # Super Productivity + WebDAV
  ├── game-servers/
  │   ├── minecraft/
  │   ├── satisfactory/
  │   └── playit/
  └── scripts/

# Per-service layout:
/srv/<category>/<service>/
  ├── docker-compose.yaml
  ├── .env                   # gitignored
  ├── config/                # gitignored where applicable
  └── data/                  # gitignored
```

---

## Important Notes

- **Traefik must be running before other services** — routing and cert resolution depend on it
- **Add routes to dynamic router files, not Docker labels** — labels are legacy
- All volumes use bind mounts; no Docker named volumes
- Media paths: `/mnt/media/jellyfin/media/{movies,shows}`, downloads: `/mnt/downloads`
- PUID/PGID are typically 1000:1000 (linuxserver images)
- External networks (`traefik_admin`, `traefik_public`, `postgres`, `mongodb`, `monitoring`) must exist before starting services that join them
- Dockhand manages stack deployments and reads this repo via `/srv` mount
