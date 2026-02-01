# [Service Name]

**Last Updated:** YYYY-MM-DD  
**Status:** Production / Testing / Planned  
**Priority:** Critical / High / Medium / Low

---

## 📋 Overview

### Purpose

One-paragraph explanation: What does this service do and why do you need it?

### Key Features

- Feature 1
- Feature 2
- Feature 3

---

## 🏠 Location & Access

### Server Location

- **Server:** Mothership / Raspberry Pi
- **Docker Compose:** `/path/to/docker-compose.yml`
- **Data Volume:** `/path/to/data`
- **Config Files:** `/path/to/configs`

### Network Access

- **Internal URL:** `http://192.168.x.x:port`
- **External URL:** `https://service.yourdomain.com`
- **Tailscale URL:** `http://tailscale-ip:port`

### Authentication

- **Type:** None / Basic Auth / SSO / API Key
- **Credentials Location:** Vaultwarden / documented below
- **Default User:** (if applicable)

---

## 🐳 Docker Configuration

### Docker Compose

```yaml
version: '3.8'

services:
  service-name:
    image: username/service:tag
    container_name: service-name
    restart: unless-stopped
    ports:
      - "port:port"
    volumes:
      - /host/path:/container/path
    environment:
      - ENV_VAR=value
    networks:
      - network-name
    labels:
      # Traefik labels if applicable
      - "traefik.enable=true"
      - "traefik.http.routers.service.rule=Host(`service.domain.com`)"

networks:
  network-name:
    external: true
```

### Environment Variables

|Variable|Purpose|Example Value|
|---|---|---|
|`VAR_NAME`|Description|`example`|
|`VAR_NAME`|Description|`example`|

### Ports

|Port|Protocol|Purpose|
|---|---|---|
|8080|HTTP|Web UI|
|9090|HTTP|API|

---

## 🔗 Dependencies

### Required Services

- **[[PostgreSQL]]** - Database backend
- **[[Traefik]]** - Reverse proxy
- **[[Service-Name]]** - Another dependency

### Optional Integrations

- **[[Service-Name]]** - What it provides

---

## ⚙️ Configuration

### Initial Setup Steps

1. Create database (if needed)
2. Configure environment variables
3. Set up volumes and permissions
4. Deploy container
5. Run initial configuration wizard

### Important Settings

**Setting Name**: What it does and recommended value

**Setting Name**: What it does and recommended value

### File Locations

- **Main Config:** `/path/to/config.yml`
- **Logs:** `/path/to/logs`
- **Cache:** `/path/to/cache`

---

## 🔒 Security

### Authentication Method

How users authenticate to this service

### Access Control

Who should have access and at what level

### Security Considerations

- Security point 1
- Security point 2
- Security point 3

### Exposed to Internet?

**Yes** / **No** / **Partial**

- If yes, through what method (Cloudflare, Tailscale, etc.)
- What protections are in place

---

## 💾 Backup

### What to Backup

- **Critical**: Database, user configs, essential data
- **Optional**: Cache, logs, temporary files

### Backup Locations

- **Primary:** `/path/on/backup/server`
- **Frequency:** Daily / Weekly / Monthly

### Restore Procedure

1. Stop container
2. Restore data from backup
3. Verify permissions
4. Start container
5. Verify functionality

---

## 🔧 Maintenance

### Regular Tasks

- **Daily:** Task description
- **Weekly:** Task description
- **Monthly:** Task description

### Updates

How to update this service safely:

1. Check release notes
2. Backup first
3. Pull new image
4. Restart container
5. Verify functionality

### Logs Location

```bash
docker logs service-name
# or
/path/to/logs/service.log
```

---

## ❗ Troubleshooting

### Common Issues

**Issue: Service won't start**

- Check logs: `docker logs service-name`
- Verify permissions: `ls -la /data/path`
- Check dependencies are running
- Verify port availability

**Issue: Can't access via URL**

- Verify Traefik routing
- Check DNS resolution
- Verify firewall rules
- Test direct IP:port access

**Issue: Database connection errors**

- Verify PostgreSQL is running
- Check database credentials
- Verify network connectivity
- Check database exists

### Health Check

```bash
# Quick health check commands
curl http://localhost:port/health
docker exec service-name command-to-check-status
```

### Useful Commands

```bash
# View logs
docker logs -f service-name

# Restart service
docker-compose restart service-name

# Access container shell
docker exec -it service-name /bin/bash

# Check resource usage
docker stats service-name
```

---

## 📊 Monitoring

### Key Metrics

- Metric 1: What it measures and healthy range
- Metric 2: What it measures and healthy range

### Prometheus Metrics

- **Endpoint:** `http://service:port/metrics`
- **Key Metrics:** List important metrics to track

### Alerts

What should trigger an alert:

- Service down
- High resource usage
- Failed operations

---

## 🔗 Related Documentation

### Internal Links

- [[Related-Service]] - How they work together
- [[Procedure-Name]] - Related procedure
- [[Decision-Name]] - Why we chose this

### External Resources

- [Official Documentation](https://example.com/)
- [Useful Tutorial](https://example.com/)
- [Community Forum](https://example.com/)

---

## 📝 Notes & Observations

### Performance Notes

Observations about resource usage, speed, etc.

### Integration Notes

How well it works with other services

### Future Improvements

- Improvement idea 1
- Improvement idea 2

---

## 📜 Change Log

### 2025-10-07

- Initial documentation created
- Service deployed to [Server]

### YYYY-MM-DD

- Change description
- Configuration update