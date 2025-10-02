#!/bin/bash

if [[ -f "./logs/installed" ]]; then
    if [ "${OCC}" == "1" ]; then 
        php ./nextcloud/occ ${COMMANDO_OCC}
        exit
    else
        echo "✓ Updating install.sh script"
        curl -sSL https://raw.githubusercontent.com/TinyBrickBoy/Nexcloud/refs/heads/main/install.sh -o install.sh
        chmod a+x ./install.sh
        echo "✓ Updating start.sh script"
        curl -sSL https://raw.githubusercontent.com/TinyBrickBoy/Nexcloud/refs/heads/main/start.sh -o start.sh
        chmod a+x ./start.sh
        ./start.sh
    fi
else
    cd /home/container/ || exit
    mkdir -p php-fpm logs tmp
    
    echo "**** Downloading Nextcloud ****"
    rm -rf nextcloud/
    if [ "${NEXTCLOUD_RELEASE}" == "latest" ]; then
        DOWNLOAD_LINK="latest.zip"
    else
        DOWNLOAD_LINK="nextcloud-${NEXTCLOUD_RELEASE}.zip"
    fi

    echo "✓ Updating install.sh script"
    curl -sSL https://raw.githubusercontent.com/TinyBrickBoy/Nexcloud/refs/heads/main/install.sh -o install.sh

    echo "✓ Cloning nginx and php-fpm setup"
    git clone https://github.com/finnie2006/ptero-nginx ./temp
    cp -r ./temp/nginx /home/container/
    cp -r ./temp/php-fpm /home/container/
    rm -rf ./temp
    rm -rf /home/container/webroot/* 2>/dev/null || true

    # Remove old configs
    rm -f nginx/conf.d/default.conf
    rm -f nginx/conf.d/nextcloud.conf
    
    echo "✓ Downloading Nextcloud nginx config"
    cd /home/container/nginx/conf.d/
    wget -O default.conf https://raw.githubusercontent.com/TinyBrickBoy/Nexcloud/refs/heads/main/default.conf
    cd /home/container
    
    cat <<EOF >./logs/install_log.txt
Version: $NEXTCLOUD_RELEASE
Link: https://download.nextcloud.com/server/releases/${DOWNLOAD_LINK}
File: ${DOWNLOAD_LINK}
EOF

    echo "✓ Downloading Nextcloud ${NEXTCLOUD_RELEASE}"
    wget -O "${DOWNLOAD_LINK}" "https://download.nextcloud.com/server/releases/${DOWNLOAD_LINK}"
    
    if [ -f "${DOWNLOAD_LINK}" ]; then
        echo "✓ Extracting Nextcloud"
        unzip -q "${DOWNLOAD_LINK}"
        rm -f "${DOWNLOAD_LINK}"
    else
        echo "❌ Error: Could not download Nextcloud"
        exit 1
    fi

    # Set permissions (no chown in container, just chmod)
    chmod -R 755 nextcloud
    
    echo "**** Cleaning up ****"
    rm -rf /tmp/* 2>/dev/null || true
    
    echo "**** Configure PHP and Nginx for Nextcloud ****"
    
    # Create PHP config directories if they don't exist
    mkdir -p php-fpm/conf.d
    
    # Configure PHP extensions
    if [ -f "php-fpm/conf.d/apcu.ini" ]; then
        echo 'apc.enable_cli=1' >> php-fpm/conf.d/apcu.ini
    fi
    
    # Configure PHP settings
    if [ -f "php-fpm/php.ini" ]; then
        sed -i \
            -e 's/;opcache.enable.*=.*/opcache.enable=1/g' \
            -e 's/;opcache.interned_strings_buffer.*=.*/opcache.interned_strings_buffer=16/g' \
            -e 's/;opcache.max_accelerated_files.*=.*/opcache.max_accelerated_files=10000/g' \
            -e 's/;opcache.memory_consumption.*=.*/opcache.memory_consumption=128/g' \
            -e 's/;opcache.save_comments.*=.*/opcache.save_comments=1/g' \
            -e 's/;opcache.revalidate_freq.*=.*/opcache.revalidate_freq=1/g' \
            -e 's/;always_populate_raw_post_data.*=.*/always_populate_raw_post_data=-1/g' \
            -e 's/memory_limit.*=.*128M/memory_limit=512M/g' \
            -e 's/max_execution_time.*=.*30/max_execution_time=120/g' \
            -e 's/upload_max_filesize.*=.*2M/upload_max_filesize=1024M/g' \
            -e 's/post_max_size.*=.*8M/post_max_size=1024M/g' \
            -e 's/output_buffering.*=.*/output_buffering=0/g' \
            php-fpm/php.ini
        
        sed -i '/opcache.enable=1/a opcache.enable_cli=1' php-fpm/php.ini
    fi
    
    if [ -f "php-fpm/php-fpm.conf" ]; then
        echo "env[PATH] = /usr/local/bin:/usr/bin:/bin" >> php-fpm/php-fpm.conf
    fi
    
    mkdir -p tmp
    touch ./logs/installed
    
    echo "✅ Installation complete!"
    echo "Run ./start.sh to start Nextcloud"
fi
