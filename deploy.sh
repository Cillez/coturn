#!/bin/bash

# Hades Coturn Server Deployment Script
# Usage: ./deploy.sh [remote-host] [remote-user]

set -e

REMOTE_HOST=${1:-cdn.hades.lt}
REMOTE_USER=${2:-root}
REMOTE_DIR="/opt/hades-coturn-server"

echo "🚀 Deploying Hades Coturn Server to $REMOTE_USER@$REMOTE_HOST"

# Create deployment package
echo "📦 Creating deployment package..."
tar -czf hades-coturn-server.tar.gz \
    --exclude='logs/*' \
    --exclude='*.log' \
    --exclude='.git' \
    --exclude='node_modules' \
    --exclude='*.tar.gz' \
    .

# Copy to remote server
echo "📤 Copying to remote server..."
scp hades-coturn-server.tar.gz $REMOTE_USER@$REMOTE_HOST:~/

# Extract and setup on remote server
echo "🔧 Setting up on remote server..."
ssh $REMOTE_USER@$REMOTE_HOST << EOF
    # Create directory if it doesn't exist
    sudo mkdir -p $REMOTE_DIR
    sudo chown $REMOTE_USER:$REMOTE_USER $REMOTE_DIR

    # Extract files
    tar -xzf hades-coturn-server.tar.gz
    cd hades-coturn-server

    # Create logs directory
    mkdir -p logs

    # Generate SSL certificates if they don't exist
    if [ ! -d "/etc/letsencrypt/live/cdn.hades.lt" ]; then
        echo "🔐 Setting up SSL certificates..."
        sudo apt-get update
        sudo apt-get install -y certbot

        # Stop any existing web server temporarily
        sudo systemctl stop nginx || true
        sudo systemctl stop apache2 || true

        # Get Let's Encrypt certificate
        sudo certbot certonly --standalone -d cdn.hades.lt --agree-tos --register-unsafely-without-email

        # Restart web server if it was running
        sudo systemctl start nginx || true
        sudo systemctl start apache2 || true
    fi

    # Start the server
    echo "🎯 Starting coturn server..."
    docker-compose up -d

    # Show status
    echo "📊 Server status:"
    docker-compose ps

    # Show logs
    echo "📋 Recent logs:"
    docker-compose logs --tail=10 coturn

    echo "✅ Deployment complete!"
    echo "🌐 Coturn server should be available at:"
    echo "   STUN/TURN: turn:cdn.hades.lt:3478"
    echo "   TURN TLS:  turns:cdn.hades.lt:5349"
EOF

# Cleanup
rm hades-coturn-server.tar.gz

echo "🧹 Cleanup complete"
echo ""
echo "🎉 Deployment finished successfully!"
echo ""
echo "📖 Next steps:"
echo "   1. Verify the server is running: ssh $REMOTE_USER@$REMOTE_HOST 'cd $REMOTE_DIR && docker-compose ps'"
echo "   2. Check logs: ssh $REMOTE_USER@$REMOTE_HOST 'cd $REMOTE_DIR && docker-compose logs -f coturn'"
echo "   3. Test connectivity from your backend server"
echo ""
echo "🔧 Useful commands:"
echo "   Start:  docker-compose up -d"
echo "   Stop:   docker-compose down"
echo "   Logs:   docker-compose logs -f coturn"
echo "   Status: docker-compose ps"
