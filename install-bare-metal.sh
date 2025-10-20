#!/bin/bash

# Hades Coturn Server Bare-Metal Installation Script
# This script installs and configures Coturn directly on the VPS

set -e

echo "🚀 Installing Hades Coturn Server (Bare-Metal)..."
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root (sudo)"
    exit 1
fi

# Update package lists
echo "📦 Updating package lists..."
apt-get update

# Install required packages
echo "🔧 Installing Coturn and dependencies..."
apt-get install -y coturn openssl curl certbot

# Create coturn user and directories
echo "👤 Creating coturn user and directories..."
useradd -r -s /bin/false coturn
mkdir -p /etc/coturn /var/log/coturn /var/lib/coturn
chown -R coturn:coturn /etc/coturn /var/log/coturn /var/lib/coturn

# Copy configuration file
echo "⚙️  Installing configuration..."
cp turnserver-bare-metal.conf /etc/coturn/turnserver.conf
chmod 644 /etc/coturn/turnserver.conf
chown coturn:coturn /etc/coturn/turnserver.conf

# Generate SSL certificates if they don't exist
echo "🔐 Setting up SSL certificates..."
if [ ! -d "/etc/letsencrypt/live/coturn.dybng.no" ]; then
    echo "📜 Obtaining Let's Encrypt certificate..."

    # Stop any existing web servers temporarily
    systemctl stop nginx 2>/dev/null || true
    systemctl stop apache2 2>/dev/null || true

    # Get certificate
    certbot certonly --standalone -d coturn.dybng.no --agree-tos --register-unsafely-without-email

    # Restart web servers if they were running
    systemctl start nginx 2>/dev/null || true
    systemctl start apache2 2>/dev/null || true

    echo "✅ SSL certificate obtained!"
else
    echo "✅ SSL certificates already exist"
fi

# Set correct permissions on certificates
echo "🔒 Setting certificate permissions..."
chmod 644 /etc/letsencrypt/live/coturn.dybng.no/fullchain.pem
chmod 600 /etc/letsencrypt/live/coturn.dybng.no/privkey.pem
chown coturn:coturn /etc/letsencrypt/live/coturn.dybng.no/privkey.pem

# Install systemd service
echo "🔧 Installing systemd service..."
cp hades-coturn.service /etc/systemd/system/hades-coturn.service
chmod 644 /etc/systemd/system/hades-coturn.service

# Reload systemd
systemctl daemon-reload

# Enable and start service
echo "🎯 Starting Coturn service..."
systemctl enable hades-coturn
systemctl start hades-coturn

# Wait a moment and check status
sleep 3
echo ""
echo "📊 Service status:"
systemctl status hades-coturn --no-pager -l

echo ""
echo "✅ Installation complete!"
echo ""
echo "🌐 Coturn server is running at:"
echo "   STUN/TURN: turn:coturn.dybng.no:3478"
echo "   TURN TLS:  turns:coturn.dybng.no:5349"
echo ""
echo "🔧 Management commands:"
echo "   Start:    systemctl start hades-coturn"
echo "   Stop:     systemctl stop hades-coturn"
echo "   Restart:  systemctl restart hades-coturn"
echo "   Status:   systemctl status hades-coturn"
echo "   Logs:     journalctl -u hades-coturn -f"
echo ""
echo "🔒 Security notes:"
echo "   - Firewall should allow ports 3478, 5349, and 49152-49999"
echo "   - Certificates auto-renew via certbot timer"
echo "   - Service runs as coturn user for security"
