#!/bin/bash
kind create cluster --name inframind --config kind/cluster.yaml
kubectl apply -f namespaces/
