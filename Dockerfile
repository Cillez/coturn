FROM alpine:latest

# Install coturn and required dependencies
RUN apk add --no-cache \
    coturn \
    openssl \
    curl \
    && rm -rf /var/cache/apk/*

# Verify coturn installation
RUN which coturn && coturn --version

# Create coturn user and group
RUN addgroup -g 1000 coturn && \
    adduser -D -u 1000 -G coturn coturn

# Create necessary directories
RUN mkdir -p /etc/coturn /var/log/coturn /var/lib/coturn && \
    chown -R coturn:coturn /etc/coturn /var/log/coturn /var/lib/coturn

# Copy configuration files
COPY turnserver.conf /etc/coturn/turnserver.conf
COPY entrypoint.sh /entrypoint.sh

# Make entrypoint executable
RUN chmod +x /entrypoint.sh

# Expose ports
EXPOSE 3478 3478/udp 5349 5349/tcp 49152-49999 49152-49999/udp

# Set working directory
WORKDIR /var/lib/coturn

# Health check - check if coturn process is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD pgrep -x "coturn" > /dev/null || exit 1

# Start coturn (run as root to access coturn binary)
ENTRYPOINT ["/entrypoint.sh"]
