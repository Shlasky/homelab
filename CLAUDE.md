# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Docker-based self-hosted infrastructure repository managed through Traefik reverse proxy. The architecture follows a modular service-based design where each directory represents a standalone service stack with its own docker-compose configuration.

### Architecture

**Core Infrastructure:**
- **Traefik** (`traefik/`): Reverse proxy with automatic SSL (Let's Encrypt via Cloudflare DNS challenge), metrics endpoint, and centralized routing
  - Two networks: `traefik_public` (internet-facing) and `traefik_admin` (VPN/Tailscale only)
  - Dynamic configuration via Docker labels and file provider (`dynamic/middlewares.yml`)
  - Services expose themselves by setting `traefik.enable=true` and defining routers/services via labels

**Service Categories:**
1. **Media Stack** (`jellyfin/`, `arr/`, `torrent/`):
   - Jellyfin: Media server with dual routing (public via `tv.${DOMAIN}`, admin via `tv.${ADMIN_DOMAIN}`)
   - Jellyseerr: Request management system
   - Arr stack: Sonarr (TV), Radarr (movies), Bazarr (subtitles), Prowlarr (indexer manager)
   - qBittorrent: Torrent client routing through Gluetun VPN container (network_mode: service:gluetun)

2. **Infrastructure Services**:
   - MongoDB (`db/mongodb/`): Database with mongo-express UI and Prometheus exporter
   - Docker Registry (`registry/`): Private registry with token-based auth via cesanta/docker_auth
   - GitHub Runners (`github-runners/`): Self-hosted runners for GitHub Actions (org-level)
   - Monitoring (`monitor/`): Node-exporter and cAdvisor for Prometheus metrics

3. **Dashboards** (`homepage/`):
   - Admin homepage: Full service dashboard with API integrations
   - Public homepage: Public-facing landing page

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

**Static config** (`traefik/traefik.yml`):
- Entry points: web (80→443 redirect), websecure (443), metrics (8082)
- Cloudflare DNS challenge for Let's Encrypt certificates
- Docker provider with `exposedByDefault: false`

**Dynamic config** (`traefik/dynamic/middlewares.yml`):
- `security-headers@file`: HSTS, CSP, XSS protection
- `compression@file`: Gzip compression
- `cloudflare-ips@file`: IP whitelist for Cloudflare
- `admin-network@file`: Tailscale/local network IP whitelist
- `rate-limit@file`: 100 req/min with burst of 50
- `registry-auth-transport@file`: Skip TLS verification for registry auth

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
cd /srv/<service-name>
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
cd /srv/traefik
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
cd /srv/db/mongodb

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
tail -f /srv/traefik/logs/access.log

# Service logs
docker compose -f /srv/<service>/docker-compose.yaml logs -f
```

## Development Patterns

### Adding a New Service

1. Create directory under `/srv/<service-name>/`
2. Create `docker-compose.yaml` with:
   - Service definition using official/linuxserver images
   - Volume mounts (config in `/srv/<service>/<data>`)
   - Network: `traefik_public` or `traefik_admin` (external: true)
   - Traefik labels for routing (see examples in existing services)
3. Add to `.gitignore`: `<service>/data/`, `<service>/config/`, etc.
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
/srv/<service>/
  ├── docker-compose.yaml    # Service definition
  ├── .env                   # Environment variables (gitignored)
  ├── config/                # Application config (gitignored)
  ├── data/                  # Application data (gitignored)
  └── cache/                 # Cache files (gitignored)

/srv/traefik/
  ├── docker-compose.yml
  ├── traefik.yml           # Static config
  ├── dynamic/              # Dynamic config (middlewares, routes)
  │   └── middlewares.yml
  ├── acme/                 # SSL certificates (gitignored)
  └── logs/                 # Access logs (gitignored)
```

## Important Notes

- **Traefik must be started before other services** for routing to work
- All volumes use absolute paths (e.g., `/srv/`, `/mnt/media/`, `/mnt/downloads/`)
- Media paths: `/mnt/media/jellyfin/media/{movies,shows}`, downloads: `/mnt/downloads`
- PUID/PGID are typically 1000:1000 (linuxserver images)
- Always use `restart: unless-stopped` for production services
- Security headers and compression are applied via `@file` middleware references
- Services with `external: true` networks must have networks created first
- The repository uses shallow git history; recent commits show homepage migration to admin/public split
