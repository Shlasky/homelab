# Traefik

**Last Updated:** 11/10/2025
**Status:** Stable - still testing phase
**Priority:** Critical

---
## 📋 Overview

### Purpose

Traefik is the reverse proxy and load balancer for the entire homelab infrastructure. It serves as the single entry point for all HTTP/HTTPS services, handling:

- Automatic SSL certificate management via Let's Encrypt
- Service discovery through Docker labels
- Request routing based on hostnames
- Security middleware (headers, rate limiting, IP filtering)
- Automatic HTTPS redirects

### Key Features

- **Automatic Service Discovery** - Detects new Docker containers via labels
- **Let's Encrypt Integration** - Automatic SSL certificates using DNS challenge
- **Middleware System** - Reusable security policies (headers, auth, rate limiting)
- **Multi-Network Support** - Separate networks for public and admin services
- **Dashboard** - Web UI for monitoring routes, services, and middleware

---
## 🏠 Location & Access

### Server Location

- **Server:** Mothership
- **Docker Compose:** `/srv/traefik/docker-compose.yml`
- **Data Volume:** `/srv/traefik/acme/` (certificates)
- **Config Files:** `/srv/traefik/traefik.yml`, `/srv/traefik/dynamic/middlewares.yml`

### Network Access

- **Dashboard (VPN):** `https://traefik.admin.ashlasky.com` or `https://proxy.admin.ashlasky.com`
- **Dashboard (Internal):** `http://10.0.0.48:8080` (bypasses routing)
- **Entry Points:**
    - Port 80 (HTTP) - Redirects to HTTPS
    - Port 443 (HTTPS) - Main entry point
    - Port 8080 (Dashboard)

### Authentication

- **Type:** Basic Auth (username/password)
- **Credentials Location:** Vaultwarden - "Traefik Dashboard"
- **Additional Protection:** admin-network middleware (Tailscale + Local IPs only)
---
## 🐳 Docker Configuration

### Docker Compose

```yaml
services:
  traefik:
    image: traefik:v3.0
    container_name: traefik
    restart: always
    security_opt:
      - no-new-privileges:true
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"   # Only through tailscale
    environment:
      - TZ=${TZ}
      - CF_API_EMAIL=${CF_API_EMAIL}
      - CF_DNS_API_TOKEN=${CF_API_KEY}
    volumes:
      # Traefik config files
      - ./traefik.yml:/traefik.yml:ro
      - ./dynamic:/dynamic:ro
      # Certificate storage
      - ./acme/acme.json:/acme.json
      # Docker socket (for service discovery)
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - traefik_public
      - traefik_admin
    labels:
      - "traefik.enable=true"
      # Dashboard Router (admin subdomain via Tailscale)
      - "traefik.http.routers.dashboard.rule=Host(`traefik.${ADMIN_DOMAIN}`) || Host(`proxy.${DOMAIN}`)"
      - "traefik.http.routers.dashboard.entrypoints=websecure"
      - "traefik.http.routers.dashboard.tls=true"
      - "traefik.http.routers.dashboard.tls.certresolver=letsencrypt"
      - "traefik.http.routers.dashboard.service=api@internal"
      - "traefik.http.routers.dashboard.middlewares=dashboard-auth"
      # Dashboard Authentication Middleware
      - "traefik.http.middlewares.dashboard-auth.basicauth.users=${DASHBOARD_PASSWORD_HASH}"

networks:
  traefik_public:
    name: traefik_public
    driver: bridge
  traefik_admin:
    name: traefik_admin
    driver: bridge
```

### Environment Variables

| Variable                  | Purpose                  | Example Value        |
| ------------------------- | ------------------------ | -------------------- |
| `DOMAIN`                  | Primary domain           | `ashlasky.com`       |
| `ADMIN_DOMAIN`            | Admin subdomain          | `admin.ashlasky.com` |
| `ACME_EMAIL`              | Let's Encrypt email      | `ashlasky@gmail.com` |
| `DASHBOARD_PASSWORD_HASH` | bcrypt password hash     | `admin:$2y$05$...`   |
| `CF_API_EMAIL`            | Cloudflare account email | `ashlasky@gmail.com` |
| `CF_DNS_API_TOKEN`        | Cloudflare API token     | `token-string`       |
| `TZ`                      | Timezone                 | `Asia/Jerusalem`     |
### Ports

