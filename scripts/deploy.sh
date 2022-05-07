#! /bin/bash

rm -rf /tmp/dist;
cp -r dist /tmp/dist;
cd /tmp/dist;
echo "<!--" >> index.html;
find . -type f -print0 | sort -z | xargs -P $(nproc --all) -0 sha1sum | tqdm --unit file --total $(find . -type f | wc -l) | sort | awk '{ print $1 }' | sha1sum | head -c 40 |  xargs -I {} echo "Content hash: " {} >> index.html;
echo "-->" >> index.html;
git init;
git add -A;
git commit -m "Deploy";
git remote add origin git@github.com:Nek/faust-sandbox-deploy.git;
git push origin master --force;