# Docker Registry

**URL:** https://registry.ashlasky.com
**Path:** `/srv/registry/`
**Port:** 5000 (Registry), 5001 (Auth)

---

## Purpose

Private Docker image registry with token-based authentication for storing custom Docker images.

---

## Quick Info

- **Docker Compose:** `/srv/registry/docker-compose.yaml`
- **Registry Data:** `/srv/registry/data/`
- **Auth Config:** `/srv/registry/auth/config.yml`
- **Certificates:** `/srv/registry/auth/server.key`, `/srv/registry/auth/server.pem`
- **Network:** `traefik_public`, `registry` (internal)

---

## Notes

### Gotchas
- **Two containers:** `registry` (main) and `registry-auth` (authentication)
- Uses `cesanta/docker_auth` for token-based authentication
- Auth endpoint at `/auth` path (priority 100 routing)
- Registry uses **self-signed certificates** - Traefik configured to skip TLS verification via `registry-auth-transport@file` middleware
- Auth service runs HTTPS on port 5001 with custom certs

### Dependencies
- Traefik (reverse proxy and SSL)

### Important Config
- **Authentication Flow:**
  1. Docker client requests image
  2. Registry redirects to `https://registry.ashlasky.com/auth`
  3. Traefik routes `/auth` to `registry-auth` service
  4. Auth service validates credentials and issues token
  5. Client uses token to access registry
- **Service names:**
  - Auth: "Shdocker Hub Auth"
  - Registry: "Shdocker Hub"
- **Certificate bundle:** `/certs/server.pem` mounted in both containers

---

## Usage

### Create New User
```bash
# Use the registry user creation script
REGISTRY_USER=username REGISTRY_PASSWORD=password /srv/scripts/registry_create_user.sh
```

### Login to Registry
```bash
docker login registry.ashlasky.com
# Enter username and password
```

### Push Image
```bash
# Tag image
docker tag local-image:tag registry.ashlasky.com/image:tag

# Push to registry
docker push registry.ashlasky.com/image:tag
```

### Pull Image
```bash
docker pull registry.ashlasky.com/image:tag
```

---
