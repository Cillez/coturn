#!/bin/bash

# Certificate Check Script for Hades Coturn Server
# This script helps diagnose SSL certificate issues

echo "🔍 Checking SSL certificates for Hades Coturn Server..."
echo ""

# Check if Let's Encrypt certificates exist
CERT_PATH="/etc/letsencrypt/live/coturn.dybng.no"
echo "📍 Checking certificate path: $CERT_PATH"

if [ -f "$CERT_PATH/fullchain.pem" ] && [ -f "$CERT_PATH/privkey.pem" ]; then
    echo "✅ Certificates found!"

    # Check permissions
    echo ""
    echo "🔐 Checking certificate permissions..."
    ls -la "$CERT_PATH/"

    # Check certificate validity
    echo ""
    echo "📜 Checking certificate validity..."
    openssl x509 -in "$CERT_PATH/fullchain.pem" -text -noout | grep -E "(Subject:|Issuer:|Not Before:|Not After:)"

    echo ""
    echo "🎯 Certificate looks good!"
    echo ""
echo "💡 Next steps:"
echo "   1. Restart the coturn container: $DOCKER_COMPOSE_CMD restart coturn"
echo "   2. Check logs: $DOCKER_COMPOSE_CMD logs -f coturn"
echo "   3. Test from backend: curl https://coturn.dybng.no:5349/"

else
    echo "❌ Certificates not found at $CERT_PATH"
    echo ""
    echo "🔧 Possible solutions:"
    echo ""

    # Check if certbot is installed
    if command -v certbot &> /dev/null; then
        echo "1️⃣  Generate new certificates:"
        echo "   sudo certbot certonly --standalone -d coturn.dybng.no"
        echo ""
    fi

    echo "2️⃣  Check if certificates are in a different location:"
    echo "   find /etc -name "*.pem" 2>/dev/null | grep -i letsencrypt"
    echo ""

    echo "3️⃣  Manual certificate setup:"
    echo "   - Copy your certificates to /etc/letsencrypt/live/coturn.dybng.no/"
    echo "   - Ensure correct permissions (644 for fullchain.pem, 600 for privkey.pem)"
    echo ""

    echo "4️⃣  Run without TLS (development only):"
    echo "   - Comment out TLS settings in turnserver.conf"
    echo "   - Coturn will work with STUN/TURN only (no TLS)"
    echo ""

    echo "5️⃣  Check Docker volume mounts in docker-compose.yml"
    echo ""

fi

echo "🔍 Checking Docker container status..."

# Try docker compose first (newer versions), then fall back to docker-compose
if command -v "docker compose" &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker compose"
elif command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
else
    echo "❌ Docker Compose not found. Please install Docker Compose."
    exit 1
fi

echo "📍 Using Docker Compose command: $DOCKER_COMPOSE_CMD"

if $DOCKER_COMPOSE_CMD ps coturn | grep -q "Up"; then
    echo "✅ Coturn container is running"
else
    echo "❌ Coturn container is not running"
    echo "   Start it with: $DOCKER_COMPOSE_CMD up -d"
fi

echo ""
echo "📊 Quick status check:"
echo "   Container status: $($DOCKER_COMPOSE_CMD ps coturn)"
echo "   Recent logs (last 5 lines):"
$DOCKER_COMPOSE_CMD logs --tail=5 coturn 2>/dev/null || echo "   (No logs available)"
