#!/bin/zsh

cp ../simulate-cicd/app/app1.py app/app.py
echo "# $(date +%s)" >> app/app.py
git commit app/app.py -m "Working version committed $(date +%s)"
git push

