# Devbox Development Environment Guide

Complete guide to using Jetify Devbox for isolated, reproducible development
environments in your cloudops Multipass VM.

**Last Updated**: 2025-11-15

## Table of Contents

- [Introduction](#introduction)
- [What is Devbox?](#what-is-devbox)
- [Quick Start](#quick-start)
- [Using Templates](#using-templates)
- [Creating Custom Environments](#creating-custom-environments)
- [Common Workflows](#common-workflows)
- [Advanced Usage](#advanced-usage)
- [Team Collaboration](#team-collaboration)
- [Performance and Optimization](#performance-and-optimization)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [FAQ](#faq)
- [Resources](#resources)

## Introduction

Your cloudops VM comes pre-configured with **Jetify Devbox**, a powerful tool
for creating isolated development environments. Think of it as a lightweight
alternative to Docker containers, but specifically optimized for development
workflows.

### Pre-installed Components

Your VM includes:

- **Nix Package Manager**: v3.13.1 (Determinate Systems installer)
- **Devbox CLI**: v0.16.0
- **Global Tools**: jq, yq, gh, nodejs (24.11.0)
- **Per-Project Tools**: pnpm (add via `devbox add pnpm@10` in your project)
- **Claude CLI**: v2.0.42 (installed globally via npm)
- **5 Ready-to-use Templates**: Node.js, Python, Go, Rust, Full-stack
- **Auto-activated Environment**: No manual configuration needed

### Key Features

- **Project Isolation**: Each project gets its own package environment
- **Reproducible Builds**: Share devbox.json, everyone gets identical setup
- **Fast Package Installation**: Nix caching makes repeated installs 10-30s
- **No Version Conflicts**: Run Node 18 and Node 22 on the same machine
- **Minimal Disk Usage**: Optimized Nix store (~693MB for base installation)

## What is Devbox?

Devbox uses **Nix** under the hood to provide deterministic package management
without requiring deep Nix knowledge. It solves common development problems:

### Problems Devbox Solves

#### Problem 1: "Works on my machine"

Traditional approach:

```bash
# Developer A: Ubuntu 22.04, Python 3.10
python manage.py runserver  # ✓ Works

# Developer B: Ubuntu 24.04, Python 3.12
python manage.py runserver  # ✗ Breaks due to version differences
```

With Devbox:

```bash
# Both developers use identical Python 3.12 from devbox.json
devbox shell
python manage.py runserver  # ✓ Works for everyone
```

#### Problem 2: Version Conflicts

Traditional approach:

```bash
# Project A needs Node 18
nvm use 18
cd ~/project-a && npm start  # ✓ Works

# Project B needs Node 22
nvm use 22
cd ~/project-b && npm start  # ✓ Works

cd ~/project-a && npm start  # ✗ Broken! Wrong Node version
```

With Devbox:

```bash
# Each project automatically uses its specified Node version
cd ~/project-a && devbox shell && npm start  # ✓ Always Node 18
cd ~/project-b && devbox shell && npm start  # ✓ Always Node 22
```

#### Problem 3: Onboarding Time

Traditional approach:

```bash
# New developer setup (2-4 hours)
brew install node python go postgresql redis
# Install correct versions
# Configure environment variables
# Install project dependencies
# Debug version mismatches
```

With Devbox:

```bash
# New developer setup (5 minutes)
git clone repo && cd repo
devbox shell  # Installs everything automatically
npm start     # ✓ Works immediately
```

## Quick Start

### First Steps

Access your VM and verify Devbox is installed:

```bash
# Access the VM
multipass shell cloudops

# Verify installation
devbox version
# Expected: devbox 0.16.0

# Check global tools
jq --version
yq --version
gh --version
node --version
pnpm --version
claude --version
```

### Create Your First Environment

#### Method 1: Use a Template (Recommended for Beginners)

```bash
# Create project directory
mkdir my-first-app && cd my-first-app

# Copy Node.js template
cp ~/.devbox-templates/nodejs-webapp.json devbox.json

# Enter the environment
devbox shell
```

You'll see:

```text
Node.js Web App Environment
Node: v22.14.0
pnpm: 10.11.0
TypeScript: Version 5.7.3

Run: pnpm install  # Install dependencies
Run: pnpm dev      # Start development server

(devbox) cloudops@cloudops:~/my-first-app$
```

Notice the `(devbox)` prefix indicating you're in an isolated environment.

#### Method 2: Initialize from Scratch

```bash
# Create project directory
mkdir my-custom-app && cd my-custom-app

# Initialize devbox
devbox init
# Creates: devbox.json

# Add packages
devbox add nodejs@22.14.0 pnpm@10.11.0

# Enter the environment
devbox shell
```

### Exit the Environment

```bash
# Inside devbox shell
exit

# Back to normal shell
cloudops@cloudops:~/my-custom-app$
```

## Using Templates

Your VM includes 5 production-ready templates in `~/.devbox-templates/`.

### Template 1: Node.js Web Application

**Use for**: React, Vue, Next.js, Express.js, Astro applications

```bash
mkdir my-webapp && cd my-webapp
cp ~/.devbox-templates/nodejs-webapp.json devbox.json
devbox shell
```

**Included packages**:

- Node.js 22.14.0
- pnpm 10.11.0
- TypeScript 5.7.3

**Environment variables**:

- `PATH`: Includes `node_modules/.bin` for local package executables
- `NODE_ENV`: Set to `development`

**Built-in scripts**:

```bash
devbox run install  # Equivalent to: pnpm install
devbox run dev      # Equivalent to: pnpm dev
devbox run build    # Equivalent to: pnpm build
devbox run test     # Equivalent to: pnpm test
```

**Real-world example**:

```bash
# Create a Next.js app
devbox shell
pnpm create next-app@latest .
pnpm dev

# Access at http://localhost:3000
```

### Template 2: Python API

**Use for**: FastAPI, Flask, Django applications

```bash
mkdir my-api && cd my-api
cp ~/.devbox-templates/python-api.json devbox.json
devbox shell
```

**Included packages**:

- Python 3.12.6 (full distribution with pip, venv)
- Poetry (latest)

**Environment variables**:

- `VIRTUAL_ENV`: Points to `.venv` directory
- `PATH`: Includes `.venv/bin`
- `PYTHONPATH`: Set to project root

**Built-in scripts**:

```bash
devbox run install  # Equivalent to: poetry install
devbox run dev      # Equivalent to: poetry run uvicorn main:app --reload
devbox run test     # Equivalent to: poetry run pytest
```

**Real-world example**:

```bash
# Create a FastAPI app
devbox shell
poetry init -n
poetry add fastapi uvicorn

# Create main.py
cat > main.py << 'EOF'
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    return {"Hello": "World"}
EOF

# Run server
devbox run dev
# Access at http://localhost:8000
```

### Template 3: Go Service

**Use for**: Go microservices, APIs, CLI tools

```bash
mkdir my-service && cd my-service
cp ~/.devbox-templates/go-service.json devbox.json
devbox shell
```

**Included packages**:

- Go 1.23.5
- Air (hot reload tool)

**Environment variables**:

- `GOENV`: Disabled (use devbox-managed Go)
- `CGO_ENABLED`: 0 (static binaries)
- `GOOS`: linux
- `GOARCH`: amd64

**Built-in scripts**:

```bash
devbox run install  # Equivalent to: go mod download
devbox run dev      # Equivalent to: air (hot reload)
devbox run build    # Equivalent to: go build -o bin/app .
devbox run test     # Equivalent to: go test ./...
```

**Real-world example**:

```bash
# Create a Go web server
devbox shell
go mod init github.com/username/my-service

# Create main.go
cat > main.go << 'EOF'
package main

import (
    "fmt"
    "net/http"
)

func main() {
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "Hello, Go!")
    })
    http.ListenAndServe(":8080", nil)
}
EOF

# Run with hot reload
devbox run dev
```

### Template 4: Rust CLI

**Use for**: Rust command-line tools, systems programming

```bash
mkdir my-cli && cd my-cli
cp ~/.devbox-templates/rust-cli.json devbox.json
devbox shell
```

**Included packages**:

- Rust 1.85.0
- Cargo 1.85.0
- rust-analyzer (LSP for IDE integration)

**Built-in scripts**:

```bash
devbox run build    # Equivalent to: cargo build
devbox run release  # Equivalent to: cargo build --release
devbox run dev      # Equivalent to: cargo run
devbox run test     # Equivalent to: cargo test
```

**Real-world example**:

```bash
# Create a CLI tool
devbox shell
cargo init --name my-cli

# Build and run
devbox run dev
```

### Template 5: Full-Stack Application

**Use for**: Monorepos, full-stack projects with database

```bash
mkdir my-fullstack && cd my-fullstack
cp ~/.devbox-templates/fullstack.json devbox.json
devbox shell
```

**Included packages**:

- Node.js 22.14.0 + pnpm 10.11.0
- Python 3.12.6
- PostgreSQL 16
- Redis 7.2

**Environment variables**:

- `DATABASE_URL`: postgresql://localhost:5432/devdb
- `REDIS_URL`: redis://localhost:6379

**Built-in scripts**:

```bash
devbox run db:start     # Start PostgreSQL
devbox run db:stop      # Stop PostgreSQL
devbox run redis:start  # Start Redis
devbox run redis:stop   # Stop Redis
```

**Real-world example**:

```bash
# Start services
devbox shell
devbox services start  # Starts PostgreSQL and Redis

# Frontend (in terminal 1)
cd frontend
pnpm install
pnpm dev

# Backend (in terminal 2)
cd backend
poetry install
poetry run uvicorn main:app --reload

# Stop services when done
devbox services stop
```

## Creating Custom Environments

### Understanding devbox.json

The `devbox.json` file defines your project environment:

```json
{
  "$schema": "https://raw.githubusercontent.com/jetify-com/devbox/main/devbox.schema.json",
  "packages": {
    "nodejs": "22.14.0",
    "pnpm": "10.11.0"
  },
  "env": {
    "NODE_ENV": "development",
    "PATH": "$PWD/node_modules/.bin:$PATH"
  },
  "shell": {
    "init_hook": [
      "echo 'Environment ready!'"
    ],
    "scripts": {
      "dev": "pnpm dev",
      "test": "pnpm test"
    }
  }
}
```

### Sections Explained

**1. Packages**: Define runtime dependencies

```json
"packages": {
  "nodejs": "22.14.0",     // Pin exact version
  "python": "3.12.6",
  "postgresql": "16"       // Major version only
}
```

**2. Environment Variables**: Configure runtime

```json
"env": {
  "DATABASE_URL": "postgresql://localhost:5432/mydb",
  "API_KEY": "dev-key-12345",
  "PATH": "$PWD/bin:$PATH"  // Prepend to PATH
}
```

**3. Init Hooks**: Commands run when entering shell

```json
"init_hook": [
  "echo 'Welcome to my project!'",
  "npm install",
  "createdb mydb 2>/dev/null || true"
]
```

**4. Scripts**: Shortcuts for common commands

```json
"scripts": {
  "dev": "npm run dev",
  "test": "npm test",
  "db:reset": "dropdb mydb && createdb mydb"
}
```

### Building Custom Environments

#### Example 1: Django Application

```bash
mkdir django-app && cd django-app
devbox init

# Add packages
devbox add python-full@3.12.6 postgresql@16

# Edit devbox.json
cat > devbox.json << 'EOF'
{
  "$schema": "https://raw.githubusercontent.com/jetify-com/devbox/main/devbox.schema.json",
  "packages": {
    "python-full": "3.12.6",
    "postgresql": "16"
  },
  "env": {
    "DATABASE_URL": "postgresql://localhost:5432/django_db",
    "DJANGO_SETTINGS_MODULE": "myproject.settings"
  },
  "shell": {
    "init_hook": [
      "echo 'Django Development Environment'",
      "python -m venv .venv",
      "source .venv/bin/activate",
      "pip install django psycopg2-binary"
    ],
    "scripts": {
      "migrate": "python manage.py migrate",
      "dev": "python manage.py runserver",
      "shell": "python manage.py shell"
    }
  }
}
EOF

devbox shell
```

#### Example 2: Rust Web API with Database

```bash
mkdir rust-api && cd rust-api
devbox init

devbox add rustc@1.85.0 cargo@1.85.0 postgresql@16

cat > devbox.json << 'EOF'
{
  "$schema": "https://raw.githubusercontent.com/jetify-com/devbox/main/devbox.schema.json",
  "packages": {
    "rustc": "1.85.0",
    "cargo": "1.85.0",
    "postgresql": "16"
  },
  "env": {
    "DATABASE_URL": "postgresql://localhost:5432/rust_db"
  },
  "shell": {
    "init_hook": [
      "echo 'Rust API Environment'",
      "cargo --version",
      "rustc --version"
    ],
    "scripts": {
      "dev": "cargo run",
      "build": "cargo build --release",
      "test": "cargo test",
      "db:start": "pg_ctl start -D .devbox/virtenv/postgresql/data"
    }
  }
}
EOF

devbox shell
cargo init
```

## Common Workflows

### Node.js Full-Stack Development

```bash
# Setup
mkdir fullstack-app && cd fullstack-app
cp ~/.devbox-templates/nodejs-webapp.json devbox.json
devbox shell

# Frontend
mkdir frontend && cd frontend
pnpm create vite@latest . --template react-ts
pnpm install
pnpm dev &  # Run in background

# Backend
cd .. && mkdir backend && cd backend
pnpm init
pnpm add express
cat > index.js << 'EOF'
const express = require('express');
const app = express();
app.get('/api', (req, res) => res.json({ message: 'Hello API' }));
app.listen(3001, () => console.log('API on :3001'));
EOF
node index.js &
```

### Python Data Science

```bash
mkdir data-analysis && cd data-analysis
devbox init

# Add data science packages
devbox add python-full@3.12.6

cat > devbox.json << 'EOF'
{
  "$schema": "https://raw.githubusercontent.com/jetify-com/devbox/main/devbox.schema.json",
  "packages": {
    "python-full": "3.12.6"
  },
  "shell": {
    "init_hook": [
      "python -m venv .venv",
      "source .venv/bin/activate",
      "pip install pandas numpy matplotlib jupyter"
    ],
    "scripts": {
      "notebook": "jupyter notebook",
      "lab": "jupyter lab"
    }
  }
}
EOF

devbox shell
devbox run notebook  # Launch Jupyter
```

### Go Microservices

```bash
mkdir microservices && cd microservices
cp ~/.devbox-templates/go-service.json devbox.json
devbox shell

# Service 1: User Service
mkdir user-service && cd user-service
go mod init github.com/username/user-service
# Implement service

# Service 2: Auth Service
cd .. && mkdir auth-service && cd auth-service
go mod init github.com/username/auth-service
# Implement service

# All services share same Go version from devbox
```

### Rust CLI Tool Development

```bash
mkdir cli-tools && cd cli-tools
cp ~/.devbox-templates/rust-cli.json devbox.json
devbox shell

cargo init --name mytool

# Add dependencies
cargo add clap serde

# Build release
devbox run release

# Binary at: target/release/mytool
```

## Advanced Usage

### Working with Services

Some packages (PostgreSQL, Redis, MySQL) can run as background services.

**Starting Services**:

```bash
devbox shell

# Method 1: Using devbox services
devbox services start          # Start all services
devbox services start postgres # Start specific service
devbox services stop

# Method 2: Using scripts (if defined in devbox.json)
devbox run db:start
devbox run redis:start
```

**PostgreSQL Example**:

```bash
mkdir db-app && cd db-app
devbox init
devbox add postgresql@16

devbox shell
devbox services start postgres

# Create database
createdb myapp_dev

# Connect
psql myapp_dev
# \dt  -- list tables
# \q   -- quit
```

**Redis Example**:

```bash
devbox add redis@7.2
devbox shell
devbox services start redis

# Test connection
redis-cli ping
# PONG

# Set/get values
redis-cli set mykey "Hello"
redis-cli get mykey
```

### Environment Variables and Secrets

#### 1. Development Environment Variables

```json
{
  "env": {
    "DATABASE_URL": "postgresql://localhost:5432/dev",
    "REDIS_URL": "redis://localhost:6379",
    "LOG_LEVEL": "debug"
  }
}
```

#### 2. Secret Management (DO NOT commit secrets)

Create `.env` file (add to `.gitignore`):

```bash
# .env (gitignored)
API_KEY=secret-key-12345
DATABASE_PASSWORD=super-secret
```

Load in devbox:

```json
{
  "shell": {
    "init_hook": [
      "if [ -f .env ]; then export $(cat .env | xargs); fi"
    ]
  }
}
```

#### 3. Environment-Specific Configs

```bash
# .env.development
DATABASE_URL=postgresql://localhost:5432/dev

# .env.test
DATABASE_URL=postgresql://localhost:5432/test
```

Load conditionally:

```json
{
  "shell": {
    "init_hook": [
      "export ENV=${ENV:-development}",
      "if [ -f .env.$ENV ]; then export $(cat .env.$ENV | xargs); fi"
    ]
  }
}
```

### Custom Scripts

Define reusable commands in `devbox.json`:

```json
{
  "shell": {
    "scripts": {
      "setup": [
        "npm install",
        "createdb myapp || true",
        "npm run migrate"
      ],
      "reset": [
        "dropdb myapp",
        "createdb myapp",
        "npm run migrate",
        "npm run seed"
      ],
      "lint": "eslint . --fix",
      "format": "prettier --write .",
      "typecheck": "tsc --noEmit",
      "ci": [
        "npm run lint",
        "npm run typecheck",
        "npm test"
      ]
    }
  }
}
```

Run scripts:

```bash
devbox run setup
devbox run reset
devbox run ci
```

### Integrating with IDEs

**VS Code Integration**:

1. Install "Remote - SSH" extension
2. Connect to cloudops VM (see [VSCODE_SETUP.md](VSCODE_SETUP.md))
3. Open project folder in devbox environment:

```bash
# On cloudops VM
cd ~/code/my-project
devbox shell
code .  # Opens VS Code in devbox context
```

VS Code will use the Node/Python/Go versions from devbox.

**direnv Integration** (optional):

```bash
# Install direnv globally
devbox global add direnv

# In project directory
echo 'eval "$(devbox generate direnv)"' > .envrc
direnv allow

# Now devbox activates automatically when you cd into directory
cd ~/code/my-project  # Automatically enters devbox environment
```

## Team Collaboration

### Sharing Environments

**1. Commit to Git**:

```bash
git add devbox.json devbox.lock
git commit -m "Add devbox configuration"
git push
```

**2. Teammate Setup**:

```bash
git clone <repo>
cd <repo>
devbox shell  # Automatically installs all packages
```

Everyone gets identical environment, regardless of host OS.

### Version Control Best Practices

**Always commit**:

- `devbox.json` - Package definitions
- `devbox.lock` - Exact package versions

**Never commit**:

- `.devbox/` - Local cache (add to `.gitignore`)
- `.env` - Secrets (add to `.gitignore`)

**.gitignore example**:

```gitignore
.devbox/
.env
.env.local
```

### Documentation for Team

Create `DEVBOX_README.md` in your project:

```markdown
# Development Setup

## Prerequisites

- Multipass VM with devbox installed (or local devbox installation)

## Quick Start

1. Clone repository
2. Enter devbox environment: `devbox shell`
3. Install dependencies: `devbox run install`
4. Start services: `devbox services start`
5. Run development server: `devbox run dev`

## Available Commands

- `devbox run dev` - Start development server
- `devbox run test` - Run tests
- `devbox run lint` - Lint code
- `devbox run build` - Build for production

## Database Setup

1. Start PostgreSQL: `devbox services start postgres`
2. Create database: `createdb myapp_dev`
3. Run migrations: `devbox run migrate`
```

## Performance and Optimization

### Nix Store Optimization

Your VM automatically optimizes the Nix store (hard-links duplicate files):

```bash
# Manual optimization
sudo nix-store --optimise

# Check store size
du -sh /nix/store
```

Expected sizes:

- Base installation: ~693MB
- After installing Node.js projects: ~1.5GB
- After installing Python projects: ~2GB
- Full-stack (Node + Python + PostgreSQL + Redis): ~3-4GB

### Caching Performance

**First installation** (cold cache):

```bash
devbox add nodejs@22.14.0
# Downloads and builds: 2-5 minutes
```

**Subsequent installations** (warm cache):

```bash
# In another project
devbox add nodejs@22.14.0
# Uses cache: 10-30 seconds
```

**Shared cache across projects**: All projects using `nodejs@22.14.0` share the
same Nix store entry.

### Disk Space Management

**Check project sizes**:

```bash
# Size of .devbox directory (local cache)
du -sh ~/code/my-project/.devbox

# Total Nix store size
du -sh /nix/store
```

**Clean up unused packages**:

```bash
# Remove packages not referenced by any project
nix-collect-garbage

# Aggressive cleanup (removes all non-current generations)
sudo nix-collect-garbage -d
```

**Optimize after cleanup**:

```bash
sudo nix-store --optimise
```

## Troubleshooting

### Common Issues

#### Issue 1: "Package not found"

**Symptom**:

```bash
devbox add nodejs@22
# Error: package 'nodejs@22' not found
```

**Solution**: Use exact version from search

```bash
# Search for available versions
devbox search nodejs

# Use exact version
devbox add nodejs@22.14.0
```

#### Issue 2: "Command not found after adding package"

**Symptom**:

```bash
devbox add nodejs@22.14.0
node --version
# bash: node: command not found
```

**Solution**: Enter devbox shell

```bash
devbox shell
node --version
# v22.14.0
```

Packages are only available inside `devbox shell`.

#### Issue 3: "Slow package installation"

**Symptom**: First package installation takes 5+ minutes

**Explanation**: This is normal. Nix downloads and builds packages on first
install.

**Subsequent installs**: 10-30 seconds (uses cache)

#### Issue 4: "Services won't start"

**Symptom**:

```bash
devbox services start postgres
# Error: could not start service
```

**Solution**: Check logs and ports

```bash
# Check if port is already in use
sudo netstat -tulpn | grep 5432

# View devbox service logs
devbox services ls
```

#### Issue 5: "Permission denied errors"

**Symptom**: Cannot write to `.devbox/` directory

**Solution**: Fix ownership

```bash
sudo chown -R cloudops:cloudops ~/code/my-project
```

### Advanced Debugging

**Enable verbose output**:

```bash
devbox shell --debug
```

**Check package info**:

```bash
devbox info nodejs@22.14.0
```

**Verify Nix installation**:

```bash
nix --version
# nix (Nix) 3.13.1

which nix
# /usr/bin/nix
```

**Check devbox configuration**:

```bash
devbox version
devbox global list  # List global packages
```

### Getting Help

1. **In-VM documentation**: `cat ~/.devbox-quickstart.md`
2. **Official docs**: <https://www.jetify.com/devbox/docs>
3. **Package search**: <https://www.nixhub.io>
4. **GitHub issues**: <https://github.com/jetify-com/devbox/issues>
5. **Discord community**: <https://discord.gg/jetify>

## Best Practices

### 1. Always Pin Package Versions

```json
// ✓ Good - Explicit version
"packages": {
  "nodejs": "22.14.0",
  "python": "3.12.6"
}

// ✗ Avoid - Unpredictable
"packages": {
  "nodejs": "latest",
  "python": "3"
}
```

### 2. Use Templates as Starting Points

```bash
# Start with template
cp ~/.devbox-templates/nodejs-webapp.json devbox.json

# Customize for your needs
devbox add tailwindcss
```

### 3. Document Your Environment

Add comments to `devbox.json`:

```json
{
  "packages": {
    "nodejs": "22.14.0",  // LTS version, required for React 18+
    "postgresql": "16"    // Matches production version
  }
}
```

### 4. Separate Global vs Project Packages

**Global packages** (available everywhere):

```bash
devbox global add jq yq ripgrep fd
```

**Project packages** (specific to project):

```bash
devbox add nodejs@22.14.0 postgresql@16
```

### 5. Use Scripts for Common Tasks

```json
{
  "shell": {
    "scripts": {
      "dev": "npm run dev",
      "test": "npm test",
      "setup": "npm install && npm run migrate"
    }
  }
}
```

### 6. Keep .devbox/ Out of Git

```bash
echo ".devbox/" >> .gitignore
```

### 7. Test on Clean Environment

```bash
# Remove local cache
rm -rf .devbox/

# Fresh install
devbox shell
# Verify everything works
```

### 8. Use devbox.lock for Consistency

```bash
# After adding packages
devbox shell  # Generates devbox.lock

# Commit lock file
git add devbox.lock
git commit -m "Lock devbox dependencies"
```

### 9. Environment-Specific Configuration

```json
{
  "env": {
    "NODE_ENV": "development",
    "LOG_LEVEL": "debug"
  }
}
```

For production, create separate config.

### 10. Regular Cleanup

```bash
# Monthly cleanup
nix-collect-garbage
sudo nix-store --optimise
```

## FAQ

### General Questions

**Q: Do I need to understand Nix to use Devbox?**

A: No. Devbox provides a simple interface to Nix. You only need to know basic
devbox commands.

**Q: Can I use Devbox outside the VM?**

A: Yes. Install devbox on your host machine: <https://www.jetify.com/devbox/docs/installing_devbox/>

**Q: How is Devbox different from Docker?**

A: Docker provides full OS-level isolation. Devbox provides package-level
isolation optimized for development. Devbox is faster to start and uses less
disk space.

**Q: Does Devbox work on Windows/Mac?**

A: Yes. Devbox runs on Linux, macOS, and Windows (via WSL2).

**Q: Can I use Devbox with Docker?**

A: Yes. You can build Docker images from devbox environments. See:
<https://www.jetify.com/devbox/docs/devbox_examples/containers/>

### Package Questions

**Q: How do I find available packages?**

A: Search at <https://www.nixhub.io> or use `devbox search <query>`

**Q: Can I install multiple versions of the same package?**

A: Yes, in different projects. Each project's devbox.json specifies its version.

**Q: What if a package isn't available in Nix?**

A: Use `init_hook` to install via language package managers:

```json
{
  "shell": {
    "init_hook": [
      "pip install custom-package",
      "npm install private-package"
    ]
  }
}
```

**Q: How do I update packages?**

A:

```bash
# Update all packages
devbox update

# Update specific package
devbox remove nodejs
devbox add nodejs@22.15.0
```

### Performance Questions

**Q: Why is first installation slow?**

A: Nix downloads and builds packages. Subsequent installs use cache (10-30s).

**Q: How much disk space does Devbox use?**

A: Base: ~693MB. Typical project with Node/Python/DB: ~3-4GB total.

**Q: Can I share Nix cache between projects?**

A: Yes. Nix automatically shares packages across all projects.

### Package Manager Questions

**Q: Why is Claude CLI installed with npm instead of pnpm?**

A: After 9 debugging iterations, we discovered that pnpm has strict PATH validation requirements that conflict with the devbox environment:

- **pnpm validation**: pnpm validates that `global-bin-dir` exists in `$PATH` before allowing `pnpm add -g`
- **devbox environment**: The devbox shell doesn't inherit `PNPM_HOME` from `.bashrc`, causing validation to fail
- **npm solution**: npm doesn't have this PATH validation requirement and works reliably with a configured prefix

This ensures automated Claude CLI installation works consistently during cloud-init provisioning.

**Q: Should I use npm or pnpm for my projects?**

A: Use whichever fits your project:

- **pnpm**: Recommended for new projects (faster, disk-efficient, strict dependency resolution)
- **npm**: Works everywhere, simpler, no additional configuration needed
- **Global packages**: npm is used for Claude CLI; pnpm is available for other global tools via devbox

Both are installed globally and available in all environments.

**Q: How do I install global packages?**

A: Three options:

```bash
# Option 1: Via devbox (recommended - isolated per project)
devbox global add <package>

# Option 2: Via npm (works everywhere)
npm install -g <package>

# Option 3: Via pnpm (project-specific)
pnpm add -g <package>  # Requires PNPM_HOME in PATH
```

### Workflow Questions

**Q: Should I commit devbox.json?**

A: Yes. Commit `devbox.json` and `devbox.lock`.

**Q: Should I commit .devbox/ directory?**

A: No. Add to `.gitignore`.

**Q: How do teammates use my devbox config?**

A:

```bash
git clone <repo>
devbox shell  # Automatically installs packages
```

**Q: Can I use devbox in CI/CD?**

A: Yes. GitHub Actions example:

```yaml
- name: Install devbox
  uses: jetify-com/devbox-install-action@v0.7.0
- name: Run tests
  run: devbox run test
```

## Resources

### Official Documentation

- **Devbox Docs**: <https://www.jetify.com/devbox/docs>
- **Devbox GitHub**: <https://github.com/jetify-com/devbox>
- **Package Search**: <https://www.nixhub.io>
- **Examples**: <https://github.com/jetify-com/devbox-examples>

### In-VM Resources

- **Quickstart**: `cat ~/.devbox-quickstart.md`
- **Templates**: `ls ~/.devbox-templates/`
- **Template Details**: `cat ~/.devbox-templates/<template-name>.json`

### Community

- **Discord**: <https://discord.gg/jetify>
- **GitHub Discussions**: <https://github.com/jetify-com/devbox/discussions>
- **Twitter**: @jetify_com

### Learning Resources

- **Devbox Tutorial**: <https://www.jetify.com/devbox/docs/quickstart>
- **Nix Pills**: <https://nixos.org/guides/nix-pills/> (advanced)
- **NixHub Package Docs**: <https://www.nixhub.io>

### Video Tutorials

- **Devbox Introduction**: <https://www.youtube.com/watch?v=ZYmyOTdH7B0>
- **Devbox vs Docker**: <https://www.youtube.com/watch?v=dVqvJA-MxfY>

### Related Documentation

- **[Main README](../README.md)** - Project overview and quick start
- **[Troubleshooting Guide](TROUBLESHOOTING.md)** - Devbox and Nix troubleshooting
- **[VS Code Setup](VSCODE_SETUP.md)** - Remote development configuration
- **[Multipass Best Practices](MULTIPASS_BEST_PRACTICES.md)** - Production deployment
- **[Migration Guide](../MIGRATION.md)** - Upgrading between versions
- **[Changelog](../CHANGELOG.md)** - Version history including Devbox integration
- **[Optimization Summary](OPTIMIZATION_SUMMARY.md)** - VM performance details

## Next Steps

Now that you understand Devbox, try:

1. **Create your first project**: Use a template from `~/.devbox-templates/`
2. **Customize environment**: Modify `devbox.json` for your stack
3. **Share with team**: Commit config and onboard teammates
4. **Explore advanced features**: Services, scripts, CI/CD integration
5. **Join community**: Discord for questions and best practices

**Happy developing with Devbox!**

---

**Document Version**: 1.1
**Last Updated**: 2025-11-15
**Maintained by**: CloudOps Development Team
