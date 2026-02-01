# Homelab Documentation - Master Index

**Last Updated:** 2025-10-07  
**Status:** Foundation Phase  
**Current Focus:** Planning & Initial Setup

---

## 📋 Quick Navigation

### 🏗️ Infrastructure

- [[01-Infrastructure/Hardware|Hardware Inventory]]
- [[01-Infrastructure/Network|Network Topology]]
- [[01-Infrastructure/Storage|Storage Strategy]]

### 🐳 Services

- [[02-Services/Service-Inventory|Service Inventory]] - What's running where
- [[02-Services/_Service-Template|Service Documentation Template]]
- See individual service docs in `02-Services/`

### ⚙️ Configurations

- [[03-Configs/mothership/README|Mothership Configs]]
- [[03-Configs/raspberry-pi/README|Raspberry Pi Configs]]

### 📖 Procedures

- [[04-Procedures/Adding-New-Service|Adding a New Service]]
- [[04-Procedures/Backup-Restore|Backup & Restore]]
- [[04-Procedures/Troubleshooting|Common Issues & Solutions]]

### 📚 Learning Notes

- [[05-Learning/Docker-Notes|Docker Deep Dives]]
- [[05-Learning/Traefik-Learning|Traefik Configuration]]
- [[05-Learning/PostgreSQL-Notes|PostgreSQL Management]]

### 🤔 Decisions & Architecture

- [[06-Decisions/Architecture-Overview|System Architecture]]
- [[06-Decisions/Why-Traefik|Why Traefik over NPM]]
- [[06-Decisions/Database-Strategy|Database Consolidation]]
- [[06-Decisions/Networking-Strategy|Networking & Remote Access]]

---

## 🎯 Current Phase: Foundation

### This Week's Focus

- [ ] Contact ISP about port forwarding on static IP
- [ ] Set up Obsidian vault structure (this!)
- [ ] Initialize Git repository
- [ ] Document current state (before migration)
- [ ] Inventory all running services

### Documentation Priorities

1. **Current State Documentation** - Snapshot of existing setup
2. **Hardware Documentation** - Detailed specs and connections
3. **Network Documentation** - Current topology and plans
4. **Service Inventory** - What's running, where, and how to access

---

## 📊 Migration Roadmap Reference

### Phase 1: Foundation (Weeks 1-2)

- Contact ISP
- Documentation setup
- Hardware preparation
- Mothership installation

### Phase 2: Core Infrastructure (Weeks 3-4)

- PostgreSQL deployment
- Traefik setup
- Initial service migration

### Phase 3: Service Migration (Weeks 5-6)

- Media stack migration
- Storage reorganization
- Service-by-service migration

### Phase 4: Monitoring & Backup (Weeks 7-8)

- Monitoring stack on Pi
- Backup implementation
- Testing & validation

### Phase 5: External Access (Week 9+)

- Networking solution based on ISP
- Authentication layer
- Security hardening

### Phase 6: Expansion (Ongoing)

- n8n automation
- Game servers
- Continuous improvement

---

## 🔧 System Overview

### Hardware

- **Mothership**: Intel i7-7700, 32GB RAM, 500GB SSD + 1TB HDD + 16TB HDD
- **Raspberry Pi 4**: 8GB RAM, 1TB SSD + 16TB HDD (moving to Mothership)

### Network

- **Static IP Network**: Your room (Mothership + Pi + Desktop)
- **ISP 1**: Static IP (upstairs) - Port forwarding TBD
- **ISP 2**: Dynamic IP (living room) - No port forwarding

### Current Remote Access

- **Tailscale** for all external access
- **DNS**: \*.ashlasky.com → Tailscale IP

---

## 📝 Documentation Philosophy

### Obsidian (This Vault)

**Purpose**: Your technical brain dump

- Raw notes and work-in-progress
- All configuration files
- Learning notes and troubleshooting
- Decision logs with full context

### Git Repository

**Purpose**: Version control + backup

- Track all changes
- Rollback capability
- Collaboration ready

### BookStack (Future)

**Purpose**: User-friendly public docs

- Clean, polished guides
- Family/friend access instructions
- FAQ and troubleshooting
- No technical jargon

### Public GitHub (Portfolio)

**Purpose**: Professional showcase

- Architecture diagrams
- Clean infrastructure-as-code
- Lessons learned write-ups
- Resume/interview material

---

## 🚀 Quick Reference

### Current Services Location

**Raspberry Pi**: Portainer, Grafana, Prometheus, NPM, Nextcloud, Jellyfin, *arr stack, qBittorrent, Vaultwarden, cAdvisor

### Access URLs

- Portainer: `https://portainer.ashlasky.com` `https://ashlasky.com`
- Grafana: `https://grafana.ashlasky.com` `https://monitor.ashlasky.com`
- Jellyfin: `https://jellyfin.ashlasky.com` `https://shnetflix.ashlasky.com`
- (Update with your actual URLs)

### Important Paths

- Docker configs: `/path/to/docker/configs` (document actual path)
- Media storage: `/mnt/nas/media`
- Backups: (not yet implemented)

---

## 💡 Using This Documentation

1. **Daily Work**: Navigate via links, update as you work
2. **New Service**: Copy `_Service-Template`, fill it out
3. **Troubleshooting**: Check service doc, then `Troubleshooting.md`
4. **Learning**: Add notes to `05-Learning/` as you discover new things
5. **Decisions**: Document why you chose something in `06-Decisions/`

---

## 🎓 Documentation Standards

### File Naming

- Use kebab-case: `my-service-name.md`
- Be descriptive: `traefik-https-setup.md` not `traefik.md`
- Services use service name: `Jellyfin.md`

### Internal Links

- Use wiki-links: `[[Hardware]]` or `[[01-Infrastructure/Hardware]]`
- Relative paths for configs: `../03-Configs/docker-compose.yml`

### Updates

- Always update "Last Updated" date at top of files
- Note what changed in git commit messages
- Archive old configs, don't delete

### Code Blocks

Always specify language:

```yaml
version: '3.8'
services:
  ...
```

---
