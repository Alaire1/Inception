#!/bin/bash
set -e  

MARIADB_CONFIG="/etc/my.cnf.d/mariadb-server.cnf"
FIRST_RUN_FLAG="/etc/.firstrun"
FIRST_MOUNT_FLAG="/var/lib/mysql/.firstmount"


configure_server() {
    echo "Configuring MariaDB server for the first run..."
    cat << EOF >> "$MARIADB_CONFIG"
[mysqld]
bind-address=0.0.0.0  # Allow connections from any IP address
skip-networking=0     # Enable networking
EOF
    touch "$FIRST_RUN_FLAG"  
}


initialize_database() {
    echo "Initializing the database for the first volume mount..."

    
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql

    
    mysqld_safe &
    mysqld_pid=$!

    
    until mysqladmin ping --silent; do
        echo "Waiting for MariaDB to start..."
        sleep 1
    done


    echo "Setting up database and user accounts..."
    cat << EOF | mysql --protocol=socket -u root
        CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\`;
        CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
        GRANT ALL PRIVILEGES ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%';
        GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
        FLUSH PRIVILEGES;
EOF

    mysqladmin shutdown
    touch "$FIRST_MOUNT_FLAG"
}

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

echo "Starting MariaDB server..."
exec mysqld_safe
