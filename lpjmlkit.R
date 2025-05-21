model_path <- "/home/usuario/LPJmL"
sim_path <- "/home/usuario/LPJmL/simulation"

startgrid <- 27410
endgrid <- 27433

spinup_params <- tibble::tibble(
  sim_name = "spinup",
  # `pftpar[[1]]$name` = "first_tree",
  `-DWITHOUT_NITROGEN` = TRUE,
  # `-DFROM_RESTART` = TRUE,
  # `restart_filename` = "restart/scen1/restart.lpj",
  # `startgrid` = startgrid,
  # `endgrid` = endgrid,
  `river_routing` = FALSE,
  `nspinup` = 5,
  `firstyear` = NA,
  `lastyear` = NA,
)

spinup_config_details <- lpjmlkit::write_config(
  x = spinup_params,
  model_path = model_path,
  sim_path = sim_path
)

simulation_params <- tibble::tibble(
  sim_name = "scenario_1",
  # random_seed = 12,
  # `pftpar[[1]]$name` = "first_tree",
  `-DWITHOUT_NITROGEN` = TRUE,
  `-DFROM_RESTART` = TRUE,
  `restart_filename` = "restart/spinup/restart.lpj",
  # `startgrid` = startgrid,
  # `endgrid` = endgrid,
  `river_routing` = FALSE,
  `nspinup` = 0,
  `firstyear` = 1901,
  `lastyear` = 1910,
  # gsi_phenology = TRUE
)

simulation_config_details <- lpjmlkit::write_config(
  x = simulation_params,
  model_path = model_path,
  sim_path = sim_path,
  debug = TRUE
)

# lpjmlkit::check_config(config_details, model_path, sim_path)
# my_conf <- lpjmlkit::read_config("./simulation/configurations/config_scen1.json")
# View(my_conf)

spinup_run_details <- lpjmlkit::run_lpjml(
  spinup_config_details,
  model_path,
  sim_path,
  run_cmd = "mpirun -np 24 "
)

simulation_run_details <- lpjmlkit::run_lpjml(
  simulation_config_details,
  model_path,
  sim_path,
  run_cmd = "mpirun -np 24 "
)
