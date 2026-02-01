# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Docker-based self-hosted infrastructure repository managed through Traefik reverse proxy. The architecture follows a hierarchical, category-based design where services are grouped into top-level directories (`infra/`, `media/`, `product/`, `game-servers/`), each containing standalone service stacks with their own docker-compose configuration.

### Architecture

**Core Infrastructure (`infra/`):**
- **Traefik** (`infra/traefik/`): Reverse proxy with automatic SSL (Let's Encrypt via Cloudflare DNS challenge), metrics endpoint, and centralized routing
  - Two networks: `traefik_public` (internet-facing) and `traefik_admin` (VPN/Tailscale only)
  - Dynamic configuration via Docker labels and file provider (`dynamic/middlewares.yml`, `dynamic/routers/`)
  - Services expose themselves by setting `traefik.enable=true` and defining routers/services via labels
- **MongoDB** (`infra/db/mongodb/`): Database with mongo-express UI and Prometheus exporter
- **Docker Registry** (`infra/registry/`): Private registry with token-based auth via cesanta/docker_auth
- **GitHub Runners** (`infra/github-runners/`): Self-hosted runners for GitHub Actions (org-level)
- **Monitoring** (`infra/monitoring/`): Grafana, Prometheus, Loki, Tempo, Alertmanager, Promtail, Node-exporter, and cAdvisor
- **Dockhand** (`infra/dockhand/`): Docker stack management with git integration

**Media Stack (`media/`):**
- **Jellyfin** (`media/jellyfin/`): Media server with dual routing (public via `tv.${DOMAIN}`, admin via `tv.${ADMIN_DOMAIN}`), includes Jellyseerr request management
- **Arr stack** (`media/arr/`): Sonarr (TV), Radarr (movies), Bazarr (subtitles), Prowlarr (indexer manager)
- **Torrent** (`media/torrent/`): qBittorrent torrent client routing through Gluetun VPN container (network_mode: service:gluetun)
- **Media Tools** (`media/media-tools/`): FFsubsync and other media utilities

**Products (`product/`):**
- **Dashboards** (`product/homepage/`): Admin and public homepage dashboards
- **Docs** (`product/docs/`): MkDocs-based documentation (public and private sites)
- **SP** (`product/sp/`): WebDAV-based service

**Game Servers (`game-servers/`):**
- **Minecraft** (`game-servers/minecraft/`): Minecraft server
- **Satisfactory** (`game-servers/satisfactory/`): Satisfactory dedicated server
- **Playit** (`game-servers/playit/`): Playit.gg tunnel for game server connectivity

### Network Architecture

**Two-Domain Strategy:**
- `${DOMAIN}`: Public domain (internet-facing services)
- `${ADMIN_DOMAIN}`: Admin domain (VPN/Tailscale-only services)

Services often define dual routes supporting both domains (e.g., `Host(\`service.${DOMAIN}\`) || Host(\`service.${ADMIN_DOMAIN}\`)`).

**Network Segmentation:**
- `traefik_public`: Internet-facing services (Jellyfin public, Registry, Jellyseerr)
- `traefik_admin`: Admin services (arr stack, dashboards, monitoring UIs)
- Service-specific networks: `mongodb`, `registry` (internal communication)

### Traefik Configuration

**Static config** (`infra/traefik/traefik.yml`):
- Entry points: web (80→443 redirect), websecure (443), metrics (8082)
- Cloudflare DNS challenge for Let's Encrypt certificates
- Docker provider with `exposedByDefault: false`

**Dynamic config** (`infra/traefik/dynamic/middlewares.yml`):
- `security-headers@file`: HSTS, CSP, XSS protection
- `compression@file`: Gzip compression
- `cloudflare-ips@file`: IP whitelist for Cloudflare
- `admin-network@file`: Tailscale/local network IP whitelist
- `rate-limit@file`: 100 req/min with burst of 50
- `registry-auth-transport@file`: Skip TLS verification for registry auth

**Dynamic routers** (`infra/traefik/dynamic/routers/`):
- `infra.yaml`: Routes for infrastructure services
- `media.yaml`: Routes for media services
- `product.yaml`: Routes for product services

### Environment Variables

All services use environment variables from `.env` files (not committed, see `.gitignore`). Common variables:
- `TZ`: Timezone
- `DOMAIN`: Public domain
- `ADMIN_DOMAIN`: Admin/VPN domain
- `PUID`/`PGID`: User/group IDs (typically 1000:1000)
- Service-specific API keys (prefixed with service name)

## Common Commands

### Docker Compose Operations

**Start/stop services:**
```bash
# Start a service stack
cd /srv/<category>/<service-name>
docker compose up -d

# View logs
docker compose logs -f [service-name]

# Restart a service
docker compose restart [service-name]

# Stop and remove
docker compose down

# Rebuild and restart
docker compose up -d --force-recreate
```

**Manage Traefik (must be running first):**
```bash
cd /srv/infra/traefik
docker compose up -d

# View Traefik logs
docker compose logs -f

# Reload dynamic config (Traefik watches files)
# Just edit files in dynamic/ and save
```

**Network management:**
```bash
# Create external networks (if needed)
docker network create traefik_public
docker network create traefik_admin

# List networks
docker network ls

# Inspect network
docker network inspect traefik_public
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

# View MongoDB logs
docker compose logs -f mongodb
```

**View all running services:**
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### Monitoring & Debugging

**Check Traefik routing:**
- Dashboard: `https://traefik.${ADMIN_DOMAIN}` or `https://proxy.${DOMAIN}`
- Metrics: `http://<server-ip>:8082/metrics`

**Service health:**
```bash
# Check container health
docker ps -a

# Inspect container
docker inspect <container-name>

# Check networks
docker inspect <container-name> | grep -A 20 Networks
```

**Logs:**
```bash
# Traefik access logs
tail -f /srv/infra/traefik/logs/access.log

# Service logs
docker compose -f /srv/<category>/<service>/docker-compose.yaml logs -f
```

## Development Patterns

### Adding a New Service

1. Create directory under `/srv/<category>/<service-name>/` (choose `infra/`, `media/`, `product/`, or `game-servers/`)
2. Create `docker-compose.yaml` with:
   - Service definition using official/linuxserver images
   - Volume mounts (config in `/srv/<category>/<service>/<data>`)
   - Network: `traefik_public` or `traefik_admin` (external: true)
   - Traefik labels for routing (see examples in existing services)
3. Add runtime data patterns to `.gitignore` if needed
4. Start service: `docker compose up -d`

**Traefik label template:**
```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.<service>.rule=Host(`<service>.${DOMAIN}`)"
  - "traefik.http.routers.<service>.entrypoints=websecure"
  - "traefik.http.routers.<service>.tls=true"
  - "traefik.http.routers.<service>.tls.certresolver=letsencrypt"
  - "traefik.http.routers.<service>.middlewares=security-headers@file"
  - "traefik.http.services.<service>.loadbalancer.server.port=<port>"
```

### VPN-Routing Pattern (Gluetun)

For services requiring VPN (like qBittorrent):
```yaml
gluetun:
  # VPN container with ports exposed
  ports:
    - "8090:8090"  # Application port
  labels:
    # Traefik labels for the service behind VPN

service:
  network_mode: "service:gluetun"  # Route through VPN
  # No ports, no labels (gluetun handles routing)
  depends_on:
    - gluetun
```

### Script Template

Use `/srv/scripts/template_script.sh` as a base. It provides:
- Color-coded logging (`log INFO|SUCCESS|WARN|ERROR`)
- Variable validation (`checkvars VAR1 VAR2 ...`)
- Consistent error handling

## File Structure Conventions

```
/srv/
  ├── infra/                         # Core infrastructure
  │   ├── traefik/
  │   │   ├── docker-compose.yml
  │   │   ├── traefik.yml            # Static config
  │   │   ├── dynamic/               # Dynamic config
  │   │   │   ├── middlewares.yml
  │   │   │   └── routers/           # Per-category route files
  │   │   ├── acme/                  # SSL certificates (gitignored)
  │   │   └── logs/                  # Access logs (gitignored)
  │   ├── db/mongodb/
  │   ├── registry/
  │   ├── github-runners/
  │   ├── monitoring/                # Grafana, Prometheus, Loki, etc.
  │   └── dockhand/
  ├── media/                         # Media services
  │   ├── jellyfin/
  │   ├── arr/                       # Sonarr, Radarr, Bazarr, Prowlarr
  │   ├── torrent/                   # qBittorrent + Gluetun VPN
  │   └── media-tools/
  ├── product/                       # User-facing products
  │   ├── homepage/
  │   │   ├── admin/                 # Admin dashboard
  │   │   └── public/                # Public landing page
  │   ├── docs/                      # MkDocs documentation
  │   └── sp/
  ├── game-servers/                  # Game server instances
  │   ├── minecraft/
  │   ├── satisfactory/
  │   └── playit/
  └── scripts/                       # Shared utility scripts

# Per-service directory layout:
/srv/<category>/<service>/
  ├── docker-compose.yaml    # Service definition
  ├── .env                   # Environment variables (gitignored)
  ├── config/                # Application config (gitignored where applicable)
  └── data/                  # Application data (gitignored)
```

## Important Notes

- **Traefik must be started before other services** for routing to work
- All volumes use absolute paths (e.g., `/srv/`, `/mnt/media/`, `/mnt/downloads/`)
- Media paths: `/mnt/media/jellyfin/media/{movies,shows}`, downloads: `/mnt/downloads`
- PUID/PGID are typically 1000:1000 (linuxserver images)
- Always use `restart: unless-stopped` for production services
- Security headers and compression are applied via `@file` middleware references
- Services with `external: true` networks must have networks created first
- Dockhand manages stack deployments and can sync with this git repo
