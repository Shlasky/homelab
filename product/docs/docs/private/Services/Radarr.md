# Radarr

**URL:** https://radarr.ashlasky.com
**Path:** `/srv/arr/radarr/`
**Port:** 7878

---

## Purpose

Movie management - monitors, downloads, and organizes movies automatically.

---

## Quick Info

- **Docker Compose:** `/srv/arr/docker-compose.yaml`
- **Config:** `/srv/arr/radarr/`
- **Movies:** `/mnt/media/jellyfin/media/movies/`
- **Downloads:** `/mnt/downloads/`
- **Network:** `traefik_admin`

---

## Notes

### Gotchas
- Monitors for new movie releases
- Automatically renames and organizes files after download

### Dependencies
- Prowlarr (indexers)
- qBittorrent (download client)
- Jellyfin (media consumption)

### Important Config
- Runs as PUID/PGID 1000:1000
- Dual domain routing (public + admin)

---
