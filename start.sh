#!/bin/bash
cd /home/container || exit

# Clean temp directory
rm -rf /home/container/tmp/*
mkdir -p /home/container/tmp

echo "⚙️ Script Version: 2.0"
echo "🛠 Starting PHP-FPM..."

# Check if PHP-FPM binary exists
if [ -f "/home/container/php-fpm/sbin/php-fpm" ]; then
    /home/container/php-fpm/sbin/php-fpm \
        --fpm-config /home/container/php-fpm/php-fpm.conf \
        --prefix /home/container/php-fpm \
        --daemonize
    echo "✅ PHP-FPM started"
elif [ -f "/usr/sbin/php-fpm" ]; then
    /usr/sbin/php-fpm \
        --fpm-config /home/container/php-fpm/php-fpm.conf \
        --daemonize
    echo "✅ PHP-FPM started (system binary)"
else
    echo "❌ PHP-FPM binary not found!"
    exit 1
fi

sleep 2

echo "🛠 Starting Nginx..."

# Check if Nginx binary exists
if [ -f "/home/container/nginx/sbin/nginx" ]; then
    /home/container/nginx/sbin/nginx \
        -c /home/container/nginx/nginx.conf \
        -p /home/container/nginx/
    echo "✅ Nginx started"
elif [ -f "/usr/sbin/nginx" ]; then
    /usr/sbin/nginx \
        -c /home/container/nginx/nginx.conf \
        -p /home/container/
    echo "✅ Nginx started (system binary)"
else
    echo "❌ Nginx binary not found!"
    exit 1
fi

echo ""
echo "✅ Nextcloud is now running!"
echo "📍 Access it via your server's IP:PORT"
echo ""
echo "📋 Logs:"
echo "   - Nginx: /home/container/logs/nginx_error.log"
echo "   - PHP-FPM: /home/container/logs/php-fpm_error.log"
echo ""

# Keep container running by tailing logs
tail -f /home/container/logs/*.log 2>/dev/null || sleep infinity
