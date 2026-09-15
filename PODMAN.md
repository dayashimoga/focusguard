# FocusGuard - Zero-Host Podman Container Architecture

FocusGuard achieves 100% reproducible developer environments through containerization. No mobile SDKs or Flutter tools are required on the host system.

---

## 1. Container Image & Specification

The development container is based on `ghcr.io/cirruslabs/flutter:3.24.3`:
- **OS**: Ubuntu 22.04 LTS (Jammy)
- **Flutter Version**: Pinned `3.24.3` (channel stable)
- **Dart Version**: `3.5.3`
- **JDK**: OpenJDK 17 (`temurin`)
- **Android SDK**: API Level 34 (Android 14) with Build Tools 34.0.0 and Command-Line Tools
- **Gradle**: 8.3+

---

## 2. Containerfile Definition

```dockerfile
FROM ghcr.io/cirruslabs/flutter:3.24.3

USER root

# Install essential system utilities and SQLite tooling
RUN apt-get update && apt-get install -y --no-install-recommends \
    sqlite3 \
    libsqlite3-dev \
    lcov \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Configure safe git directory for container mounted workspaces
RUN git config --global --add safe.directory /workspace

# Workspace working directory
WORKDIR /workspace

# Expose web / debugging ports if needed
EXPOSE 8080 3000

CMD ["sleep", "infinity"]
```

---

## 3. Volume Mounting & SELinux Flag (`:Z`)

When launching the container with Podman, the host workspace is bind-mounted to `/workspace`.

On SELinux-enabled systems (such as Fedora, RHEL, or WSL2 with SELinux), Podman requires the `:Z` flag on volume mounts:
```bash
podman run -d \
  --name focusguard-dev \
  -v "$(pwd):/workspace:Z" \
  -w /workspace \
  ghcr.io/cirruslabs/flutter:3.24.3 \
  sleep infinity
```
The `:Z` flag instructs Podman to automatically relabel the mounted directory with a private, unshared SELinux security context (`system_u:object_r:container_file_t:s0:c...`), granting the containerized process full read-write access while maintaining host filesystem isolation.

---

## 4. Container Lifecycle Troubleshooting

### 4.1 "Container focusguard-dev is already in use"
Run:
```bash
podman rm -f focusguard-dev
./dev-up
```

### 4.2 Permission Denied on Build Outputs
Inside the container, files may be created with root UID. All developer scripts handle directory ownership gracefully. If needed on the host, run:
```bash
podman unshare chown -R $UID:$GID .
```

### 4.3 Git Dubious Ownership Warning
The container automatically configures `git config --global --add safe.directory /workspace` to prevent Git security blocks across mounted volumes.
