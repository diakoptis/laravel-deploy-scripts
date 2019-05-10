#!/bin/bash

# DEPLOY LARAVEL APP AND DO FULL INSTALL
# This deploy has almost zero downtime.
# Instead of updating the currently-running version,
# it checks out a new clone of the passed in branch and builds it in a timestamped folder, then
# recreates a symlink at the very end.

# This script assumes you have put your production .env file in your WORKING_DIR folder and your master branch has been commited with all npm assets compiled (npm run production).
# We have the file at /usr/local/bin/deploy and executable.
# Also you’ll need to use a deploy key for ssh access to your repo.
#> deploy git_reponame time_string

if (( $# < 2 )); then
        echo "Deploy Script requires an app name and a time string. The app name should match your git repository name."
        exit 1
fi

#UPDATE THIS
WORKING_DIR=/var/www/html

APP=$1 TIME=$2 FOLDER=${APP}-${TIME} APP_DIR=${WORKING_DIR}/${FOLDER}

echo -e "\n\n====> Creating .env file\n"

cd ${WORKING_DIR}
touch ${APP_DIR}/.env
cp .env ${APP_DIR}/.env

cd ${APP_DIR}
echo -e "\n\n====> Installing composer dependencies...\n\n"
composer install --no-interaction --no-dev --prefer-dist

echo -e "\n\n====> Modifying permissions...\n\n"
sudo touch $APP_DIR/storage/logs/laravel.log
sudo touch $APP_DIR/storage/logs/laravel.json
sudo mkdir -p $APP_DIR/storage/framework/cache/data
sudo chown -R wwworkshop-staging:www-data $APP_DIR
sudo chmod -R 2777 $APP_DIR/storage

echo -e "\n\n====> Caching Configs...\n\n"
/usr/bin/php $APP_DIR/artisan cache:clear
/usr/bin/php $APP_DIR/artisan config:cache

echo -e "\n\n====> Restarting php-fpm...\n"
sudo service php7.1-fpm restart

which nginx > /dev/null 2>&1
if [ $? == 0 ]; then
        echo -e "\n====> Restarting nginx...\n"
        sudo service nginx restart
fi

which supervisord > /dev/null 2>&1
if [ $? == 0 ]; then
        echo -e "\n====> Restarting supervisord...\n"
        sudo service supervisor restart
fi

echo -e "\n====> Updating Symlink...\n"
sudo rm -rf ${WORKING_DIR}/${APP} && ln -s $APP_DIR ${WORKING_DIR}/${APP}

echo -e "\n\n====> Site Deployed Successfully.\n\n"
