#!/bin/sh

# Hades Coturn Server Entrypoint Script
# This script initializes and starts the coturn server

set -e

echo "🚀 Starting Hades Coturn Server..."
echo "📍 Domain: ${TURN_DOMAIN:-cdn.hades.lt}"
echo "🌐 Realm: ${TURN_REALM:-cdn.hades.lt}"
echo "🔐 External IP: ${EXTERNAL_IP:-auto}"
echo "📊 Port Range: ${MIN_PORT:-49152}-${MAX_PORT:-49999}"

# Create log directory if it doesn't exist
mkdir -p /var/log/coturn

# Check if SSL certificates exist and are readable
CERT_PATH="/etc/letsencrypt/live/cdn.hades.lt"
echo "🔍 Checking SSL certificates at: ${CERT_PATH}"

if [ -f "${CERT_PATH}/fullchain.pem" ] && [ -f "${CERT_PATH}/privkey.pem" ]; then
    echo "✅ SSL certificates found!"
    echo "   📄 Full chain: $(ls -la ${CERT_PATH}/fullchain.pem)"
    echo "   🔑 Private key: $(ls -la ${CERT_PATH}/privkey.pem)"

    # Test if we can read the certificates
    if test -r ${CERT_PATH}/fullchain.pem && test -r ${CERT_PATH}/privkey.pem; then
        echo "✅ Can read certificates"
    else
        echo "⚠️  Warning: Cannot read certificates"
        echo "   Fixing permissions..."
        chmod 644 ${CERT_PATH}/fullchain.pem 2>/dev/null || echo "   Could not set permissions on fullchain.pem"
        chmod 600 ${CERT_PATH}/privkey.pem 2>/dev/null || echo "   Could not set permissions on privkey.pem"
    fi

else
    echo "❌ SSL certificates not found at ${CERT_PATH}/"
    echo "   Expected files:"
    echo "   - ${CERT_PATH}/fullchain.pem"
    echo "   - ${CERT_PATH}/privkey.pem"
    echo ""
    echo "🔧 Current directory contents:"
    ls -la ${CERT_PATH}/ 2>/dev/null || echo "   Directory not accessible"
    echo ""
    echo "🔍 Searching for certificates in /etc/letsencrypt:"
    find /etc/letsencrypt -name "*.pem" 2>/dev/null | head -10
    echo ""
    echo "⚠️  TLS will not be available. Make sure certificates are mounted correctly."
    echo ""
    echo "💡 Solutions:"
    echo "   1. Check Docker volume mount in docker-compose.yml"
    echo "   2. Verify certificate permissions (644 for fullchain.pem, 600 for privkey.pem)"
    echo "   3. For development, comment out TLS settings in turnserver.conf"
fi

# Validate required environment variables
if [ -z "${TURN_SECRET}" ]; then
    echo "❌ Error: TURN_SECRET environment variable is required"
    exit 1
fi

# Generate configuration file from template if needed
if [ ! -f /etc/coturn/turnserver.conf ]; then
    echo "❌ Error: turnserver.conf not found"
    exit 1
fi

# Basic configuration validation
echo "🔍 Validating configuration..."

# Check if configuration file is readable
if [ ! -r /etc/coturn/turnserver.conf ]; then
    echo "❌ Error: Cannot read turnserver.conf"
    exit 1
fi

# Check for required settings in config file
if ! grep -q "listening-port=3478" /etc/coturn/turnserver.conf; then
    echo "❌ Error: listening-port not found in configuration"
    exit 1
fi

if ! grep -q "static-auth-secret=" /etc/coturn/turnserver.conf; then
    echo "❌ Error: static-auth-secret not found in configuration"
    exit 1
fi

echo "✅ Configuration validation passed"
echo "🎯 Starting coturn server..."

# Find coturn binary
COTURN_BIN=$(which coturn || find /usr -name "*coturn*" -type f -executable 2>/dev/null | head -1)

if [ -z "$COTURN_BIN" ]; then
    echo "❌ Error: coturn binary not found"
    exit 1
fi

echo "📍 Using coturn binary: $COTURN_BIN"

# Start coturn with the generated configuration
exec "$COTURN_BIN" -c /etc/coturn/turnserver.conf -v
