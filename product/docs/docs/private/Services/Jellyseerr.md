# Jellyseerr

**URL:** https://request.ashlasky.com
**Path:** `/srv/jellyfin/jellyseerr/`
**Port:** 5055

---

## Purpose

Media request management system - users request movies/TV shows, automatically sends to Sonarr/Radarr for download.

---

## Quick Info

- **Docker Compose:** `/srv/jellyfin/docker-compose.yaml`
- **Config:** `/srv/jellyfin/jellyseerr/config/`
- **Networks:** `traefik_public`, `traefik_admin`

---

## Notes

### Gotchas
- Runs with `LOG_LEVEL=debug` for troubleshooting
- Public-facing service (accessible via internet)

### Dependencies
- Jellyfin (authentication)
- Sonarr (TV show requests)
- Radarr (movie requests)

### Important Config
- Integrates with Jellyfin for user authentication
- Auto-approves or requires manual approval based on user settings
- Sends requests to appropriate *arr service based on media type

---
