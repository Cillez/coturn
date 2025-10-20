# Hades Coturn Server

A production-ready TURN/STUN server for the Hades Project, optimized for P2P gaming traffic.

## Overview

This Coturn server provides:
- **STUN** (Session Traversal Utilities for NAT) for NAT traversal
- **TURN** (Traversal Using Relays around NAT) for fallback connectivity
- **TLS encryption** for secure WebRTC connections
- **WebRTC compatibility** with proper ICE server configuration

## Quick Start

### Prerequisites

- A domain name (e.g., `coturn.dybng.no`)
- SSL certificates (Let's Encrypt recommended)
- Open ports: 3478, 5349, and 49152-49999

### Deployment Options

**Option 1: Docker (Recommended for development/testing)**
- Docker and Docker Compose
- Easy to manage and update

**Option 2: Bare-Metal (Recommended for production VPS)**
- Direct installation on VPS
- Better performance and resource usage
- More control over system configuration

### 1. Configuration

```bash
# Copy the example environment file
cp .env.example .env

# Edit the configuration
nano .env
```

**Required Settings:**
```bash
# Domain must match your SSL certificate
TURN_DOMAIN=coturn.dybng.no
TURN_REALM=coturn.dybng.no

# Must match your backend's TURN_SECRET
TURN_SECRET=test-secret-key

# Set to your server's public IP
EXTERNAL_IP=your-server-ip
```

### 2. SSL Certificates

For production deployment, obtain SSL certificates:

```bash
# Using Let's Encrypt (recommended)
sudo certbot certonly --standalone -d coturn.dybng.no

# Or using Docker
docker run -it --rm --name certbot \
  -v "/etc/letsencrypt:/etc/letsencrypt" \
  -v "/var/lib/letsencrypt:/var/lib/letsencrypt" \
  certbot/certbot certonly --standalone -d coturn.dybng.no

# Verify certificates exist
ls -la /etc/letsencrypt/live/coturn.dybng.no/
```

## Bare-Metal Deployment (Production VPS)

For production deployment on a dedicated VPS, use the bare-metal installation:

### 1. Copy Files to VPS

```bash
# Copy the entire hades-coturn-server directory to your VPS
scp -r hades-coturn-server/ user@your-vps:~/
```

### 2. Install and Configure

```bash
# SSH to your VPS
ssh user@your-vps
cd hades-coturn-server

# Run the installation script (as root)
sudo ./install-bare-metal.sh
```

### 3. Verify Installation

```bash
# Check service status
sudo systemctl status hades-coturn

# View logs
sudo journalctl -u hades-coturn -f

# Test connectivity
curl -v turn:coturn.dybng.no:3478
```

## Docker Deployment (Development/Testing)

### 3. Start the Server

```bash
# Start the server (auto-detects Docker Compose version)
./start.sh

# Or manually with Docker Compose
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f coturn
```

**Quick Start Script:**
```bash
# The start.sh script handles both old and new Docker Compose versions
./start.sh
```

## Deployment to Remote Host

### Option 1: Bare-Metal (Recommended for Production)

For dedicated Coturn servers, bare-metal deployment offers better performance:

**Advantages:**
- Lower resource overhead (no Docker layer)
- Direct access to hardware acceleration
- Better network performance
- Simpler troubleshooting
- More control over system configuration

**Deployment Steps:**
```bash
# Copy files to VPS
scp -r hades-coturn-server/ user@coturn.dybng.no:~/

# SSH and install
ssh user@coturn.dybng.no
cd hades-coturn-server
sudo ./install-bare-metal.sh
```

### Option 2: Docker Compose (Development/Testing)

1. **Copy files to server:**
   ```bash
   scp -r hades-coturn-server/ user@coturn.dybng.no:~
   ```

2. **SSH to server and start:**
   ```bash
   ssh user@coturn.dybng.no
   cd hades-coturn-server
   docker-compose up -d
   ```

### Option 2: Docker Only

```bash
# Build and run
docker build -t hades-coturn .
docker run -d \
  --name hades-coturn \
  --network host \
  --env-file .env \
  -v /etc/letsencrypt:/etc/letsencrypt:ro \
  -v ./logs:/var/log/coturn \
  hades-coturn
```

### Option 3: Systemd Service for Docker

Create `/etc/systemd/system/hades-coturn.service`:

```ini
[Unit]
Description=Hades Coturn Server (Docker)
After=network.target docker.service

[Service]
Type=simple
User=root
WorkingDirectory=/path/to/hades-coturn-server
ExecStart=/usr/bin/docker-compose up
ExecStop=/usr/bin/docker-compose down
Restart=always

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl enable hades-coturn
sudo systemctl start hades-coturn
```

## Configuration Reference

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `TURN_DOMAIN` | Domain name for TURN server | cdn.hades.lt | Yes |
| `TURN_REALM` | Authentication realm | cdn.hades.lt | Yes |
| `TURN_SECRET` | Shared secret (must match backend) | - | Yes |
| `EXTERNAL_IP` | Server's public IP address | auto | Yes* |
| `MIN_PORT` | Minimum relay port | 49152 | No |
| `MAX_PORT` | Maximum relay port | 49999 | No |
| `TURN_TTL_SECONDS` | Credential TTL in seconds | 1200 | No |

*Required for production deployment

### Ports Used

| Port | Protocol | Purpose |
|------|----------|---------|
| 3478 | UDP/TCP | STUN/TURN |
| 5349 | TCP | TURN over TLS |
| 49152-49999 | UDP | Relay ports |
| 9641 | TCP | Prometheus metrics |

## Monitoring

### Health Check

```bash
# Check if coturn is running
docker-compose exec coturn pgrep coturn

# View logs
docker-compose logs coturn

# Prometheus metrics (if enabled)
curl http://localhost:9641/metrics
```

### Troubleshooting

**Common Issues:**

1. **"TURN not configured" error**
   - Check that `TURN_SECRET` matches your backend configuration
   - Verify the backend can reach the TURN server

2. **SSL Certificate Issues**
   ```bash
   # Check if certificates exist on host
   ls -la /etc/letsencrypt/live/coturn.dybng.no/

   # Check certificate permissions
   sudo chmod 644 /etc/letsencrypt/live/coturn.dybng.no/fullchain.pem
   sudo chmod 600 /etc/letsencrypt/live/coturn.dybng.no/privkey.pem

   # Test certificate validity
   openssl x509 -in /etc/letsencrypt/live/coturn.dybng.no/fullchain.pem -text -noout

   # If using custom certificate paths, update docker-compose.yml volumes
   ```

3. **Coturn binary not found**
   - The container will automatically find the coturn binary
   - Check logs for the exact path being used

4. **Connection failures**
   - Ensure all required ports are open in firewall
   - Check `EXTERNAL_IP` setting matches your server IP
   - Verify SSL certificates are valid and accessible

5. **Performance issues**
   - Monitor bandwidth usage with: `docker-compose logs coturn`
   - Adjust `BANDWIDTH_LIMIT_PER_PEER_KBPS` if needed
   - Check system resources: `docker stats`

### Logs

Logs are written to:
- Container: `/var/log/coturn/coturn.log`
- Host: `./logs/coturn.log` (via volume mount)

## Security Considerations

- **Firewall**: Only expose necessary ports (3478, 5349, 49152-49999)
- **Certificates**: Use valid SSL certificates for TLS
- **Secrets**: Keep `TURN_SECRET` secure and consistent across services
- **Updates**: Regularly update the coturn Docker image
- **Monitoring**: Monitor for unusual traffic patterns

## Integration with Hades Project

This TURN server is compatible with:
- **hades-backend-go**: Provides ICE configuration via `/api/p2p/ice`
- **hades-launcher**: Uses ICE servers for WebRTC P2P connections
- **p2p-go-seeder**: Uses ICE servers for peer discovery

The server generates ephemeral TURN credentials using the shared secret, ensuring secure authentication for all P2P connections.

## Performance Tuning

For high-traffic scenarios, consider:

- **Load Balancing**: Deploy multiple TURN servers behind a load balancer
- **Geographic Distribution**: Deploy servers in multiple regions
- **Resource Allocation**: Increase Docker resource limits
- **Bandwidth Monitoring**: Monitor and limit per-peer bandwidth

## Support

For issues related to:
- **Server Configuration**: Check logs and configuration files
- **Network Issues**: Verify firewall and port accessibility
- **Integration Problems**: Ensure backend and launcher configurations match

The TURN server configuration is optimized for gaming traffic with appropriate bandwidth limits and connection handling.
