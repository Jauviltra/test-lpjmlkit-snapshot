grid <- terra::rast("~/LPJmL/simulation/output/scenario_1/mpet.nc")

grid |>
  as.data.frame(xy = TRUE, na.rm = TRUE) |>
  tibble::as_tibble()
