#!/bin/zsh

cp ../simulate-cicd/app/app2.py app/app.py
echo "# $(date +%s)" >> app/app.py
git commit app/app.py -m "Broken version committed  $(date +%s)"
git push

