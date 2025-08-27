<?php
/**
 * @file
 * Simple health check and redirect for FarmOS container.
 */

// Check if Drupal is installed
if (file_exists(__DIR__ . '/core/includes/bootstrap.inc')) {
    // Drupal is available, redirect to it
    header('Location: /core/install.php');
    exit;
} else {
    // Drupal not available, show status
    echo '<!DOCTYPE html>
<html>
<head>
    <title>FarmOS Container Status</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .status { padding: 20px; border: 1px solid #ccc; border-radius: 5px; }
        .error { background-color: #ffebee; border-color: #f44336; }
        .success { background-color: #e8f5e8; border-color: #4caf50; }
    </style>
</head>
<body>
    <h1>FarmOS Container Status</h1>
    <div class="status error">
        <h2>Drupal Core Not Found</h2>
        <p>The Drupal core files are not available. This could be due to:</p>
        <ul>
            <li>Composer install not completing properly</li>
            <li>Drupal scaffold not running</li>
            <li>File permissions issues</li>
        </ul>
        <p>Check the container logs for more details.</p>
    </div>
    <div class="status">
        <h3>Container Information</h3>
        <p><strong>PHP Version:</strong> ' . PHP_VERSION . '</p>
        <p><strong>Document Root:</strong> ' . __DIR__ . '</p>
        <p><strong>Current Directory:</strong> ' . getcwd() . '</p>
    </div>
</body>
</html>';
}
?>
