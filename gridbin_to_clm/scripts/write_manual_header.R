#!/usr/bin/env Rscript
# write_manual_header.R
# Writes LPJmL binary header matching lpjmlkit::write_header() behaviour
# Usage: Rscript write_manual_header.R --cells <cells.txt> --grid-json <grid.bin.json> --out <out.hdr>

args <- commandArgs(trailingOnly = TRUE)
opts <- list()
for (i in seq(1, length(args), by = 2)) {
  k <- args[i]; v <- args[i+1]
  if (k == "--cells") opts$cells <- v
  else if (k == "--grid-json") opts$grid_json <- v
  else if (k == "--out") opts$out <- v
}
if (is.null(opts$cells) || is.null(opts$grid_json) || is.null(opts$out)) {
  stop("Usage: Rscript write_manual_header.R --cells <cells.txt> --grid-json <grid.bin.json> --out <out.hdr>")
}
if (!file.exists(opts$cells)) stop("cells file not found: ", opts$cells)
if (!file.exists(opts$grid_json)) stop("grid json not found: ", opts$grid_json)

library(jsonlite)
`%||%` <- function(a,b) if(!is.null(a)) a else b

cells <- tryCatch(as.integer(read.table(opts$cells, header = FALSE)[,1]), error = function(e) stop("Failed to read cells: ", e$message))
meta <- fromJSON(opts$grid_json)
scalar <- as.numeric(meta$scalar %||% meta$scale %||% 0.01)
cellsize <- as.numeric(meta$cellsize %||% 0.5)
cellsize_lon <- as.numeric(meta$cellsize_lon %||% cellsize)
cellsize_lat <- as.numeric(meta$cellsize_lat %||% cellsize)

ncell_sel <- length(cells)
firstcell_sel <- as.integer(min(cells))

# Decide version and other defaults
version <- 4L
order <- 0L
firstyear <- 0L
nyear <- 0L
nbands <- 1L
datatype <- 1L   # default datatype code (1: short/int16 typical)
nstep <- 1L
timestep <- 1L

# Build header list like lpjmlkit expects
hdr_name <- tools::file_path_sans_ext(basename(opts$out))
endian <- tolower(.Platform$endian)

# Build numeric named vector header$header
hdr_vec <- numeric()
hdr_vec["version"] <- as.integer(version)
hdr_vec["order"] <- as.integer(order)
hdr_vec["firstyear"] <- as.integer(firstyear)
hdr_vec["nyear"] <- as.integer(nyear)
hdr_vec["firstcell"] <- as.integer(firstcell_sel)
hdr_vec["ncell"] <- as.integer(ncell_sel)
hdr_vec["nbands"] <- as.integer(nbands)
# version > 1
hdr_vec["cellsize_lon"] <- as.numeric(cellsize_lon)
hdr_vec["scalar"] <- as.numeric(scalar)
# version > 2
hdr_vec["cellsize_lat"] <- as.numeric(cellsize_lat)
hdr_vec["datatype"] <- as.integer(datatype)
# version > 3
hdr_vec["nstep"] <- as.integer(nstep)
hdr_vec["timestep"] <- as.integer(timestep)

# Now write binary header file following lpjmlkit::write_header()
fp <- file(opts$out, "wb")
# write name as raw bytes (no length prefix)
writeBin(charToRaw(hdr_name), fp)
# base_header_items order
base_header_items <- c("version", "order", "firstyear", "nyear", "firstcell", "ncell", "nbands")
writeBin(as.integer(hdr_vec[base_header_items]), fp, size = 4, endian = endian)
# version > 1: write cellsize_lon and scalar as floats (size=4)
if (hdr_vec["version"] > 1) {
  writeBin(as.double(hdr_vec[c("cellsize_lon", "scalar")]), fp, size = 4, endian = endian)
}
# version > 2: write cellsize_lat (double size=4) and datatype (int)
if (hdr_vec["version"] > 2) {
  writeBin(as.double(hdr_vec["cellsize_lat"]), fp, size = 4, endian = endian)
  writeBin(as.integer(hdr_vec["datatype"]), fp, size = 4, endian = endian)
}
# version > 3: write nstep and timestep as ints
if (hdr_vec["version"] > 3) {
  writeBin(as.integer(hdr_vec[c("nstep", "timestep")]), fp, size = 4, endian = endian)
}
close(fp)
message("Wrote manual binary header: ", opts$out)
message("Header name: ", hdr_name)
message("ncell: ", ncell_sel, ", firstcell: ", firstcell_sel, ", scalar: ", scalar, ", cellsize: ", cellsize)
