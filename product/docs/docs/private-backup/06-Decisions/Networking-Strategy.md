Created at: 07/10/25
Last Updated: 07/10/25
## Prerequisites
### Networks
* **Bezek:**
	* Static IP
	* Router Located upstairs + Access point and 5 port switch in my room
	* 2.5 Gb/s Bandwidth
	* Currently connected - New PC, Mothership (Future - Raspberry Pi)
* **Cellcom:**
	* Dynamic IP
	* Router located in the living room
	* Currently connected - Raspberry Pi (Future - Will be connected only through wifi as backup)
### Current Setup
```
Internet -> Tailscale IP -> Ngnix Proxy Manger -> Services
```

---
## Problem

The main problem is Bezek blocking port forwarding, and even if I succeed my Dad also use the network for his smart home and security cameras.
In the case I actually open a port forward I'll have to make sure I don't collide with his work and make sure I'll do it secure as possible.

For now I used tailscale to overcome this and I got a secure connection (DNS pointing to tailscale IP which means only tailscale user can access the domain). 
This worked well, but created a different problem when I want to share my services with friends or family. Tailscale allow up to 3 users, and 100 devices, so I'm limited to myself and 2 users, and this is without all the technical over head for non tech users...

I need a stable connection, with protection, but easy accessibility.

---
## Solutions

#### Option 1 - Direct Port Forwarding
In that case will connect directly to my static IP (using cloudflare proxy of course), and use traefik on the homelab itself to route services. 

```
Internet → Cloudflare Proxy → Bezek Static IP:443 → Traefik → Services
```

✅ **Pros:**
- **Best performance** - Direct connection, no tunneling overhead
- **Full control** - You own the entire network path
- **Low latency** - Critical for Jellyfin streaming
- **No monthly costs** - Just your existing ISP
- **Multiple ports available** - Game servers can use their own ports
- **Industry standard** - How most production systems work

❌ **Cons:**
- **Requires ISP cooperation** - Your ISP must allow it
- **More security responsibility** - You're exposed to internet (mitigated by Cloudflare)
- **DDoS risk** - Mitigated by Cloudflare proxy
- **Requires static IP** - Which I have...
- **Only usable for https services** - But can add more port forwarding.
---
#### Option 2 - Hybrid Connection (Port Forwarding Disabled)
Will use combination of cloudflare tunneling (which will add about 50ms), tailscale and playit.gg.

```
# Public Services
Internet -> Cloudflare Edge -> Cloudflare's Network -> Traefik -> Services 
# Private Services
Internet -> Tailscale IP -> Traefik -> Services
# Game Servers
Internet -> Playit.gg Network -> Playit.gg Tunnel -> Game Server  
```

**Cloudflared** - For public services and low bandwidth services.
**Tailscale** - For private services and high bandwidth services (Jellyfin)
**Playit.gg** - For game servers

##### Light/Public Services: 
- **Vaultwarden** → Cloudflare Tunnel 
- **BookStack** → Cloudflare Tunnel 
- **Guest Jellyfin** → Cloudflare Tunnel (light use) 
##### Heavy/Private Services: 
- **Personal Jellyfin** → Tailscale (full quality) 
- ***arr app**s → Tailscale 
- **Admin tools** → Tailscale 
- **Nextcloud** → Tailscale
##### Game Servers:
- **Modded Minecraft Server** - Playit.gg
- **Valheim** - Playit.gg

✅ **Pros:**
- Tailscale setup already exists
- Simple
- Secure
- Fast (direct P2P when possible)

**❌ Cons:**
- 3-user limit on free tier
- Technical barrier for non-tech users
- Device compatibility issues
- Not accessible on random devices (LG Smart tvs, etc...)
---
#### Option 3 - VPS + Wireguard setup (Port Forwarding Disabled)
Instead of using my network as the edge point, we'll use the VPS and tunnel to my network using Wireguard. Of course all of that will be behind cloudflare proxy.

```
# Https Services
Friend → VPS:443 → WireGuard tunnel → Home Traefik → Jellyfin/etc
# Game Servers
Friend → VPS:GAME_PORT → WireGuard tunnel → Mothership → Game Server
```

✅ **Pros:**
- **Supports all protocols** - HTTP/HTTPS, TCP, UDP (game servers)
- **Multiple game servers** - Can expose unlimited ports through VPS
- **Home IP completely hidden** - Can't be directly targeted
- **Encrypted tunnel** - All traffic through WireGuard (secure by default)
- **Single point of hardening** - Secure the VPS, home stays protected
- **Better than Cloudflare Tunnel for games** - More direct path (~30-50ms added)
- **Consistent latency** - Predictable performance
- **Production-grade setup** - Real-world infrastructure pattern
- **Full control** - Manage entire stack yourself
- **Scalable** - Can upgrade VPS resources if needed
- **Centralized management** - One VPS config for all external access
- **Easy to add services** - Just forward another port on VPS
- **Monitoring from VPS** - Can check tunnel health externally

 ❌ **Cons:**
- **Higher complexity** - VPS + WireGuard + port forwarding + monitoring
- **Steeper learning curve** - Need to understand VPS management, iptables, WireGuard
- **Two servers to maintain** - VPS AND home lab need updates/monitoring
- **Monthly VPS cost** - €4-6/month for decent VPS (Hetzner, Vultr)
- **Added latency** - Extra hop through VPS (~30-50ms typically)
- **VPS location critical** - Wrong location = high latency for all users
- **Single point of failure** - If tunnel breaks, everything down
- **VPS maintenance required** - Neglect = security risk
- **Dependent on VPS provider** - Their downtime = your downtime
- **VPS security hardening** - Another server to secure (fail2ban, firewall, updates)
- **Backup access method needed** - What if VPS or tunnel fails?
- **WireGuard configuration** - Can be tricky to troubleshoot if issues arise
---
## Decision