|Port|Protocol|Purpose|
|---|---|---|
|80|HTTP|Web entry point (redirects to 443)|
|443|HTTPS|Secure web entry point|
|8080|HTTP|Dashboard (Tailscale/local only)|

---
## 🔗 Dependencies

### Required Services

- **Docker Engine** - Container runtime
- **Cloudflare DNS** - For DNS challenge and domain management [[Network#🌐 DNS Configuration]]
- **Let's Encrypt** - SSL certificate authority

### Optional Integrations
- **Fail2ban** - Brute force protection [TO DO]
- **Authentik/Authelia** - SSO authentication layer [TO DO]

---
## ⚙️ Configuration

### Static Configuration (traefik.yml)
The static configuration defines entry points, certificate resolvers, and providers:

```yaml
api:
  dashboard: true
  insecure: true

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
  websecure:
    address: ":443"
    http:
      tls:
        certResolver: letsencrypt

certificatesResolvers:
  letsencrypt:
    acme:
      email: ashlasky@gmail.com
      storage: /acme.json
      dnsChallenge:
        provider: cloudflare
        resolvers:
          - "1.1.1.1:53"
          - "8.8.8.8:53"
        delayBeforeCheck: 30

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
    network: traefik_public
  file:
    directory: /dynamic
    watch: true

log:
  level: INFO
```

### Dynamic Configuration (dynamic/middlewares.yml)
Reusable middleware for security and functionality:

**security-headers** - Adds secure HTTP headers to all responses
- HSTS (HTTP Strict Transport Security)
- Content Security Policy
- X-Frame-Options
- And more security headers

**cloudflare-ips** - Only allows traffic from Cloudflare IP ranges
- Prevents direct access bypassing Cloudflare protection
- Blocks non-Cloudflare traffic

**admin-network** - Restricts access to Tailscale and local network
- Tailscale IP range: 100.64.0.0/10
- Local network: 10.0.0.0/24
- Localhost: 127.0.0.1/32

**rate-limit** - Prevents abuse
- 100 requests per minute average
- Burst of 50 requests allowed

**compression** - Compresses HTTP responses
- Reduces bandwidth usage
- Faster page loads

### Important Settings

**DNS Challenge for Certificates**
- Uses Cloudflare DNS API to prove domain ownership
- Allows certificates for private services (admin.ashlasky.com via Tailscale)
- Can issue wildcard certificates if needed
- 30-second delay before verification for DNS propagation

**Docker Service Discovery**
- `exposedByDefault: false` - Services must opt-in with `traefik.enable=true`
- Watches Docker socket for new containers
- Automatically configures routing based on labels

**Entry Point Behavior**
- Port 80 automatically redirects to 443
- All services get HTTPS by default
- Certificates auto-renew before expiration

### File Locations
- **Main Config:** `/srv/traefik/traefik.yml`
- **Dynamic Config:** `/srv/traefik/dynamic/middlewares.yml`
- **Certificates:** `/srv/traefik/acme/acme.json` **(chmod 600)**
- **Environment:** `/srv/traefik/.env`
- **Logs:** Docker logs (no file logs currently) 

---

## 🔒 Security

### Authentication Method
Dashboard uses HTTP Basic Auth with bcrypt-hashed passwords stored in environment variables.

### Access Control

**Public Services (Port 443):**
- Cloudflare proxy in front (DDoS protection, WAF)
- IP whitelist to Cloudflare ranges only
- Security headers middleware
- Rate limiting

**Admin Services (Tailscale/Local):**
- admin-network middleware (IP whitelist)
- Only accessible via Tailscale or local network
- Not exposed to internet

**Dashboard:**
- Basic Auth required
- admin-network middleware
- Accessible via Tailscale or local network only
### Security Considerations
- Traefik runs with `no-new-privileges:true` security option
- Docker socket mounted read-only
- Certificates stored with 600 permissions (owner-only)
- Let's Encrypt rate limits: 50 certificates per domain per week
- Cloudflare API token has minimal permissions (DNS edit only)

### Exposed to Internet?

**Partial** - Only ports 80 and 443 exposed
- Traffic must come through Cloudflare proxy
- Direct IP access blocked by cloudflare-ips middleware
- Admin interfaces not exposed

---
## 💾 Backup
### What to Backup

**Critical:**
- `/srv/traefik/traefik.yml` - Static configuration
- `/srv/traefik/dynamic/` - Dynamic middleware configuration
- `/srv/traefik/docker-compose.yml` - Service definition
- `/srv/traefik/.env` - Environment variables (contains passwords!)
- `/srv/traefik/acme/acme.json` - SSL certificates

**Optional:**
- Docker logs (if needed for debugging)

### Backup Locations
- **Git Repository:** homelab-docs repo (configs only, not .env with secrets)
- **Primary Backup:** Raspberry Pi backup system [TO DO]
- **Frequency:** Daily (automated via backup script) [TO DO]

### Restore Procedure
1. Stop Traefik container: `docker-compose down`
2. Restore files to `/srv/traefik/`
3. Verify acme.json permissions: `chmod 600 acme/acme.json`
4. Verify .env contains credentials
5. Start Traefik: `docker-compose up -d`
6. Check logs: `docker logs traefik` or `docker compose logs`
7. Verify dashboard accessible
8. Test a public service endpoint

---
## 🔧 Maintenance

### Regular Tasks
- **Weekly:** Check dashboard for any routing errors
- **Monthly:** Review rate limit effectiveness, update Cloudflare IP ranges if needed [TO DO - Automate script]
- **Quarterly:** Review and update security headers based on best practices

### Updates

**To update Traefik to a new version:**
1. Check release notes at https://github.com/traefik/traefik/releases
2. Backup current configuration
3. Update image version in docker-compose.yml
4. Pull new image: `docker-compose pull`
5. Recreate container: `docker-compose up -d`
6. Watch logs for errors: `docker logs -f traefik` or `docker compose logs -f`
7. Test dashboard and a few services
8. If issues occur, rollback: change image version back and recreate

**Update frequency:** Follow Traefik v3.x minor releases, test major versions in dev first

### Logs Location

```bash
# View live logs
docker logs -f traefik

# View last 100 lines
docker logs traefik --tail 100

# View logs since timestamp
docker logs traefik --since 2025-01-09T10:00:00
```

---
## ❗ Troubleshooting

### Common Issues

**ALWAYS CHECK THE LOGS FIRST - 99% of the problems are written in broad daylight!**

**Issue: Service won't get certificate**
- Check Cloudflare API token is valid
- Verify DNS record exists for the domain
- Check logs: `docker logs traefik | grep -i acme`
- DNS challenge takes 30-60 seconds on first request
- **Let's Encrypt rate limit: max 50 certs/week per domain**

**Issue: Can't access dashboard**
- Verify you're on Tailscale or local network (10.0.0.x)
- Check password hash is correct in .env
- Test direct port access: `http://IP:8080`
- Check admin-network middleware isn't blocking you
- Verify certificate was issued: `ls -lh acme/acme.json`

**Issue: Service shows 404 Not Found**
- Check service has `traefik.enable=true` label
- Verify router rule matches the domain you're accessing
- Check service is on the correct Docker network (traefik_public or traefik_admin)
- View dashboard → HTTP → Routers to see if route exists
- Check service container is running: `docker ps`

**Issue: Service shows 502 Bad Gateway**
- Service container is down or unhealthy
- Service port in labels doesn't match actual service port
- Network connectivity issue between Traefik and service
- Check service logs for crashes
- Verify service network: `docker inspect service-name | grep Networks`

**Issue: External access not working**
- Verify ports 80 and 443 are forwarded in router
- Check ISP app/portal hasn't blocked ports
- Verify Cloudflare proxy is enabled (orange cloud)
- Test from external network (mobile data)
- Check Cloudflare SSL/TLS mode is "Full"
- Verify DNS resolves correctly: `nslookup domain.com`

### Health Check

```bash
# Check Traefik is running
docker ps | grep traefik

# Verify ports are open
sudo netstat -tlnp | grep docker-proxy
# More precise
docker port traefik
# Should show: :::80, :::443, :::8080

# Test entry points locally
curl -I http://localhost  # Should redirect to https
curl -k -I https://localhost  # Should respond

# Check networks exist
docker network ls | grep traefik

# Verify certificates exist
sudo ls -lh /srv/traefik/acme/acme.json
# Should show file size > 0 if certs issued

# Check for errors in logs
docker logs traefik | grep -i error
docker logs traefik | grep -i "level=error"
```

### Useful Commands

```bash
# View real-time logs
docker logs -f traefik

# Restart Traefik
cd /srv/traefik
docker compose restart

# Recreate container (applies config changes)
docker compose down && docker compose up -d

# Check Traefik version
docker exec traefik traefik version

# Validate configuration (before starting)
docker run --rm -v $PWD/traefik.yml:/traefik.yml traefik:v3.0 traefik --configFile=/traefik.yml --validate

# View certificate details
sudo cat /srv/traefik/acme/acme.json | \
	jq '.letsencrypt.Certificates[].domain'

# Force certificate renewal (delete acme.json)
# WARNING: Only if you haven't hit Let's Encrypt rate limits!
docker compose down
sudo rm /srv/traefik/acme/acme.json
sudo touch /srv/traefik/acme/acme.json
sudo chmod 600 /srv/traefik/acme/acme.json
sudo chown -R 1000:1000 /srv/traefik/acme
docker-compose up -d
```

---
## 📊 Monitoring

### Key Metrics
- **Request Rate:** Requests per second through Traefik
- **Response Time:** How long services take to respond
- **Certificate Expiry:** Days until certificates expire (auto-renews at 30 days)
- **Error Rate:** 4xx and 5xx response codes
- **Active Connections:** Number of concurrent connections

### Monitoring Tools
- **Traefik Dashboard:** Real-time view of routes, services, middleware
- **Prometheus:** Metrics collection [TO DO]
- **Grafana:** Visualization dashboard [TO DO]

### Alerts
Planned alerts for:
- Traefik container down
- Certificate renewal failures
- High error rate (>5% of requests)
- Abnormal traffic patterns

---
## 🔗 Related Documentation

### Internal Links
- [[01-Infrastructure/Network]] - Network topology and DNS configuration
- [[06-Decisions/Networking-Strategy]] - Why we chose this architecture
- [[04-Procedures/Adding-New-Service]] - How to add services behind Traefik
- [[05-Learning/Traefik-Notes]] - Learning notes and examples

### External Resources
- [Official Traefik Documentation](https://doc.traefik.io/traefik/)
- [Traefik v3.0 Release Notes](https://github.com/traefik/traefik/releases)
- [Let's Encrypt Rate Limits](https://letsencrypt.org/docs/rate-limits/)
- [Cloudflare IP Ranges](https://www.cloudflare.com/ips/)

---
## 📝 Notes & Observations

### Performance Notes
- DNS challenge adds 30-60 seconds on first certificate request
- After initial cert, subsequent requests are instant
- Response times are negligible (<5ms overhead)
- Handles multiple concurrent connections well on i7-7700

### Integration Notes
- Works seamlessly with Docker service discovery
- Cloudflare DNS challenge more reliable than HTTP challenge
- Middleware system is very flexible and reusable
- Dashboard is helpful for debugging routing issues

### Future Improvements
- Add Prometheus metrics endpoint
- Implement Fail2ban integration for brute force protection
- Set up Authentik for SSO across all services
- Consider wildcard certificates for admin subdomain
- Add custom error pages
- Implement more granular rate limiting per service
- Set up automated certificate expiry alerts

### Lessons Learned
- **Port Blocking:** ISP blocked ports 80/443 until opened via their mobile app - Fuck Bezek
- **DNS Challenge:** Essential for services on private networks (Tailscale)
- **Middleware Order:** Order matters when chaining multiple middleware
- **Testing:** Always test certificate acquisition with a test subdomain first

---
## 📜 Change Log

### 2025-10-09
- Initial Traefik deployment on Mothership
- Configured DNS challenge with Cloudflare
- Created middleware for security, rate limiting, compression
- Dashboard accessible via Tailscale
- Ports 80 and 443 successfully opened through ISP app
- Tested with test.ashlasky.com - certificates working
- Documented complete setup

### Future Changes
- Monitor and update as services are migrated
- Track any configuration changes
- Note any issues or optimizations discovered