**Last Updated:** 11/22/2025

---

## 📋 Table of Contents (UPDATE LINKS)

- [Current Network Topology]()
- [Planned Network Architecture]()
- [IP Address Allocation]()
- [Remote Access Strategy]()
- [DNS Configuration]()
- [Security Layers]()
- [Port Allocation]()
- [Network Services]()
- [Change Log]()

---

## 🌐 Network Topology

### Physical Layout

```
Internet
│
├─── Bezek (Static IP Network - 109.67.151.17)
│    ├─── Router (10.0.0.138)
│    │    
│    └─── Your Room (Ethernet + 5-Port Switch)
│         ├─── Desktop PC 10.0.0.250
│         ├─── Mothership 10.0.0.248 [Primary Server]
│         └─── Raspberry Pi 10.0.0.249 [Monitoring/Backups]
│
└─── Cellcom (Dynamic IP)
     └─── Backup connectivity option

Remote Access Layer:
├─── Tailscale VPN (Current: All access)
└─── [Cloudflare Tunnel OR Direct Port Forwarding] (Planned: Public services)
```

---

## 🔢 IP Address Allocation

### Static IP Assignments

| Device/Service | IP Address | Notes            |
| -------------- | ---------- | ---------------- |
| ISP 1 Router   | 10.0.0.138 | Default gateway  |
| Desktop PC     | 10.0.0.50  | DHCP Reservation |
| Mothership     | 10.0.0.48  | DHCP Reservation |
| Raspberry Pi   | 10.0.0.49  | DHCP Reservation |

---
### Setup 

**Architecture:**

```
Internet
  ↓
Cloudflare (Proxy + WAF)
  ↓ (Port 443)
Static IP
  ↓
Traefik (Reverse Proxy)
  ↓
Services (Tiered Access)
```

**Service Access Tiers:**

**Tier 1 - Public (Port 443):**
- Jellyfin (with authentication)
- Nextcloud

**Tier 2 - Admin Only (Tailscale/VPN):**
- Traefik Dashboard
- Portainer
- Vaultwarden
- Grafana & Prometheus
- \*arr apps (Radarr, Sonarr, etc.)
- n8n
- pgAdmin
- BookStack admin (Future documentation)

**Tier 3 - Game Servers (Custom Ports):**
- **Minecraft**: Port 25565
- **Temp Game Servers:** Playit.gg service 

**Security Layers:**
1. **Cloudflare** - DDoS protection, hides real IP, WAF rules
2. **Traefik** - Reverse proxy with security headers
3. **Authentik/Authelia** - SSO + 2FA for sensitive services
4. **Fail2ban** - Auto-ban brute force attempts
5. **Network Isolation** - Admin services never exposed

---
## 🌐 DNS Configuration

| Type      | Name                 | Content                                      | Proxy      | Purpose                             |
| --------- | -------------------- | -------------------------------------------- | ---------- | ----------------------------------- |
| **A**     | `ashlasky.com`       | `109.67.151.17` - **Static IP**              | ☁️ Proxied | Root domain                         |
| **CNAME** | `*`                  | `ashlasky.com`                               | ☁️ Proxied | **Wildcard - all public services**  |
| **A**     | `admin.ashlasky.com` | `100.74.54.34` - **Mothership Tailscale IP** | DNS only   | Private services root               |
| **CNAME** | `*.admin`            | `admin.ashlasky.com`                         | DNS only   | **Wildcard - all private services** |
|           |                      |                                              |            |                                     |
| **CNAME** | `monitor`            | admin.ashlasky.com                           | DNS only   | **Grafana Dashboard**               |
| **CNAME** | `vault`              | admin.ashlasky.com                           | DNS only   | **Vault Warden**                    |
| **CNAME** | `admintv`            | admin.ashlasky.com                           | DNS only   | **Private Jellyfin**                |
| **CNAME** | `proxy`              | admin.ashlasky.com                           | DNS only   | **Traefik Dashboard**               |
|           |                      |                                              |            |                                     |
| **A**     | `minecraft`          | `109.67.151.17` - **Static IP**              | DNS only   | Minecraft server IP                 |
| **CNAME** | `mc`                 | `minecraft.ashlasky.com`                     | DNS only   | Minecraft short name                |
| **SRV**   | `_minecraft._tcp.mc` | `0 5 25565 minecraft.ashlasky.com`           | DNS only   | Minecraft port discovery            |
|           |                      |                                              |            |                                     |
| **NS**    | `ashlasky.com`       | `dns1.registrar-servers.com`                 | DNS only   | Nameserver (keep all)               |
| **NS**    | `ashlasky.com`       | `dns2.registrar-servers.com`                 | DNS only   | Nameserver (keep all)               |

**Cloudflare Proxy:**
- ✅ Enabled for public services (hides real IP)
- ❌ Disabled for admin subdomains (Tailscale only)

---

## 🔒 Security Layers

### External Access Protection

**Layer 1: Cloudflare (If using)**
- DDoS protection (automatic)
- Web Application Firewall (WAF)
- Rate limiting rules
- Bot protection
- Hide real IP address

**Layer 2: Traefik**
- Reverse proxy with TLS
- Security headers (HSTS, CSP, etc.)
- IP whitelisting for admin services
- Request rate limiting
- Automatic HTTPS redirects

**Layer 3: Authentication**
- **Option A:** Authentik (Open-source SSO)
- **Option B:** Authelia (Lightweight SSO)
- **Option C:** Traefik BasicAuth (Simple services)

