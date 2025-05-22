model_path <- "/home/usuario/LPJmL"
sim_path <- "/home/usuario/LPJmL/simulation"

startgrid <- 27410
endgrid <- 27433
use_cores <- 24
simulation_start_year <- 1901
simulation_end_year <- 1902

spinup_params <- tibble::tibble(
  sim_name = "spinup",
  `startgrid` = startgrid,
  `endgrid` = endgrid,
  `river_routing` = FALSE,
  `nspinup` = 2,
  `firstyear` = simulation_start_year,
  `lastyear` = simulation_start_year,
)

spinup_config_details <- lpjmlkit::write_config(
  x = spinup_params,
  model_path = model_path,
  sim_path = sim_path
)

simulation_params <- tibble::tibble(
  sim_name = "scenario_1",
  `-DFROM_RESTART` = TRUE,
  `restart_filename` = "restart/spinup/restart.lpj",
  `startgrid` = startgrid,
  `endgrid` = endgrid,
  `river_routing` = FALSE,
  `nspinup` = 0,
  `firstyear` = simulation_start_year,
  `lastyear` = simulation_end_year,
)

simulation_config_details <- lpjmlkit::write_config(
  x = simulation_params,
  model_path = model_path,
  sim_path = sim_path
)

spinup_run_details <- lpjmlkit::run_lpjml(
  spinup_config_details,
  model_path,
  sim_path,
  run_cmd = stringr::str_glue("mpirun -np {use_cores} ")
)

simulation_run_details <- lpjmlkit::run_lpjml(
  simulation_config_details,
  model_path,
  sim_path,
  run_cmd = stringr::str_glue("mpirun -np {use_cores} ")
)
