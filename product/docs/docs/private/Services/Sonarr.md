# Sonarr

**URL:** https://sonarr.ashlasky.com
**Path:** `/srv/arr/sonarr/`
**Port:** 8989

---

## Purpose

TV show management - monitors, downloads, and organizes TV shows automatically.

---

## Quick Info

- **Docker Compose:** `/srv/arr/docker-compose.yaml`
- **Config:** `/srv/arr/sonarr/`
- **TV Shows:** `/mnt/media/jellyfin/media/shows/`
- **Downloads:** `/mnt/downloads/`
- **Network:** `traefik_admin`

---

## Notes

### Gotchas
- Monitors RSS feeds for new episodes
- Automatically renames and organizes files after download

### Dependencies
- Prowlarr (indexers)
- qBittorrent (download client)
- Jellyfin (media consumption)

### Important Config
- Runs as PUID/PGID 1000:1000
- Dual domain routing (public + admin)

---