**All services get:**
- Username/password at minimum
- 2FA for sensitive services (Vaultwarden, admin tools)
- Failed login tracking

**Layer 4: Fail2ban**
- Monitor auth logs
- Auto-ban after failed attempts
- Configurable ban duration
- Whitelist trusted IPs

**Layer 5: Network Isolation**
- Admin services NEVER exposed to internet
- Tailscale/VPN-only access
- Separate Docker networks

### Firewall Rules

**On Mothership (UFW/iptables):**

```bash
# Default deny all incoming
# Allow from local network: 192.168.x.0/24
# Allow port 443 (if direct access)
# Allow Tailscale ports
# Log all dropped packets
```

---

## 🔌 Port Allocation

### External Ports (Exposed to Internet)

| Port  | Protocol | Service   | Purpose      | Security          |
| ----- | -------- | --------- | ------------ | ----------------- |
| 80    | HTTP     | Traefik   | Web services | Cloudflare + Auth |
| 443   | HTTPS    | Traefik   | Web services | Cloudflare        |
| 25565 | TCP      | Minecraft | Game server  | Whitelist         |

### Internal Ports (Local Network Only)

| Port  | Service           | Access Method        |
| ----- | ----------------- | -------------------- |
| 80    | Traefik HTTP      | Redirect to 443      |
| 443   | Traefik HTTPS     | Main entry point     |
| 8080  | Traefik Dashboard | Tailscale only       |
| 9000  | Portainer         | Tailscale only       |
| 3000  | Grafana           | Tailscale only       |
| 9090  | Prometheus        | Tailscale only       |
| 5432  | PostgreSQL        | Docker network only  |
| 8096  | Jellyfin          | Via Traefik          |

### Port Forwarding Configuration

**Router Port Forwards:**

```
External Port 80 → Internal 10.0.0.48:80 (Mothership)
External Port 443 → Internal 10.0.0.48:443 (Mothership)
[Game ports] → Respective Mothership ports
```

**Traefik Internal Routing:**
- Handles all HTTP/HTTPS traffic on 443
- Routes by hostname to services
- No need for individual port forwards

---

## 🛠️ Network Services

### Reverse Proxy: Traefik

**Location:** Mothership  
**Purpose:** Single entry point for all HTTP/HTTPS services  
**Configuration:** [[Traefik|See Traefik documentation]]

**Features:**
- Automatic service discovery (Docker labels)
- Let's Encrypt SSL certificates
- HTTP to HTTPS redirect
- Custom routing rules
- Middleware (auth, rate limiting, headers)

### VPN: Tailscale

**Role:** Admin and power user access

**Devices Connected:**
- Your devices (phone, laptop, etc.)
- Family/friend devices (approaching 3-user limit)

**Tailscale Subnet Router:**
- Consider: Use one device as subnet router
- Allows access to entire home network via Tailscale
- Useful for admin access to all services

### DNS: Cloudflare

**Domain Management:** yourdomain.com  

**Services:**
- DNS hosting (free)
- Proxy/WAF (free tier)
- Cloudflare Tunnel (free, if needed)

**Configuration Access:**
- Dashboard: cloudflare.com
- API tokens: [In Vaultwarden]

---

## 📊 Network Monitoring

### Metrics to Track
- Bandwidth usage per service
- Connection counts
- Failed authentication attempts
- Response times
- DNS query patterns

### Monitoring Tools
- **Grafana Dashboard:** Network overview
- **Prometheus:** Collect metrics
- **Traefik Metrics:** Request stats
- **Fail2ban Status:** Ban counts

---

## 🚨 Troubleshooting

### Common Network Issues

**Issue: Can't access service locally**

```bash
# Check service is running
docker ps | grep service-name

# Check service port
netstat -tulpn | grep port

# Test direct connection
curl http://10.0.0.50:port

# Check Traefik routing
docker logs traefik | grep service-name
```

**Issue: External access not working**

```bash
# Verify DNS resolution
nslookup service.ashlasky.com

# Test from external network
# Use phone data, not home WiFi
curl -I https://service.ashlasky.com

# Check Cloudflare status
# Dashboard → Analytics → Traffic

# Verify port forwarding (if using)
# Use online port checker tool
```

**Issue: Slow connection**

```bash
# Test direct vs Tailscale
# Compare response times

# Check Tailscale connection
tailscale status

# Monitor bandwidth
nethogs
iftop
```

### Network Diagnostic Commands

```bash
# Show all connections
ss -tunap

# Show routing table
ip route

# Test DNS resolution
dig service.yourdomain.com

# Trace route
traceroute service.yourdomain.com

# Check firewall rules
sudo ufw status verbose
sudo iptables -L -n -v

# Monitor traffic
sudo tcpdump -i eth0 port 443

# Test port accessibility
nc -zv 192.168.x.x port
```

---
## 📚 Related Documentation

- [[06-Decisions/Networking-Strategy|Detailed Networking Strategy Decision]]
- [[02-Services/Traefik|Traefik Configuration]]
- [[04-Procedures/Adding-New-Service#Network-Configuration|Network Setup for New Services]]
- [[05-Learning/Networking-Concepts|Networking Learning Notes]]

---
## 📋 Change Log

#### 07/10/25
- Initial network documentation created
- Documented current state
- Outlined planned architecture (pending ISP response)
- Created placeholder for future configurations
#### 08/10/25
- Created the new network strategy
- Updated the DNS Records (To match with the new strategy)
