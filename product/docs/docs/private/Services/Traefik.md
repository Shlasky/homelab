# Traefik

**URL:** https://proxy.ashlasky.com
**Path:** `/srv/traefik/`
**Ports:** 80 (HTTP), 443 (HTTPS), 8080 (Dashboard), 8082 (Metrics)

---

## Purpose

Reverse proxy and load balancer with automatic SSL certificate management via Let's Encrypt and Cloudflare DNS challenge.

---

## Quick Info

- **Docker Compose:** `/srv/traefik/docker-compose.yml`
- **Static Config:** `/srv/traefik/traefik.yml`
- **Dynamic Config:** `/srv/traefik/dynamic/middlewares.yml`
- **Certificates:** `/srv/traefik/acme/acme.json`
- **Logs:** `/srv/traefik/logs/`
- **Networks:** `traefik_public`, `traefik_admin`

---

## Notes

### Gotchas
- **MUST be started before all other services** - other services depend on Traefik networks
- Dashboard requires basic auth (set via `DASHBOARD_PASSWORD_HASH` env var)
- Let's Encrypt uses Cloudflare DNS challenge (requires `CF_API_EMAIL` and `CF_DNS_API_TOKEN`)
- acme.json must have 600 permissions: `chmod 600 /srv/traefik/acme/acme.json`

### Dependencies
- None (core infrastructure)

### Important Config
- **Two networks:**
  - `traefik_public` - Internet-facing services (Jellyfin, Registry, Jellyseerr)
  - `traefik_admin` - Admin/VPN-only services (Arr stack, monitoring)
- **Entry points:**
  - `web` (80) - Auto-redirects to HTTPS
  - `websecure` (443) - Main HTTPS entry
  - `metrics` (8082) - Prometheus metrics endpoint
- **Middlewares** defined in `dynamic/middlewares.yml`:
  - `security-headers@file` - HSTS, CSP, XSS protection
  - `compression@file` - Gzip compression
  - `admin-network@file` - Tailscale/local IP whitelist
  - `rate-limit@file` - 100 req/min with burst of 50
  - `registry-auth-transport@file` - Skip TLS verification for registry auth

---

## Usage

### Adding Service to Traefik

Add labels to your docker-compose.yml:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.myservice.rule=Host(`service.ashlasky.com`)"
  - "traefik.http.routers.myservice.entrypoints=websecure"
  - "traefik.http.routers.myservice.tls=true"
  - "traefik.http.routers.myservice.tls.certresolver=letsencrypt"
  - "traefik.http.routers.myservice.middlewares=security-headers@file"
  - "traefik.http.services.myservice.loadbalancer.server.port=8080"
```

### Dual Domain Routing (Public + Admin)

```yaml
- "traefik.http.routers.myservice.rule=Host(`service.ashlasky.com`) || Host(`service.admin.ashlasky.com`)"
```

### View Logs

```bash
# Access logs
tail -f /srv/traefik/logs/access.log

# Container logs
docker logs -f traefik
```

### Restart

```bash
cd /srv/traefik
docker compose restart
```

---
