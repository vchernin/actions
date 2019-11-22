#!/bin/bash

if [[ -z "$GITHUB_WORKSPACE" || -z "$GITHUB_REPOSITORY" ]]; then
    echo "Script is not running in GitHub Actions CI"
    exit 1
fi

detect_manifest() {
    repo=${1}

    if [[ -f $repo/${repo}.yml ]]; then
        manifest=${repo}.yml
    elif [[ -f $repo/${repo}.yaml ]]; then
        manifest=${repo}.yaml
    elif [[ -f $repo/${repo}.json ]]; then
        manifest=${repo}.json
    else
        return 1
    fi

    echo $manifest
}

git config --global user.name "flathubbot" && \
git config --global user.email "sysadmin@flathub.org"

mkdir flathub
cd flathub

gh-ls-org flathub | parallel "git clone --depth 1 {}"
mapfile -t checker_apps < <( grep -rl x-checker-data | cut -d/ -f1 | sort -u )

for repo in ${checker_apps[@]}; do
    manifest=$(detect_manifest $repo)
    if [[ -n $manifest ]]; then
        echo "==> checking ${repo}"
        /opt/flatpak-external-data-checker/flatpak-external-data-checker --verbose $repo/$manifest
    fi
done
