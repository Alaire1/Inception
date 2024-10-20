#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

# Configuration file for MariaDB
MARIADB_CONFIG="/etc/my.cnf.d/mariadb-server.cnf"
FIRST_RUN_FLAG="/etc/.firstrun"
FIRST_MOUNT_FLAG="/var/lib/mysql/.firstmount"

# Function to configure the server for the first run
configure_server() {
    echo "Configuring MariaDB server for the first run..."
    cat << EOF >> "$MARIADB_CONFIG"
[mysqld]
bind-address=0.0.0.0  # Allow connections from any IP address
skip-networking=0     # Enable networking
EOF
    touch "$FIRST_RUN_FLAG"  # Mark that the configuration has been applied
}

# Function to initialize the database on the first volume mount
initialize_database() {
    echo "Initializing the database for the first volume mount..."

    # Initialize a database in the specified data directory
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql

    # Start MariaDB in the background
    mysqld_safe &
    mysqld_pid=$!

    # Wait for the server to start
    until mysqladmin ping --silent; do
        echo "Waiting for MariaDB to start..."
        sleep 1
    done

    # Create database and user accounts
    echo "Setting up database and user accounts..."
    cat << EOF | mysql --protocol=socket -u root
CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\`;
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
FLUSH PRIVILEGES;
EOF

    # Shut down the temporary server and mark the volume as initialized
    mysqladmin shutdown
    touch "$FIRST_MOUNT_FLAG"
}

# Main script execution starts here
if [ ! -e "$FIRST_RUN_FLAG" ]; then
    configure_server
fi

if [ ! -e "$FIRST_MOUNT_FLAG" ]; then
    if [ -z "$MYSQL_DATABASE" ] || [ -z "$MYSQL_USER" ] || [ -z "$MYSQL_PASSWORD" ] || [ -z "$MYSQL_ROOT_PASSWORD" ]; then
        echo "Error: Missing environment variables. Exiting..."
        exit 1
    fi
    initialize_database
fi

# Execute the MariaDB server as the main process
echo "Starting MariaDB server..."
exec mysqld_safe
