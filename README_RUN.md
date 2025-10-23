Reproducible run instructions (WSL / Ubuntu)

Prerequisites (install once):
- Ubuntu on WSL or Linux with:
  - R (>= 4.0)
  - libopenmpi / openmpi-bin (for mpirun)
  - jq (optional, used in examples)
- R packages required:
  - lpjmlkit
  - tibble

Quick steps to reproduce the Spain subset run:

1. Ensure LPJmL is installed at /home/jvt/LPJmL (adjust --model-path accordingly).
2. Ensure inputs are in /home/jvt/test-lpjmlkit/lpjm_inputs_spain and data/global_indexes.csv contains one index per line for the subset.
3. Run the helper script (installs minimal packages and runs):

   bash /home/jvt/test-lpjmlkit/scripts/run_spain.sh

4. Alternatively run manually with R:

   Rscript /home/jvt/test-lpjmlkit/scripts/run_subset.R --indices-file /home/jvt/test-lpjmlkit/data/global_indexes.csv --model-path /home/jvt/LPJmL --sim-path /home/jvt/test-lpjmlkit/spain_sim --inpath /home/jvt/test-lpjmlkit/lpjm_inputs_spain

Notes:
- run_subset.R computes contiguous index ranges and creates one LPJmL config/run per contiguous block. For Spain it's a single contiguous block (32180..32529).
- If lpjmlkit cannot read the binary header with read_header(), it's safe to force startgrid/endgrid in the JSON as a workaround (what we used).
- To make this reproducible, consider committing data/global_indexes.csv and spain_sim/configurations/config_spain_test.json to the repo (or archive them externally).
