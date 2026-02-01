# Prowlarr

**URL:** https://prowlarr.ashlasky.com
**Path:** `/srv/arr/prowlarr/`
**Port:** 9696

---

## Purpose

Indexer manager - centralized management of torrent indexers for Sonarr and Radarr.

---

## Quick Info

- **Docker Compose:** `/srv/arr/docker-compose.yaml`
- **Config:** `/srv/arr/prowlarr/`
- **Network:** `traefik_admin`

---

## Notes

### Gotchas
- **Should be configured FIRST** before Sonarr/Radarr - they depend on it for indexers
- All indexer configuration happens here, then syncs to Sonarr/Radarr

### Dependencies
- None (other services depend on this)

### Important Config
- Manages indexers once, syncs to all *arr apps
- Runs as PUID/PGID 1000:1000

---
