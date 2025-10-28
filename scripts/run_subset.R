#!/usr/bin/env Rscript
# run_subset.R
# Refactored runner to create lpjmlkit config(s) for a subset of global grid indices
# Main changes:
# - Encapsulate logic in a reusable function `run_subset()`
# - Don't assume incoming indices are ordered; sort/unique internally
# - Use a concise contiguous-range implementation using cumsum/split
# - Add `--run-all` flag to create a single run covering min..max

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
    else if (args[i] == "--gridfile") { a$gridfile <- args[i+1]; i <- i+2 }
    else if (args[i] == "--run-cmd") { a$run_cmd <- args[i+1]; i <- i+2 }
    else if (args[i] == "--dry-run") { a$dry_run <- TRUE; i <- i+1 }
    else if (args[i] == "--run-all") { a$run_all <- TRUE; i <- i+1 }
    else if (args[i] == "--help") { a$help <- TRUE; i <- i+1 }
    else { cat(sprintf("Unknown arg: %s\n", args[i])); i <- i+1 }
  }
  a
}

a <- parse_args(args)
# allow --gridfile as an alternative to --indices/--indices-file
if (!is.null(a$help) || (is.null(a$indices_file) && is.null(a$indices) && is.null(a$gridfile))) {
  cat("run_subset.R - usage:\n")
  cat("  --indices-file <file>   : text file, one integer index per line\n")
  cat("  --indices <csv>         : comma-separated indices (e.g. 32180,32181)\n")
  cat("  --model-path <dir>      : path to LPJmL installation (required)\n")
  cat("  --sim-path <dir>        : path to simulation directory (required)\n")
  cat("  --inpath <dir>          : path to input files (optional)\n")
  cat("  --gridfile <path>       : path to a CLM header (.hdr) to run an exact subset (overrides indices/ranges)\n")
  cat("  --run-cmd <cmd>         : command prefix to run (default 'mpirun -np 1 -- ')\n")
  cat("  --dry-run               : only write configs, don't execute LPJmL\n")
  cat("  --run-all               : create a single run covering min..max indices\n")
  quit(status=1)
}

# defaults and checks
model_path <- if (!is.null(a$model_path)) a$model_path else stop("--model-path required")
sim_path   <- if (!is.null(a$sim_path)) a$sim_path else stop("--sim-path required")
inpath     <- if (!is.null(a$inpath)) a$inpath else NULL
gridfile   <- if (!is.null(a$gridfile)) a$gridfile else NULL
run_cmd    <- if (!is.null(a$run_cmd)) a$run_cmd else "mpirun -np 1 -- "
dry_run    <- !is.null(a$dry_run) && a$dry_run
run_all    <- !is.null(a$run_all) && a$run_all

# read indices
read_indices_file <- function(path) {
  x <- scan(path, what = integer(), sep = "\n", quiet = TRUE)
  as.integer(x)
}

if (!is.null(a$gridfile)) {
  # gridfile provided -> we don't need indices here (run_subset will handle gridfile)
  indices <- integer(0)
} else if (!is.null(a$indices_file)) {
  indices <- read_indices_file(a$indices_file)
} else if (!is.null(a$indices)) {
  indices <- as.integer(strsplit(a$indices, ",")[[1]])
} else stop("No indices provided")

if (length(indices) == 0 && is.null(gridfile)) stop("No indices found in input")

#' Compute contiguous ranges from a vector of integers
#' Returns a list of integer vectors length-2 (start, end)
contiguous_ranges <- function(v) {
  if (length(v) == 0) return(list())
  v <- sort(unique(as.integer(v)))
  # groups where diff != 1
  groups <- cumsum(c(1L, as.integer(diff(v) != 1)))
  splitted <- split(v, groups)
  lapply(splitted, function(x) as.integer(range(x)))
}

#' Main worker: create configs and (optionally) run LPJmL for given indices
run_subset <- function(indices, model_path, sim_path, inpath = NULL, gridfile = NULL, run_cmd = "mpirun -np 1 -- ", dry_run = FALSE, run_all = FALSE) {
  # If a gridfile/header is provided, run a single config that points to it.
  if (!is.null(gridfile)) {
    if (!file.exists(gridfile)) stop(sprintf("Provided gridfile does not exist: %s", gridfile))
    sim_name <- paste0("subset_from_header_", tools::file_path_sans_ext(basename(gridfile)))
    cat(sprintf("Using gridfile '%s' -> creating single run %s\n", gridfile, sim_name))
    ensure_pkg <- function(pkg) {
      if (!requireNamespace(pkg, quietly = TRUE)) {
        stop(sprintf("Required package '%s' is not installed. Install it in R before running this script.", pkg))
      }
    }
    ensure_pkg("lpjmlkit")
    ensure_pkg("tibble")
    library(lpjmlkit)
    library(tibble)

    params <- tibble(
      sim_name = sim_name,
      inpath = if (!is.null(inpath)) inpath else "",
      `-DFROM_RESTART` = FALSE,
      gridfile = gridfile,
      river_routing = FALSE,
      nspinup = 0,
      firstyear = 1901,
      lastyear = 1901
    )
    cat(sprintf("Writing config for %s (gridfile=%s)\n", sim_name, gridfile))
    cfg <- lpjmlkit::write_config(x = params, model_path = model_path, sim_path = sim_path, debug = TRUE)
    if (dry_run) {
      cat(sprintf("Dry run: would execute LPJmL for %s with run_cmd='%s'\n", sim_name, run_cmd))
    } else {
      cat(sprintf("Running LPJmL for %s ...\n", sim_name))
      lpjmlkit::run_lpjml(cfg, model_path, sim_path, run_cmd = run_cmd)
      cat(sprintf("Finished run %s\n", sim_name))
    }
    cat("All done.\n")
    return(invisible(TRUE))
  }

  if (length(indices) == 0) stop('No indices provided to run_subset')
  indices <- sort(unique(as.integer(indices)))
  if (run_all) {
    indices <- seq(min(indices), max(indices))
  }
  cat(sprintf("Loaded %d indices, min=%d max=%d\n", length(indices), min(indices), max(indices)))

  ranges <- contiguous_ranges(indices)
  cat(sprintf("Computed %d contiguous range(s):\n", length(ranges)))
  for (rg in ranges) cat(sprintf("  %d .. %d (n=%d)\n", rg[1], rg[2], rg[2]-rg[1]+1))
  ensure_pkg <- function(pkg) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      stop(sprintf("Required package '%s' is not installed. Install it in R before running this script.", pkg))
    }
  }
  ensure_pkg("lpjmlkit")
  ensure_pkg("tibble")
  library(lpjmlkit)
  library(tibble)

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
  invisible(TRUE)
}

# Call the worker with parsed command-line args
run_subset(indices = indices, model_path = model_path, sim_path = sim_path, inpath = inpath, gridfile = gridfile, run_cmd = run_cmd, dry_run = dry_run, run_all = run_all)
