#!/bin/bash

set -x 

kubectl label node prometheus-node role=prometheus
kubectl label node solar-node role=solar


kubectl create namespace monitoring
kubectl create namespace solar-app

kubectl apply -f prometheus-clusterrole.yml
kubectl apply -f solar-app-secret.yml
kubectl apply -f prometheus-clusterrolebinding.yml
kubectl apply -f node-exporter-daemonset.yml
kubectl apply -f k8s-manifest.yml
kubectl apply -f prometheus-deployment.yml