I will use **Option 1**, but with a few additions.
- **Public Services** - Port forward + Cloudflare proxy
- **Private Services** - VPN (Tailscale)
- **Persistent Game Servers** - Port forward + SVR DNS Record
- **Temporary Game Servers** - Playit.gg tunnel

---

## 🌐 Current Network Topology

### Physical Layout

```
Internet
│
├─── Bezek (Static IP) - Upstairs, Dad's Office
│    │
│    └─── Ethernet Point → My Room
│         │
│         └─── 5-Port Switch
│              ├─── Desktop PC 10.0.0.3 (DHCP)
│              └─── Mothership 10.0.0.4 (DHCP)
│
└─── Cellcom (Dynamic IP) - Living Room
     └─── Raspberry Pi 10.100.102.14 (DHCP)
```

### Current Device Locations

| Device         | Current Location | Connection                  | Network | Status |
| -------------- | ---------------- | --------------------------- | ------- | ------ |
| Raspberry Pi 4 | Living Room      | Ethernet                    | Cellcom | Active |
| Desktop PC     | My Room          | Ethernet (Switch Port 4)    | Bezek   | Active |
| Mothership     | My Room          | Ethernet<br>(Switch Port 1) | Bezek   | Active |

---
## 🌐 Current Network Topology

### Physical Layout

```
Internet
│
├─── Bezek (Static IP) - Upstairs, Dad's Office
│    │
│    └─── Ethernet Point → My Room
│         │
│         └─── 5-Port Switch
│              ├─── Desktop PC 10.0.0.3 (DHCP)
│              └─── Mothership 10.0.0.4 (DHCP)
│
└─── Cellcom (Dynamic IP) - Living Room
     └─── Raspberry Pi 10.100.102.14 (DHCP)
```

### Current Device Locations

| Device         | Current Location | Connection                  | Network | Status |
| -------------- | ---------------- | --------------------------- | ------- | ------ |
| Raspberry Pi 4 | Living Room      | Ethernet                    | Cellcom | Active |
| Desktop PC     | My Room          | Ethernet (Switch Port 4)    | Bezek   | Active |
| Mothership     | My Room          | Ethernet<br>(Switch Port 1) | Bezek   | Active |

---

## 🏗️ Planned Network Architecture

### Target Network Layout (Post-Migration)

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

### Network Segmentation Plan

**Future Consideration:** Separate networks for different purposes

- **Management Network**: Admin tools (Portainer, Grafana, Traefik dashboard)
- **Public Services Network**: Exposed services (Jellyfin, Vaultwarden)
- **Internal Network**: Private services (*arr apps, databases)

> **Note**: For now will use different docker networks for logical and security reasons.
---
## 🌍 Remote Access Strategy

### Current Setup (Phase 0)

**Method:** Tailscale VPN Only

**Configuration:**
- All services accessible via Tailscale network
- DNS: `*.ashlasky.com` → Tailscale IP
- Users: 3 (approaching limit)

**Pros:**
- Secure, encrypted connections
- Easy setup for tech-savvy users
- No port forwarding needed
- Works from anywhere

**Cons:**
- ⚠️ 3 user limit on free tier
- Non-technical users struggle with setup
- Some devices don't support Tailscale
- Slight latency overhead
---
### Planned Setup 

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

### Current DNS Setup

**Domain:** `yourdomain.com`  
**DNS Provider:** Cloudflare  
**Current Configuration:**

| Record Type | Hostname | Points To                   | Proxy Status | Purpose                    |
| ----------- | -------- | --------------------------- | ------------ | -------------------------- |
| A           | `*`      | Tailscale IP (100.69.41.30) | DNS Only     | All services via Tailscale |
### Planned DNS Configuration

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
### DNS Propagation Notes
- Cloudflare DNS updates: Near-instant
- Changing from Tailscale to Static IP: Update all A records
- TTL: Keep at 300s (5 min) during migration, increase to 3600s (1 hour) when stable
---
## 🔄 Migration Network Changes

### Phase 1: Foundation

**Network Changes:**

- Move Raspberry Pi to your room switch
- Connect Mothership to switch
- Assign static/reserved IPs
- Test local connectivity

**No external changes** - keep Tailscale as-is

### Phase 2-4: Internal Services

**Network Changes:**

- Deploy Traefik on Mothership
- Configure internal routing
- Test services via local IPs

**External access:** Still via Tailscale during testing

### Phase 5: External Access

**Major Network Changes:**

- Implement chosen scenario (A or B)
- Configure Cloudflare (proxy or tunnel)
- Set up authentication layer
- Deploy Fail2ban
- Extensive security testing

**Gradual cutover:**

1. Test new access method
2. Run parallel with Tailscale
3. Migrate users one by one
4. Keep Tailscale as backup
---
## 📝 Decision Points & Questions

### Awaiting Decisions

- [x] **ISP Port Forwarding:** Scenario A or B?
- [ ] **Authentication Method:** Authentik, Authelia, or BasicAuth?
- [x] **Game Server Ports:** Which ports to use?
- [x] **Network Segmentation:** Single network or VLANs?

### To Research

- [x] Cloudflare Tunnel performance for video streaming
- [ ] Authentik vs Authelia comparison
- [ ] Fail2ban best practices
- [ ] VPN alternatives if Tailscale insufficient