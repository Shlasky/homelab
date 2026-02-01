# Homelab Quick Reference

**Last Updated:** 22/11/2025

---

## 🎯 Current Focus

### Working On
- **[Refactor]** documentation (private vs public)
- **[Research]** Better subtitles sync
- **[Infra]** Loki
- **[Infra]** Tempo
- **[Infra]** Postgresql

### Backlog
- **[Service]** Obisdian Sync
- **[Service]** Vaultwarden

---

## 🚀 Quick Access

### Services Links
- [Traefik Dashboard](https://proxy.ashlasky.com)
- [Traefik Pi - Backup](https://traefik.pi.ashlasky.com)
- [Grafana](https://monitor.ashlasky.com)
- [Prometheus](https://prometheus.ashlasky.com)
- [Jellyfin](https://tv.ashlasky.com)
- [Jellyseerr](https://request.ashlasky.com)
- [Sonarr](https://sonarr.ashlasky.com)
- [Radarr](https://radarr.ashlasky.com)
- [Prowlarr](https://prowlarr.ashlasky.com)
- [Bazarr](https://bazarr.ashlasky.com)
- [qBittorrent](https://torrent.ashlasky.com)
- [MongoDB Express](https://mongo.ashlasky.com)

---

## 📁 Documentation Structure

- **[Services/](Services/)** - Individual service documentation
- **[Configs/](Configs/)** - Configuration snippets and examples
- **[Runbook/](Runbook/)** - Backup, restore, disaster recovery procedures
- **[Common Fixes/](Common%20Fixes/)** - Troubleshooting and solutions
- **[Automation/](Automation/)** - Scripts and automated workflows

---

## 🗺️ System Overview

### Hardware
- **Mothership**: Intel i7-7700, 32GB RAM
  - 500GB SSD (OS)
  - 1TB HDD (Downloads)
  - 16TB HDD (Media)

### Network Architecture
- **Public Domain**: *.ashlasky.com → Cloudflare → Traefik (`traefik_public`)
- **Admin Domain**: *.admin.ashlasky.com → Tailscale only (`traefik_admin`)
- **Remote Access**: Tailscale VPN

### Key Paths
- **Services**: `/srv/[service-name]/`
- **Media**: `/mnt/media/jellyfin/media/{movies,shows}`
- **Downloads**: `/mnt/downloads/`
- **Scripts**: `/srv/scripts/`

### Running Services
- **Core**: Traefik (reverse proxy)
- **Dev Infrastructure**: MongoDB, Docker Registry, GitHub Runners
- **Media**: Jellyfin, Jellyseerr, Sonarr, Radarr, Bazarr, Prowlarr
- **Downloads**: qBittorrent + Gluetun (VPN)
- **Monitoring**: Grafana, Prometheus, Node-exporter, cAdvisor

---
