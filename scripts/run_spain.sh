#!/usr/bin/env bash
# run_spain.sh - helper to install minimal deps on Ubuntu WSL and run the Spain subset
set -euo pipefail
# Install minimal tools (run as user with sudo)
if ! command -v jq >/dev/null 2>&1; then
  echo "Installing jq..."
  sudo apt-get update && sudo apt-get install -y jq
fi
if ! command -v mpirun >/dev/null 2>&1; then
  echo "Installing OpenMPI..."
  sudo apt-get install -y openmpi-bin
fi
# Run the R script to execute the subset. Adjust paths if needed.
Rscript /home/jvt/test-lpjmlkit/scripts/run_subset.R --indices-file /home/jvt/test-lpjmlkit/data/global_indexes.csv --model-path /home/jvt/LPJmL --sim-path /home/jvt/test-lpjmlkit/spain_sim --inpath /home/jvt/test-lpjmlkit/lpjm_inputs_spain
