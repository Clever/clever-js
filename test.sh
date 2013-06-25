#!/bin/bash
source ~/nvm/nvm.sh
nvm install 0.8.23
nvm use 0.8.23
npm install
npm test
