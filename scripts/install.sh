#!/bin/bash

# Get the directory of the currently executing script
DIR="$(dirname "${BASH_SOURCE[0]}")"

# Include files
INCLUDE_FILES=(
    ".env.sh"
)
for INCLUDE_FILE in "${INCLUDE_FILES[@]}"
do
    if [[ ! -f "${DIR}/${INCLUDE_FILE}" ]] ; then
        echo "File ${DIR}/${INCLUDE_FILE} is missing, aborting."
        exit 1/var/www/html/.env
    fi
    source "${DIR}/${INCLUDE_FILE}"
done

if [ $# -eq 0 ]
then
	sudo cp ./git-deploy.sh /usr/local/bin/git-deploy
	sudo cp ./manual-deploy.sh /usr/local/bin/manual-deploy
	sudo cp ./revert.sh /usr/local/bin/revert
	sudo cp ./git-post-receive.sh /usr/local/bin/git-post-receive
	sudo cp ./.env.sh /usr/local/bin/.env.sh

	sudo chmod +x /usr/local/bin/.env.sh /usr/local/bin/revert /usr/local/bin/git-post-receive /usr/local/bin/manual-deploy /usr/local/bin/git-deploy

	cd ~
	mkdir ${APP}.git
	cd ${APP}.git
	git init --bare

	echo "git-post-receive" >> ~/${APP}.git/hooks/post-receive
	sudo chmod +x ~/${APP}.git/hooks/post-receive

	echo ${SERVER_USER}	'ALL=NOPASSWD: /usr/local/bin/git-deploy *' | sudo EDITOR='tee -a' visudo
else
	REMOTE=$1
	git remote add ${REMOTE} ssh://${GIT_USERNAME}@${HOST_NAME}/home/${SERVER_USER}/${APP}.git
fi
