#!/bin/bash

#
# Reload Supervisor
# --------------------------------------
# Try auto install for composer
if [ $(which composer > /dev/null 2>&1; echo $? ) -eq 0  ] && [ -f "$WEBROOT/composer.lock" ]; then
  CWDir=$(pwd)
  cd "$WEBROOT"
  composer install # Use composer not composer.phar!!!!
  cd "${CWDir}"
fi

supervisorctl restart nginx php-fpm7

echo "Done"
