#!/bin/sh

echo "deploying..."
gen=`hugo` 
dep=`cd ../apublic && git add -A && git commit -m "add a article" && git push` 
echo "deployed!"
echo "backuping..."
bac=`git add -A && git commit -m "back up" && git push`
echo "backuped!"