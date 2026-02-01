# Jellyfin

**URL:** https://tv.ashlasky.com (public), https://tv.admin.ashlasky.com (admin/Tailscale)
**Path:** `/srv/jellyfin/`
**Port:** 8096

---

## Purpose

Self-hosted media server for streaming movies and TV shows with hardware-accelerated transcoding.

---

## Quick Info

- **Docker Compose:** `/srv/jellyfin/docker-compose.yaml`
- **Config:** `/srv/jellyfin/config/`
- **Cache:** `/srv/jellyfin/cache/`
- **Media:** `/mnt/media/jellyfin/media/` (read-only)
- **Networks:** `traefik_public`, `traefik_admin`

---

## Notes

### Gotchas
- Media volume is mounted **read-only** for safety (prevents accidental deletions)
- Uses Intel GPU for hardware transcoding (`/dev/dri` device mapping)
- Dual routing: Public domain has transcoding limits, admin domain for full quality
- Runs as `user: 1000:1000` (not root)

### Dependencies
- Sonarr (TV show management)
- Radarr (movie management)
- Bazarr (subtitle management)

### Important Config
- **Public URLs:** `tv.ashlasky.com`, `shnetflix.ashlasky.com`
- **Admin URLs:** `admintv.ashlasky.com`, `tv.admin.ashlasky.com`
- **Public route** uses compression middleware for bandwidth savings
- **Admin route** no compression for better quality

---

## Usage

### Media Locations
- Movies: `/mnt/media/jellyfin/media/movies/`
- TV Shows: `/mnt/media/jellyfin/media/shows/`

### Hardware Transcoding
Enabled via `/dev/dri` device - uses Intel Quick Sync Video for efficient transcoding.

---
