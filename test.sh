#!/bin/bash
source ~/nvm/nvm.sh
nvm install $NODE_VERSION
nvm use $NODE_VERSION
rm -rf node_modules
npm install
npm test
