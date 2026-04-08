#!/bin/env bash

git add .
git commit -m "automated commit"
git branch -M main
git remote add origin git@github.com:Stars-Hiker/PostInstall.git
git push -u origin main
