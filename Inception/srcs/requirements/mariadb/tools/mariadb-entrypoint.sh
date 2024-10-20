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
    mysql_install_db --datadir=/var/lib/mysql --skip-test-db --user=mysql --group=mysql \
        --auth-root-authentication-method=socket >/dev/null 2>/dev/null

    # Start MariaDB in the background
    mysqld_safe &
    mysqld_pid=$!  # Store the PID of the background process

    # Wait for the server to start
    mysqladmin ping -u root --silent --wait >/dev/null 2>/dev/null

    # Create database and user accounts
    echo "Setting up database and user accounts..."
    cat << EOF | mysql --protocol=socket -u root -p=
CREATE DATABASE $MYSQL_DATABASE;  # Create the specified database
CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';  # Create user with specified password
GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';  # Grant privileges to the user
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';  # Grant privileges to root
FLUSH PRIVILEGES;  # Refresh privileges
EOF

    # Shut down the temporary server and mark the volume as initialized
    mysqladmin shutdown
    touch "$FIRST_MOUNT_FLAG"  # Indicate that the volume has been initialized
}

# Main script execution starts here
if [ ! -e "$FIRST_RUN_FLAG" ]; then
    configure_server  # Configure server on first run
fi

if [ ! -e "$FIRST_MOUNT_FLAG" ]; then
    initialize_database  # Initialize database on first mount
fi

# Execute the MariaDB server as the main process
echo "Starting MariaDB server..."
exec mysqld_safe 

