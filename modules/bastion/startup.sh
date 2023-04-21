#! /bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get install -y zip unzip jq redis-tools mysql-client
