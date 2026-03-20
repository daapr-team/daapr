# Use the released version of daaprverse to create a canonical daap to test against.
# The daap will exist in the fixtures directory.
# By the end of this script the new daap's renv will be active, but you'll still be
# in the wd you started in.
# Run from R session: source("create_dp-test.R", echo = TRUE)
# Run from Terminal: Rscript -e "pkgload::load_all(); source('tests/testthat/fixtures/create_dp-test.R')"

library(daapr)  # TODO: decide where to setup daapr package sources for testing

tmp_dirs <- init_local_test_daap()

# change to tmp test daap directory
setwd(tmp_dirs$temp_dp_project_dir)

# Create default code
dpcode_add(project_path = ".")

add_test_daap_inputs(daapr_fixtures_dir = tmp_dirs$daapr_fixtures_dir)

build_and_deploy_local_test_daap(dev_fixtures_daap_dir = tmp_dirs$dev_fixtures_daap_dir)

# Copy the test dp to the final location in fixtures and remove git artifacts

# Wipe existing dp-test_deployed dir every time due to different pins version names
if (dir.exists(tmp_dirs$dev_fixtures_deployed_dir)){
  unlink(tmp_dirs$dev_fixtures_deployed_dir, recursive = TRUE)
}
fs::dir_copy(file.path("..", deployed_dir_name), tmp_dirs$daapr_fixtures_dir)

# Wipe existing dp-test dir and only copy over specific files desired
if (dir.exists(tmp_dirs$dev_fixtures_daap_dir)){
  unlink(tmp_dirs$dev_fixtures_daap_dir, recursive = TRUE)
}
dir.create(tmp_dirs$dev_fixtures_daap_dir)
fs::dir_copy(".daap", file.path(tmp_dirs$dev_fixtures_daap_dir, ".daap"), overwrite = TRUE)
fs::file_copy(".gitignore", tmp_dirs$dev_fixtures_daap_dir, overwrite = TRUE)
fs::file_copy(".renvignore", tmp_dirs$dev_fixtures_daap_dir, overwrite = TRUE)
fs::file_copy("renv.lock", tmp_dirs$dev_fixtures_daap_dir, overwrite = TRUE)
fs::file_copy("README.Rmd", tmp_dirs$dev_fixtures_daap_dir, overwrite = TRUE)
fs::file_copy("dp_make.R", tmp_dirs$dev_fixtures_daap_dir, overwrite = TRUE)
fs::file_copy("dp_journal.RMD", tmp_dirs$dev_fixtures_daap_dir, overwrite = TRUE) # TODO: update this when the file ext is fixed
fs::dir_copy("R", file.path(tmp_dirs$dev_fixtures_daap_dir, "R"), overwrite = TRUE)
# .Rproj is not created unless you're working interactively from RStudio
# fs::file_copy(paste0(daap_dir_name, "x.Rproj"), tmp_dirs$dev_fixtures_daap_dir, overwrite = TRUE)

if (interactive()){
  warning("Check your library paths and current working directory before proceeding!")
}
