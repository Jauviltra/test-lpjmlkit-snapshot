#!/usr/bin/env Rscript
pkgs <- c('readr','ggplot2','maps')
missing <- pkgs[!(pkgs %in% rownames(installed.packages()))]
if(length(missing)) install.packages(missing, repos='https://cloud.r-project.org')
library(readr); library(ggplot2); library(maps)

infile <- 'cells_coords.csv'
if(!file.exists(infile)) stop('Create cells_coords.csv with columns id,lon,lat in repo root')

df <- read_csv(infile, show_col_types = FALSE)
names(df) <- tolower(names(df))
if(!all(c('lon','lat') %in% names(df))) stop('cells_coords.csv must contain lon and lat')

sp <- maps::map('world', region='spain', fill=TRUE, plot=FALSE)
spdf <- fortify(sp)

dir.create('figures', showWarnings = FALSE)
p <- ggplot() +
  geom_polygon(data = spdf, aes(x=long, y=lat, group=group), fill='#f0f0f0', colour='#666') +
  geom_point(data = df, aes(x = lon, y = lat), color = 'red', size = 1.2) +
  coord_quickmap() + theme_minimal() + labs(title = 'Selected grid cells (approx.)')
ggsave('figures/cells_map_spain_nosf.png', p, width = 7, height = 8, dpi = 150)
