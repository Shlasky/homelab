# Ashlasky Documentation

This repository contains the documentation infrastructure for both public and private documentation sites.

## Structure

```
/srv/docs/
├── docker-compose.yaml       # Docker services
├── mkdocs-public.yml         # Public docs config (wiki.ashlasky.com)
├── mkdocs-private.yml        # Private docs config (docs.ashlasky.com)
├── docs/
│   ├── public/               # Public documentation content
│   └── private/              # Private/admin documentation content
├── site-public/              # Built public site (gitignored)
├── site-private/             # Built private site (gitignored)
└── .env                      # Environment variables
```

## Sites

### Public Documentation (wiki.ashlasky.com)
- **Purpose**: Public-facing documentation for services, guides for family/friends, showcase for recruiters
- **Access**: Public (internet-accessible)
- **Network**: traefik_public
- **Color**: Indigo theme

### Private Documentation (docs.ashlasky.com)
- **Purpose**: Private homelab documentation, infrastructure notes, admin guides
- **Access**: VPN/Tailscale only (no authentication needed)
- **Network**: traefik_admin
- **Color**: Deep Orange theme

## Management Script

Use `/srv/scripts/docs_manager.sh` to manage documentation:

```bash
# Build documentation
./scripts/docs_manager.sh build [public|private|all]

# Rebuild from scratch
./scripts/docs_manager.sh rebuild [public|private|all]

# Deploy to production
./scripts/docs_manager.sh deploy [public|private|all]

# Start development server (live reload)
./scripts/docs_manager.sh serve [public|private]

# View logs
./scripts/docs_manager.sh logs [wiki|docs|all]

# Check status
./scripts/docs_manager.sh status

# Container management
./scripts/docs_manager.sh [start|stop|restart] [wiki|docs|all]

# Update MkDocs Material theme
./scripts/docs_manager.sh update
```

## Quick Start

1. **Clone your existing docs** (if you have an Obsidian vault):
   ```bash
   cd /srv/docs/docs/private
   # Clone or copy your documentation here
   ```

2. **Build the sites**:
   ```bash
   /srv/scripts/docs_manager.sh build all
   ```

3. **Deploy**:
   ```bash
   /srv/scripts/docs_manager.sh deploy all
   ```

4. **Access**:
   - Public: https://wiki.ashlasky.com
   - Private: https://docs.ashlasky.com (VPN only)

## Development Workflow

### Editing with Live Preview

```bash
# Start dev server for public docs
/srv/scripts/docs_manager.sh serve public

# Or for private docs
/srv/scripts/docs_manager.sh serve private

# Access at http://localhost:8000 (or http://server-ip:8000)
# Changes auto-reload in browser
```

### Editing in Obsidian

You can use `/srv/docs/docs/public/` or `/srv/docs/docs/private/` as Obsidian vaults. The markdown files are compatible with MkDocs Material.

### Deploy Changes

After editing:
```bash
# Rebuild and deploy
/srv/scripts/docs_manager.sh deploy [public|private|all]
```

## Automation Ideas

### Git Hook Auto-Deploy
```bash
# In your git repo's .git/hooks/post-receive
#!/bin/bash
/srv/scripts/docs_manager.sh deploy all
```

### GitHub Actions
```yaml
# .github/workflows/deploy-docs.yml
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - run: ssh user@server '/srv/scripts/docs_manager.sh deploy all'
```

### Cron Job
```bash
# Auto-rebuild every hour
0 * * * * /srv/scripts/docs_manager.sh build all
```

## MkDocs Material Features

The documentation uses [MkDocs Material](https://squidfunk.github.io/mkdocs-material/) with:

- ✅ Dark/Light theme toggle
- ✅ Search functionality
- ✅ Code syntax highlighting
- ✅ Mermaid diagrams
- ✅ Admonitions (notes, warnings, tips)
- ✅ Task lists
- ✅ Tables of contents
- ✅ Mobile responsive

### Example Markdown Features

```markdown
# Code blocks with syntax highlighting
\`\`\`python
def hello():
    print("Hello, world!")
\`\`\`

# Admonitions
!!! note
    This is a note

!!! warning
    This is a warning

# Mermaid diagrams
\`\`\`mermaid
graph LR
    A --> B
\`\`\`

# Task lists
- [x] Completed task
- [ ] Pending task
```

## Troubleshooting

### Site not updating?
```bash
# Force rebuild
/srv/scripts/docs_manager.sh rebuild all
/srv/scripts/docs_manager.sh restart all
```

### Check logs
```bash
/srv/scripts/docs_manager.sh logs all
```

### Verify builds
```bash
/srv/scripts/docs_manager.sh status
```

## Resources

- [MkDocs Material Documentation](https://squidfunk.github.io/mkdocs-material/)
- [MkDocs Documentation](https://www.mkdocs.org/)
- [Markdown Guide](https://www.markdownguide.org/)
