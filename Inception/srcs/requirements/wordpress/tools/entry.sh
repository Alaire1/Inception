#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status
cd /var/www/html

# Configure PHP-FPM on the first run
if [ ! -e /etc/.firstrun ]; then
    # Update PHP-FPM to listen on all interfaces (port 9000) instead of localhost
    sed -i 's/listen = 127.0.0.1:9000/listen = 9000/g' /etc/php82/php-fpm.d/www.conf
    touch /etc/.firstrun  # Mark the first run configuration as complete
fi

# On the first volume mount, download and configure WordPress
if [ ! -e .firstmount ]; then
    # Wait for MariaDB to be ready before proceeding
    mariadb-admin ping --protocol=tcp --host=mariadb -u "$MYSQL_USER" --password="$MYSQL_PASSWORD" --wait >/dev/null 2>/dev/null

    # Check if WordPress is already installed by looking for the wp-config.php file
    if [ ! -f wp-config.php ]; then
        echo "Installing WordPress..."

        # Download and set up WordPress core files
        wp core download --allow-root || true
        
        # Generate WordPress configuration file (wp-config.php) with the provided database credentials
        wp config create --allow-root \
            --dbhost=mariadb \
            --dbuser="$MYSQL_USER" \
            --dbpass="$MYSQL_PASSWORD" \
            --dbname="$MYSQL_DATABASE"

        # Configure WordPress installation (skip email setup)
        wp core install --allow-root \
            --skip-email \
            --url="$DOMAIN_NAME" \
            --title="$WORDPRESS_TITLE" \
            --admin_user="$WORDPRESS_ADMIN_USER" \
            --admin_password="$WORDPRESS_ADMIN_PASSWORD" \
            --admin_email="$WORDPRESS_ADMIN_EMAIL"

        # Create a regular WordPress user if it doesn't already exist
        if ! wp user get "$WORDPRESS_USER" --allow-root > /dev/null 2>&1; then
            wp user create "$WORDPRESS_USER" "$WORDPRESS_EMAIL" --role=author --user_pass="$WORDPRESS_PASSWORD" --allow-root
        fi
    else
        echo "WordPress is already installed."
    fi

    # Ensure correct permissions for the wp-content directory (write access for others)
    chmod o+w -R /var/www/html/wp-content
    touch .firstmount  # Mark the first mount setup as complete
fi

# Start PHP-FPM service in the foreground
exec /usr/sbin/php-fpm82 -F
