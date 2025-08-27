#!/bin/bash
set -e

# Function to wait for database connection
wait_for_db() {
    echo "Waiting for database connection..."
    if [ -n "$DATABASE_URL" ]; then
        # Extract database info from DATABASE_URL
        DB_HOST=$(echo $DATABASE_URL | sed -n 's/.*@\([^:]*\):.*/\1/p')
        DB_PORT=$(echo $DATABASE_URL | sed -n 's/.*:\([0-9]*\)\/.*/\1/p')
        
        if [ -n "$DB_HOST" ] && [ -n "$DB_PORT" ]; then
            until nc -z $DB_HOST $DB_PORT; do
                echo "Waiting for database at $DB_HOST:$DB_PORT..."
                sleep 2
            done
            echo "Database is ready!"
        fi
    fi
}

# Function to create Drupal settings
create_drupal_settings() {
    if [ ! -f /var/www/html/web/sites/default/settings.php ]; then
        echo "Creating Drupal settings.php..."
        
        # Check if default.settings.php exists, if not create a basic one
        if [ ! -f /var/www/html/web/sites/default/default.settings.php ]; then
            echo "Creating basic default.settings.php..."
            cat > /var/www/html/web/sites/default/default.settings.php << 'EOF'
<?php

/**
 * @file
 * Drupal site-specific configuration file.
 */

// Database configuration will be added by the entrypoint script
EOF
        fi
        
        cp /var/www/html/web/sites/default/default.settings.php /var/www/html/web/sites/default/settings.php
        
        # Add database configuration
        cat >> /var/www/html/web/sites/default/settings.php << EOF

// Database configuration from environment
\$databases['default']['default'] = [
  'driver' => 'pgsql',
  'database' => 'railway',
  'username' => 'postgres',
  'password' => 'SIJqyJWaqYNIPzNzwZVMrNYDGLSuiebc',
  'host' => 'postgres.railway.internal',
  'port' => '5432',
  'prefix' => '',
];

// Trusted host patterns
\$settings['trusted_host_patterns'] = [
  '^localhost$',
  '^.*\.railway\.app$',
  '^.*\.railway\.dev$',
];

// Hash salt
\$settings['hash_salt'] = '${DRUPAL_HASH_SALT:-$(openssl rand -hex 32)}';

// File system settings
\$settings['file_public_path'] = 'sites/default/files';
\$settings['file_private_path'] = 'sites/default/files/private';

// Performance settings
\$settings['cache']['bins']['render'] = 'cache.backend.null';
\$settings['cache']['bins']['dynamic_page_cache'] = 'cache.backend.null';
\$settings['cache']['bins']['page'] = 'cache.backend.null';
EOF
        
        chown www-data:www-data /var/www/html/web/sites/default/settings.php
        chmod 644 /var/www/html/web/sites/default/settings.php
    fi
}

# Function to install Drupal if not already installed
install_drupal() {
    if [ ! -f /var/www/html/web/sites/default/settings.php ]; then
        echo "Drupal not installed. Please configure settings.php first."
        return 1
    fi
    
    # Check if Drupal is already installed by looking for users table
    if [ ! -f /var/www/html/web/core/scripts/drupal ]; then
        echo "Drupal core scripts not found. Skipping automatic installation."
        echo "Please install Drupal manually via web interface at /install.php"
        echo "Or check if Drupal core is properly installed in /var/www/html/web/core/"
        return 1
    fi
    
    # Check if Drupal is already installed by looking for users table
    echo "Checking if Drupal is already installed..."
    if ! php /var/www/html/web/core/scripts/drupal database:status 2>/dev/null | grep -q "Connected"; then
        echo "Drupal not installed. Please install manually via web interface at /install.php"
        echo "Database connection available. You can proceed with manual installation."
        return 0
    else
        echo "Drupal already installed."
    fi
}

# Main execution
echo "Starting FarmOS container..."

# Wait for database
wait_for_db

# Ensure Drupal directory exists
if [ ! -d /var/www/html/web/core ]; then
    echo "Error: /var/www/html/web/core directory not found. Composer install may have failed."
    echo "Container will continue running for debugging..."
    echo "Contents of /var/www/html:"
    ls -la /var/www/html/ || echo "Cannot list Drupal directory"
else
    echo "Drupal core directory found"
    
    # Debug: List contents of Drupal directory
    echo "Contents of /var/www/html:"
    ls -la /var/www/html/ || echo "Cannot list Drupal directory"

    # Debug: Check if web directory exists
    if [ -d /var/www/html/web ]; then
        echo "Web directory found"
        ls -la /var/www/html/web/ || echo "Cannot list web directory"
    else
        echo "Web directory not found"
    fi

    # Debug: Check if core directory exists
    if [ -d /var/www/html/web/core ]; then
        echo "Drupal core directory found"
        ls -la /var/www/html/web/core/ || echo "Cannot list core directory"
    else
        echo "Drupal core directory not found"
    fi

    # Create Drupal settings
    create_drupal_settings

    # Install Drupal if needed
    install_drupal

    # Set proper permissions
    chown -R www-data:www-data /var/www/html/web/sites/default/files
fi

echo "FarmOS container ready!"

# Execute the main command
exec "$@"
