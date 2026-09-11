# Use the released version of daaprverse to create a canonical daap to test against.
# The daap will exist in the fixtures directory.
# Run from R session: 
#   devtools::load_all()
#   source("tests/testthat/helpers_dp-test.R")
#   source("tests/testthat/fixtures/create_dp-test.R", echo = TRUE)
# Run from Terminal: Rscript -e "devtools::load_all(); source('tests/testthat/fixtures/create_dp-test.R')"

temp_dp_dir <- withr::local_tempdir()
helpers_file <- testthat::test_path("helpers_dp-test.R")
parent_lib_paths <- .libPaths()
rsession <- callr::r_session$new()

tmp_dirs <- rsession$run(function(dir, helpers_file, lib_paths){
  # Try load_all() for dev testing; fall back to installed package during R CMD check
  # where the source tree isn't available
  loaded <- tryCatch(
    { pkgload::load_all(); TRUE },
    error = function(e) FALSE
  )
  if (!loaded) {
    library(daapr)
    source(helpers_file, local = FALSE)
  }
  tmp_dirs <- init_local_test_daap(dir)  
  setwd(tmp_dirs$temp_dp_project_dir)
  # Same options that were needed in e2e test
  withr::local_options(list(
    renv.verbose = FALSE,
    renv.config.snapshot.validate = FALSE,
    renv.config.external.libraries = lib_paths
  ))
  # Create default code
  dpcode_add(project_path = ".")
  add_test_daap_inputs(daapr_fixtures_dir = tmp_dirs$daapr_fixtures_dir)
  build_and_deploy_local_test_daap(dev_fixtures_daap_dir = tmp_dirs$dev_fixtures_daap_dir)
  return(tmp_dirs)
}, args=list(temp_dp_dir, helpers_file, parent_lib_paths))
rsession$kill()

# Copy the test dp to the final location in fixtures and remove git artifacts ----
# Wipe existing dp-test deployed board dir every time due to different pins version names
if (dir.exists(tmp_dirs$dev_fixtures_deployed_dir)){
  unlink(tmp_dirs$dev_fixtures_deployed_dir, recursive = TRUE)
}
fs::dir_copy(tmp_dirs$temp_dp_board_dir, tmp_dirs$daapr_fixtures_dir)

# Wipe existing dp-test dir and only copy over specific files desired
if (dir.exists(tmp_dirs$dev_fixtures_daap_dir)){
  unlink(tmp_dirs$dev_fixtures_daap_dir, recursive = TRUE)
}
dir.create(tmp_dirs$dev_fixtures_daap_dir)
withr::with_dir(tmp_dirs$temp_dp_project_dir, {
  fs::dir_copy(".daap", file.path(tmp_dirs$dev_fixtures_daap_dir, ".daap"), overwrite = TRUE)
  fs::file_copy(".gitignore", tmp_dirs$dev_fixtures_daap_dir, overwrite = TRUE)
  fs::file_copy(".renvignore", tmp_dirs$dev_fixtures_daap_dir, overwrite = TRUE)
  fs::file_copy("renv.lock", tmp_dirs$dev_fixtures_daap_dir, overwrite = TRUE)
  fs::file_copy("README.Rmd", tmp_dirs$dev_fixtures_daap_dir, overwrite = TRUE)
  fs::file_copy("dp_make.R", tmp_dirs$dev_fixtures_daap_dir, overwrite = TRUE)
  fs::file_copy("dp_journal.Rmd", tmp_dirs$dev_fixtures_daap_dir, overwrite = TRUE)
  fs::dir_copy("R", file.path(tmp_dirs$dev_fixtures_daap_dir, "R"), overwrite = TRUE)
  # .Rproj is not created unless you're working interactively from RStudio
  # fs::file_copy(paste0(daap_dir_name, "x.Rproj"), tmp_dirs$dev_fixtures_daap_dir, overwrite = TRUE)
})
