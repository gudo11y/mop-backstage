#!/bin/bash

# set -o errexit

echo "Setting up Tilt for $1"

ctlptl create registry ctlptl-registry --port=5005
ctlptl create cluster minikube --registry=ctlptl-registry


(cd tanka && jb install)

(cd "tanka/environments/$1" && tk tool charts vendor)

mkdir -p .tilt && touch ".tilt/$1.yaml"
