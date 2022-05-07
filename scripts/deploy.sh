#! /bin/bash

if [ -n "$(git status --porcelain)" ]; then
    echo "Working directory contains uncommitted changes."
    exit 1
else
    rm -rf /tmp/dist;
    cp -r dist /tmp/dist;
    cd /tmp/dist;
    git init;
    git add -A;
    git commit -m "Deploy";
    git remote add origin git@github.com:Nek/faust-sandbox-deploy.git;
    git push origin master --force;
fi