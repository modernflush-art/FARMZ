<?php
echo "PHP is working!";
echo "<br>PHP Version: " . phpversion();
echo "<br>Current directory: " . getcwd();
echo "<br>Files in current directory:";
$files = scandir('.');
foreach($files as $file) {
    if ($file != '.' && $file != '..') {
        echo "<br>- " . $file;
    }
}
?>
