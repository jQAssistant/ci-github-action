#!/usr/bin/env bash

url_prefix="git@github.com:jQAssistant/"
url_suffix=".git"
temp_work_dir=`mktemp -d /tmp/XXXXXXXX`

# See https://stackoverflow.com/questions/59895/
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
templ_dir="${script_dir}/../templates"

source ${script_dir}/colors.sh
source ${script_dir}/repositories.sh

#---
#--- Handling of the name and email for commits
#---

NAME=$(git config --get core.name)
NAME_SOURCE=$(git config --get --show-origin core.name | cut -f 1)
EMAIL=$(git config --get user.email)
EMAIL_SOURCE=$(git config --get --show-origin  user.email | cut -f 1)

echo -$NAME-
echo $EMAIL

if [[ -z "${NAME}" ]] || [[ -z "${EMAIL}" ]]; then
    echo "${RED}Unable to find the name of the use to be used for commits"
    echo "taken from 'core.name'${RESET}"
    exit 1
fi

if [[ -z "${EMAIL}" ]]; then
    echo "${RED}Unable to find the email of the use to be used for commits"
    echo "taken from 'user.email'${RESET}"
    exit 1
fi

echo "${RED}I will use the following values for the upcoming commits"
echo
echo -e "\tCommitter name: ${NAME}  (source ${NAME_SOURCE}"
echo -e "\tCommitter email: ${EMAIL} (source ${EMAIL_SOURCE})"
echo
echo "${GREEN}Hit enter to go on with these values or press ctrl+c to abort...${RESET}"

read -t 20 -n 1

echo "This script will install all workflows from the template directory "
echo "in the following repositories:"
echo
for repo in ${repositories[*]}
do
    echo -e "\t- ${repo}"
done
echo
echo "Please check if this list is up-to-date and update the list if needed"
echo ${GREEN}
echo "Hit enter to continue..."
read -s -n 1 key # -s => silent, -n 1 one character
echo "${RESET}"

for repo in ${repositories[*]}
do
    echo "${GREEN}###"
    echo "### Checking out ${repo}"
    echo "### URL: ${url_prefix}${repo}${url_suffix}"
    echo "### Target dir: ${temp_work_dir}/${repo}"
    echo "###${RESET}"
    git clone "${url_prefix}${repo}${url_suffix}" "${temp_work_dir}/${repo}"

    # Create the workflow directory if it does not exists
    test -d "${temp_work_dir}/${repo}/.github/workflows" || \
        mkdir -p -v "${temp_work_dir}/${repo}/.github/workflows"

    echo "${GREEN}###"
    echo "### Copying workflows"
    echo "### Project specific changes will be overridden!!!"
    echo "###${RESET}"
    cp -v ${templ_dir}/*.yaml "${temp_work_dir}/${repo}/.github/workflows"

    pushd "${temp_work_dir}/${repo}/.github/workflows"

    if [[ $(git diff --exit-code --quiet 2>/dev/null >&2)$? == 1 ]];
    then
        git add -A -v . || exit 1
        git commit -a -m "Update of our Github Action workflows" || exit 1
        git push || exit 1
    else
        echo "No changes to commit and to push"
    fi

    popd


done

