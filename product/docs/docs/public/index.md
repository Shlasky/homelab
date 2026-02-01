# Homelab Infrastructure

Self-hosted infrastructure running 15+ containerized services with automated media pipeline, private development tools, and comprehensive monitoring.

**Last Updated:** 22/11/2025

---

## Overview

**Scale:**
- 15+ containerized services across multiple stacks
- 16TB+ media storage with automated management
- Hardware-accelerated transcoding (Intel Quick Sync)
- Dual-domain architecture (public + admin networks)
- Self-hosted CI/CD infrastructure

**Key Features:**
- Automated media acquisition and quality management pipeline
- Private Docker registry with token-based authentication
- VPN-routed download client with network isolation
- Comprehensive monitoring with metrics collection and visualization
- Zero-downtime deployments with automatic SSL certificate management

---

## Tech Stack

**Core Infrastructure:**
- **Docker & Docker Compose** - Containerization and orchestration
- **Traefik v3** - Reverse proxy with automatic SSL (Let's Encrypt)
- **Cloudflare** - DNS management and DDoS protection
- **Tailscale** - Private VPN network for admin access

**Media Stack:**
- **Jellyfin** - Media server with GPU-accelerated transcoding
- **Sonarr/Radarr** - Automated TV show and movie management
- **Prowlarr** - Centralized indexer management
- **Bazarr** - Automated subtitle downloading and synchronization
- **Jellyseerr** - User request management system

**Development & Database:**
- **MongoDB** - NoSQL database with Prometheus metrics exporter
- **Docker Registry** - Private image registry with cesanta/docker_auth
- **GitHub Actions** - Self-hosted runners for CI/CD workflows

**Monitoring & Observability:**
- **Grafana** - Metrics visualization and dashboarding
- **Prometheus** - Time-series metrics collection
- **Node Exporter** - Host-level system metrics
- **cAdvisor** - Container resource usage metrics

**Networking & Security:**
- **Let's Encrypt** - Automatic SSL certificates via DNS challenge
- **WireGuard (Gluetun)** - VPN tunnel for download traffic isolation
- **Dual-network segmentation** - Public (`traefik_public`) and admin (`traefik_admin`) networks
- **Cloudflare DNS Challenge** - Secure certificate validation without exposing ports

---

## Architecture

- **[Network Architecture](Architecture/Network.md)** - Dual-domain routing, VPN integration, and security segmentation
- **[System Overview](#)** - Service dependencies and data flow *(Coming Soon)*

---

## Services

### Media Stack
- **[Jellyfin](Services/Jellyfin.md)** - Self-hosted media server with hardware transcoding and dual routing
- **[Jellyseerr](Services/Jellyseerr.md)** - Media request management with automatic Sonarr/Radarr integration
- **[Sonarr](Services/Sonarr.md)** - Automated TV show monitoring and downloading
- **[Radarr](Services/Radarr.md)** - Automated movie monitoring and downloading
- **[Prowlarr](Services/Prowlarr.md)** - Centralized indexer manager for all *arr applications
- **[Bazarr](Services/Bazarr.md)** - Automated subtitle management and synchronization
- **[qBittorrent + Gluetun](Services/qBittorrent-Gluetun.md)** - VPN-isolated download client with WireGuard

### Core Infrastructure
- **[Traefik](Services/Traefik.md)** - Reverse proxy with automatic SSL, dynamic routing, and middleware
- **[Docker Registry](Services/Docker-Registry.md)** - Private registry with token authentication and cesanta/docker_auth
- **[MongoDB](Services/MongoDB.md)** - Database with Mongo Express UI and Prometheus metrics exporter
- **[GitHub Runners](Services/GitHub-Runners.md)** - Self-hosted GitHub Actions runners

### Monitoring & Metrics
- **[Grafana + Prometheus](Services/Grafana-Prometheus.md)** - Monitoring stack with dashboards and alerting
- **[Node Exporter](Services/Node-Exporter.md)** - Host-level system metrics (CPU, memory, disk, network)
- **[cAdvisor](Services/cAdvisor.md)** - Container resource usage and performance metrics

---

## Design Decisions

- **[Networking Strategy](Decisions/Networking-Strategy.md)** - Dual-domain architecture, VPN integration, and security considerations
- **[Why Traefik](#)** - Comparison with Nginx Proxy Manager and benefits *(Coming Soon)*
- **[Database Strategy](#)** - Technology choices and use cases *(Coming Soon)*

---

## System Stats

- **Total Services:** 15+ containerized applications
- **Storage Capacity:** 16TB media storage + 1TB downloads
- **Hardware:** Intel i7-7700, 32GB RAM
- **Network:** Dual-domain routing (public + admin via Tailscale)
- **SSL Certificates:** Automatic renewal via Let's Encrypt DNS challenge
- **Monitoring:** Real-time metrics collection with historical data retention

---

## Hardware

**Mothership (Primary Server):**
- **CPU:** Intel i7-7700 (4 cores, 8 threads)
- **RAM:** 32GB DDR4
- **Storage:**
  - 500GB SSD - Operating system and Docker volumes
  - 1TB HDD - Downloads and temporary storage
  - 16TB HDD - Media library (movies, TV shows)
- **GPU:** Intel HD Graphics 630 (Quick Sync for hardware transcoding)

**Network:**
- **Public Domain:** *.ashlasky.com (Cloudflare Traefik Services)
- **Admin Domain:** *.admin.ashlasky.com (Tailscale VPN only)
- **Remote Access:** Tailscale mesh VPN

---
