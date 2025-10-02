#!/bin/bash
# Nextcloud Start Script für Pterodactyl
# Speichern als: /home/container/start.sh

cd /home/container || exit

# Bereinige temp Verzeichnis
rm -rf /home/container/tmp/*
mkdir -p /home/container/tmp

echo "⚙️ Script Version: 2.0"
echo "🛠 Starting PHP-FPM..."

# Prüfe ob PHP-FPM Binary existiert
if [ -f "/home/container/php-fpm/sbin/php-fpm" ]; then
    /home/container/php-fpm/sbin/php-fpm \
        --fpm-config /home/container/php-fpm/php-fpm.conf \
        --prefix /home/container/php-fpm \
        --daemonize
    echo "✅ PHP-FPM started (local binary)"
elif [ -f "/usr/sbin/php-fpm" ]; then
    /usr/sbin/php-fpm \
        --fpm-config /home/container/php-fpm/php-fpm.conf \
        --daemonize
    echo "✅ PHP-FPM started (system binary)"
elif [ -f "/usr/sbin/php-fpm82" ]; then
    /usr/sbin/php-fpm82 \
        --fpm-config /home/container/php-fpm/php-fpm.conf \
        --daemonize
    echo "✅ PHP-FPM82 started"
elif [ -f "/usr/sbin/php-fpm83" ]; then
    /usr/sbin/php-fpm83 \
        --fpm-config /home/container/php-fpm/php-fpm.conf \
        --daemonize
    echo "✅ PHP-FPM83 started"
else
    echo "❌ PHP-FPM binary not found!"
    echo "Looking in:"
    echo "  - /home/container/php-fpm/sbin/php-fpm"
    echo "  - /usr/sbin/php-fpm*"
    exit 1
fi

# Warte kurz damit PHP-FPM starten kann
sleep 2

echo "🛠 Starting Nginx..."

# Prüfe ob Nginx Binary existiert
if [ -f "/home/container/nginx/sbin/nginx" ]; then
    /home/container/nginx/sbin/nginx \
        -c /home/container/nginx/nginx.conf \
        -p /home/container/nginx/
    echo "✅ Nginx started (local binary)"
elif [ -f "/usr/sbin/nginx" ]; then
    /usr/sbin/nginx \
        -c /home/container/nginx/nginx.conf \
        -p /home/container/
    echo "✅ Nginx started (system binary)"
else
    echo "❌ Nginx binary not found!"
    echo "Looking in:"
    echo "  - /home/container/nginx/sbin/nginx"
    echo "  - /usr/sbin/nginx"
    exit 1
fi

echo ""
echo "============================================"
echo "✅ Nextcloud is now running!"
echo "============================================"
echo "📍 Access it via your server's IP:PORT"
echo ""
echo "📋 Logs:"
echo "   - Nginx: /home/container/logs/nginx_error.log"
echo "   - PHP-FPM: /home/container/logs/php-fpm_error.log"
echo ""
echo "💡 Tip: Use 'php nextcloud/occ' for CLI commands"
echo "============================================"
echo ""

# Halte Container am Laufen durch Log-Tailing
tail -f /home/container/logs/*.log 2>/dev/null || sleep infinity
