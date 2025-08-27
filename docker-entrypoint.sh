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
    echo "Checking for settings.php..."
    if [ ! -f /var/www/html/sites/default/settings.php ]; then
        echo "Creating Drupal settings.php..."
        
        # Check if default.settings.php exists
        if [ ! -f /var/www/html/sites/default/default.settings.php ]; then
            echo "ERROR: default.settings.php not found!"
            echo "Contents of sites/default/:"
            ls -la /var/www/html/sites/default/ || echo "Cannot list directory"
            return 1
        fi
        
        echo "Copying default.settings.php to settings.php..."
        cp /var/www/html/sites/default/default.settings.php /var/www/html/sites/default/settings.php
        
        # Add database configuration
        cat >> /var/www/html/sites/default/settings.php << EOF

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
        
        chown www-data:www-data /var/www/html/sites/default/settings.php
        chmod 644 /var/www/html/sites/default/settings.php
    fi
}

# Function to install Drupal if not already installed
install_drupal() {
    if [ ! -f /var/www/html/sites/default/settings.php ]; then
        echo "Drupal not installed. Please configure settings.php first."
        return 1
    fi
    
    # Check if Drupal is already installed by looking for users table
    if [ ! -f /var/www/html/core/scripts/drupal ]; then
        echo "Drupal core scripts not found. Skipping automatic installation."
        echo "Please install Drupal manually via web interface at /install.php"
        echo "Or check if Drupal core is properly installed in /var/www/html/core/"
        return 1
    fi
    
    # Check if Drupal is already installed by looking for users table
    echo "Checking if Drupal is already installed..."
    if ! php /var/www/html/core/scripts/drupal database:status 2>/dev/null | grep -q "Connected"; then
        echo "Drupal not installed. Please install manually via web interface at /install.php"
        echo "Database connection available. You can proceed with manual installation."
        return 0
    else
        echo "Drupal already installed."
    fi
}

# Main execution
echo "Starting FarmOS container..."

# Debug: Show current directory structure
echo "=== Debug: Current directory structure ==="
echo "Contents of /var/www/html:"
ls -la /var/www/html/ || echo "Cannot list directory"
echo "Contents of /var/www/html/sites/default:"
ls -la /var/www/html/sites/default/ || echo "Cannot list sites/default directory"
echo "=== End Debug ==="

# Wait for database
wait_for_db

# Create Drupal settings if core exists
if [ -d /var/www/html/core ]; then
    echo "Drupal core directory found"
    create_drupal_settings
    install_drupal
    chown -R www-data:www-data /var/www/html/sites/default/files
else
    echo "Drupal core directory not found, but continuing..."
    echo "Contents of /var/www/html:"
    ls -la /var/www/html/ || echo "Cannot list directory"
fi

echo "FarmOS container ready!"

# Start Apache in the foreground
echo "Starting Apache..."
exec apache2-foreground
