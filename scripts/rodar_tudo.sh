#!/usr/bin/env bash
set -eu
D=$(dirname "$0")

bash "$D/ambiente.sh"
bash "$D/parte2.sh"
bash "$D/parte3.sh"
bash "$D/parte4.sh"
bash "$D/parte5.sh"
