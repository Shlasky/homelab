# qBittorrent + Gluetun

**URL:** https://torrent.ashlasky.com
**Path:** `/srv/torrent/`
**Ports:** 8090 (WebUI), 6881 (Torrent traffic)

---

## Purpose

Torrent download client (qBittorrent) routing all traffic through VPN (Gluetun) for privacy.

---

## Quick Info

- **Docker Compose:** `/srv/torrent/docker-compose.yaml`
- **qBittorrent Config:** `/srv/torrent/qbittorrent/config/`
- **Gluetun Config:** `/srv/torrent/gluetun/`
- **WireGuard Config:** `/srv/torrent/wireguard.conf`
- **Downloads:** `/mnt/downloads/`
- **Network:** `traefik_admin`

---

## Notes

### Gotchas
- **qBittorrent uses `network_mode: service:gluetun`** - all traffic routes through VPN container
- Traefik labels go on **Gluetun container**, not qBittorrent
- Ports are exposed on Gluetun (8090 for WebUI, 6881 for torrents)
- Custom middleware `qbit-headers` to handle X-Frame-Options and Referer headers
- Requires `DISABLE_HOST_HEADER_CHECK=1` in qBittorrent for Traefik routing to work
- VPN uses WireGuard (configured in wireguard.conf)

### Dependencies
- None (standalone service)

### Important Config
- **VPN Provider:** Custom WireGuard config
- **Environment Variables:**
  - `VPN_TYPE` - Set to wireguard
  - `WIREGUARD_PRIVATE_KEY`, `WIREGUARD_PUBLIC_KEY` - VPN credentials
  - `WIREGUARD_ENDPOINT_IP` - VPN server IP
  - `WIREGUARD_ADRESSES` - VPN client IP (10.14.0.2/16)
- **Firewall:**
  - VPN input ports: 6881 (torrent traffic)
  - Subnets: 10.0.0.0/32
- Runs as PUID/PGID 1000:1000

---

## Usage

### Check VPN Status
```bash
# View Gluetun logs to verify VPN connection
docker logs gluetun

# Should see "Connected to VPN" message
```

### Access qBittorrent
- WebUI on port 8090 (routed through Gluetun)
- Default credentials are set during first run

### Downloads Location
- Downloads go to `/mnt/downloads/`
- Accessible by Sonarr/Radarr for post-processing

---
