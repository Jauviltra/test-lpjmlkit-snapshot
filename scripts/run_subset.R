#!/usr/bin/env Rscript
# run_subset.R
# Simple runner to create lpjmlkit config(s) for a subset of global grid indices
# and run LPJmL. Supports an indices file (one integer per line) or a CSV of indices.
# Usage examples:
#  Rscript run_subset.R --indices-file data/global_indexes.csv --model-path /home/jvt/LPJmL --sim-path /home/jvt/test-lpjmlkit/spain_sim --inpath /home/jvt/test-lpjmlkit/lpjm_inputs_spain --dry-run
#
args <- commandArgs(trailingOnly = TRUE)
parse_args <- function(args) {
  a <- list()
  i <- 1
  while (i <= length(args)) {
    if (args[i] %in% c("--indices-file","-f")) { a$indices_file <- args[i+1]; i <- i+2 }
    else if (args[i] %in% c("--indices","-i")) { a$indices <- args[i+1]; i <- i+2 }
    else if (args[i] == "--model-path") { a$model_path <- args[i+1]; i <- i+2 }
    else if (args[i] == "--sim-path") { a$sim_path <- args[i+1]; i <- i+2 }
    else if (args[i] == "--inpath") { a$inpath <- args[i+1]; i <- i+2 }
    else if (args[i] == "--run-cmd") { a$run_cmd <- args[i+1]; i <- i+2 }
    else if (args[i] == "--dry-run") { a$dry_run <- TRUE; i <- i+1 }
    else if (args[i] == "--help") { a$help <- TRUE; i <- i+1 }
    else { cat(sprintf("Unknown arg: %s\n", args[i])); i <- i+1 }
  }
  a
}
a <- parse_args(args)
if (!is.null(a$help) || (is.null(a$indices_file) && is.null(a$indices))) {
  cat("run_subset.R - usage:\n")
  cat("  --indices-file <file>   : text file, one integer index per line\n")
  cat("  --indices <csv>         : comma-separated indices (e.g. 32180,32181)\n")
  cat("  --model-path <dir>      : path to LPJmL installation (required)\n")
  cat("  --sim-path <dir>        : path to simulation directory (required)\n")
  cat("  --inpath <dir>          : path to input files (optional)\n")
  cat("  --run-cmd <cmd>         : command prefix to run (default 'mpirun -np 1 -- ')\n")
  cat("  --dry-run               : only write configs, don't execute LPJmL\n")
  quit(status=1)
}
# defaults and checks
model_path <- if (!is.null(a$model_path)) a$model_path else stop("--model-path required")
sim_path   <- if (!is.null(a$sim_path)) a$sim_path else stop("--sim-path required")
inpath     <- if (!is.null(a$inpath)) a$inpath else NULL
run_cmd    <- if (!is.null(a$run_cmd)) a$run_cmd else "mpirun -np 1 -- "
dry_run    <- !is.null(a$dry_run) && a$dry_run
# read indices
read_indices_file <- function(path) {
  x <- scan(path, what = integer(), sep = "\n", quiet = TRUE)
  as.integer(x)
}
if (!is.null(a$indices_file)) {
  indices <- read_indices_file(a$indices_file)
} else if (!is.null(a$indices)) {
  indices <- as.integer(strsplit(a$indices, ",")[[1]])
} else stop("No indices provided")
if (length(indices) == 0) stop("No indices found in input")
indices <- sort(unique(indices))
cat(sprintf("Loaded %d indices, min=%d max=%d\n", length(indices), min(indices), max(indices)))
# compute contiguous ranges
contiguous_ranges <- function(v) {
  if (length(v) == 0) return(list())
  r <- list()
  start <- v[1]; prev <- v[1]
  for (x in v[-1]) {
    if (x == prev + 1) { prev <- x } else { r[[length(r)+1]] <- c(start, prev); start <- x; prev <- x }
  }
  r[[length(r)+1]] <- c(start, prev)
  r
}
ranges <- contiguous_ranges(indices)
cat(sprintf("Computed %d contiguous range(s):\n", length(ranges)))
for (rg in ranges) cat(sprintf("  %d .. %d (n=%d)\n", rg[1], rg[2], rg[2]-rg[1]+1))
# require packages lazily
ensure_pkg <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop(sprintf("Required package '%s' is not installed. Install it in R before running this script.", pkg))
  }
}
ensure_pkg("lpjmlkit")
ensure_pkg("tibble")
library(lpjmlkit)
library(tibble)
# iterate ranges and create/run configs
for (i in seq_along(ranges)) {
  rg <- ranges[[i]]
  startgrid <- as.integer(rg[1])
  endgrid   <- as.integer(rg[2])
  sim_name <- paste0("subset_", startgrid, "_", endgrid)
  params <- tibble(
    sim_name = sim_name,
    inpath = if (!is.null(inpath)) inpath else "",
    `-DFROM_RESTART` = FALSE,
    startgrid = startgrid,
    endgrid = endgrid,
    river_routing = FALSE,
    nspinup = 0,
    firstyear = 1901,
    lastyear = 1901
  )
  cat(sprintf("Writing config for %s (start=%d end=%d)\n", sim_name, startgrid, endgrid))
  cfg <- lpjmlkit::write_config(x = params, model_path = model_path, sim_path = sim_path, debug = TRUE)
  if (dry_run) {
    cat(sprintf("Dry run: would execute LPJmL for %s with run_cmd='%s'\n", sim_name, run_cmd))
  } else {
    cat(sprintf("Running LPJmL for %s ...\n", sim_name))
    lpjmlkit::run_lpjml(cfg, model_path, sim_path, run_cmd = run_cmd)
    cat(sprintf("Finished run %s\n", sim_name))
  }
}
cat("All done.\n")
