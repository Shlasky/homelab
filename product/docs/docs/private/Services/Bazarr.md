# Bazarr

**URL:** https://bazarr.ashlasky.com
**Path:** `/srv/arr/bazarr/`
**Port:** 6767

---

## Purpose

Subtitle management - automatically downloads subtitles for movies and TV shows.

---

## Quick Info

- **Docker Compose:** `/srv/arr/docker-compose.yaml`
- **Config:** `/srv/arr/bazarr/`
- **Movies:** `/mnt/media/jellyfin/media/movies/`
- **TV Shows:** `/mnt/media/jellyfin/media/shows/`
- **Network:** `traefik_admin`

---

## Notes

### Gotchas
- Monitors Sonarr/Radarr for new content and fetches subtitles
- [TODO: Research better subtitle sync solutions - add to backlog]

### Dependencies
- Sonarr (TV shows)
- Radarr (movies)

### Important Config
- Runs as PUID/PGID 1000:1000
- Dual domain routing (public + admin)
- Integrates with subtitle providers (OpenSubtitles, etc.)

---
